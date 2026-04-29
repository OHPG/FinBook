import { BookType } from "../enum/BookType"
import { FileUtil } from "./FileUtil"
import { pdfService } from "@kit.PDFKit"
import { image } from "@kit.ImageKit";
import { zlib } from "@kit.BasicServicesKit";
import { util } from "@kit.ArkTS";
import fs from '@ohos.file.fs';
import BuildProfile from 'BuildProfile';

const TAG = "FinBook BookTool"

/**
 * zip Central Directory 条目信息
 */
interface ZipEntry {
  name: string
  compressedSize: number
  uncompressedSize: number
  compressionMethod: number
  localHeaderOffset: number
}

export class BookTool {

  private static async extractPdfCover(uri: string): Promise<PixelMap | undefined> {
    let document = new pdfService.PdfDocument()
    try {
      let loadResult: pdfService.ParseResult = document.loadDocument(uri, '');
      if (loadResult !== pdfService.ParseResult.PARSE_SUCCESS) {
        throw new Error("Load error " + loadResult)
      }
      let count = document.getPageCount()
      if (count > 0) {
        return document.getPage(0).getPagePixelMap()
      }
    } catch (r) {

    } finally {
      document.releaseDocument()
    }
    return undefined
  }

  // ==================== ZIP 解析 ====================

  /**
   * 从 zip 文件末尾查找 End of Central Directory，解析 Central Directory
   */
  private static async parseZipEntries(fd: number, fileSize: number): Promise<Map<string, ZipEntry>> {
    let entries = new Map<string, ZipEntry>()

    // EOCD 最小 22 字节，最大 22 + 65535（comment）
    let searchSize = Math.min(fileSize, 22 + 65535)
    let searchBuf = new ArrayBuffer(searchSize)
    await fs.read(fd, searchBuf, { offset: fileSize - searchSize })
    let searchView = new DataView(searchBuf)

    // 从后往前找 EOCD signature 0x06054b50
    let eocdOffset = -1
    for (let i = searchSize - 22; i >= 0; i--) {
      if (searchView.getUint32(i, true) === 0x06054b50) {
        eocdOffset = i
        break
      }
    }
    if (eocdOffset < 0) return entries

    let cdSize = searchView.getUint32(eocdOffset + 12, true)
    let cdOffset = searchView.getUint32(eocdOffset + 16, true)
    let entryCount = searchView.getUint16(eocdOffset + 10, true)

    // 读取 Central Directory
    let cdBuf = new ArrayBuffer(cdSize)
    await fs.read(fd, cdBuf, { offset: cdOffset })
    let cdView = new DataView(cdBuf)

    let pos = 0
    for (let i = 0; i < entryCount; i++) {
      if (pos + 46 > cdSize) break
      let sig = cdView.getUint32(pos, true)
      if (sig !== 0x02014b50) break

      let compressionMethod = cdView.getUint16(pos + 10, true)
      let compressedSize = cdView.getUint32(pos + 20, true)
      let uncompressedSize = cdView.getUint32(pos + 24, true)
      let nameLen = cdView.getUint16(pos + 28, true)
      let extraLen = cdView.getUint16(pos + 30, true)
      let commentLen = cdView.getUint16(pos + 32, true)
      let localHeaderOffset = cdView.getUint32(pos + 42, true)

      let nameBytes = new Uint8Array(cdBuf, pos + 46, nameLen)
      let decoder = new util.TextDecoder("utf-8")
      let name = decoder.decodeToString(nameBytes)

      entries.set(name, {
        name: name,
        compressedSize: compressedSize,
        uncompressedSize: uncompressedSize,
        compressionMethod: compressionMethod,
        localHeaderOffset: localHeaderOffset
      })

      pos += 46 + nameLen + extraLen + commentLen
    }

    return entries
  }

  /**
   * 从 zip 中提取单个文件的内容
   */
  private static async extractZipFile(fd: number, entry: ZipEntry): Promise<ArrayBuffer | undefined> {
    // 读取 Local File Header 获取实际数据偏移
    let lfhBuf = new ArrayBuffer(30)
    await fs.read(fd, lfhBuf, { offset: entry.localHeaderOffset })
    let lfhView = new DataView(lfhBuf)

    if (lfhView.getUint32(0, true) !== 0x04034b50) return undefined

    let lfhNameLen = lfhView.getUint16(26, true)
    let lfhExtraLen = lfhView.getUint16(28, true)
    let dataOffset = entry.localHeaderOffset + 30 + lfhNameLen + lfhExtraLen

    if (entry.compressionMethod === 0) {
      // STORED - 直接读取
      let buf = new ArrayBuffer(entry.uncompressedSize)
      await fs.read(fd, buf, { offset: dataOffset })
      return buf
    } else if (entry.compressionMethod === 8) {
      // DEFLATED - 读取压缩数据，用 zlib inflate 解压
      let compressedBuf = new ArrayBuffer(entry.compressedSize)
      await fs.read(fd, compressedBuf, { offset: dataOffset })

      let destBuf = new ArrayBuffer(entry.uncompressedSize)
      let zip = zlib.createZipSync()
      let strm: zlib.ZStream = {}
      // windowBits 为负值表示 raw deflate（无 zlib header）
      await zip.inflateInit2(strm, -15)
      strm.availableIn = entry.compressedSize
      strm.nextIn = compressedBuf
      strm.availableOut = entry.uncompressedSize
      strm.nextOut = destBuf
      await zip.inflate(strm, zlib.CompressFlushMode.FINISH)
      await zip.inflateEnd(strm)

      return destBuf
    }

    return undefined
  }

  /**
   * 从 zip 中按名称提取文件内容
   */
  private static async readZipFileByName(fd: number, fileSize: number,
    entries: Map<string, ZipEntry>, name: string): Promise<ArrayBuffer | undefined> {
    let entry = entries.get(name)
    if (!entry) return undefined
    return BookTool.extractZipFile(fd, entry)
  }

  // ==================== EPUB 封面提取 ====================

  /**
   * 从 epub/azw3 文件中提取封面图片
   */
  private static async extractEpubCover(uri: string): Promise<PixelMap | undefined> {
    let file: fs.File | undefined
    let imageSource: image.ImageSource | undefined
    try {
      file = await fs.open(uri, fs.OpenMode.READ_ONLY)
      let fileStat = await fs.stat(uri)
      let entries = await BookTool.parseZipEntries(file.fd, fileStat.size)

      if (BuildProfile.DEBUG) {
        console.info(TAG + " epub entries: " + entries.size)
      }

      // 1. 读取 container.xml
      let containerBuf = await BookTool.readZipFileByName(file.fd, fileStat.size,
        entries, "META-INF/container.xml")
      if (!containerBuf) {
        console.warn(TAG + " epub container.xml not found: " + uri)
        return undefined
      }
      let containerXml = BookTool.bufferToString(containerBuf)
      let opfPath = BookTool.parseOpfPath(containerXml)
      if (!opfPath) {
        console.warn(TAG + " epub opf path not found: " + uri)
        return undefined
      }

      // OPF 所在目录
      let opfDir = ""
      let slashIndex = opfPath.lastIndexOf("/")
      if (slashIndex >= 0) {
        opfDir = opfPath.substring(0, slashIndex + 1)
      }

      // 2. 读取 OPF 文件
      let opfBuf = await BookTool.readZipFileByName(file.fd, fileStat.size, entries, opfPath)
      if (!opfBuf) {
        console.warn(TAG + " epub opf not found: " + opfPath)
        return undefined
      }
      let opfXml = BookTool.bufferToString(opfBuf)
      if (BuildProfile.DEBUG) {
        console.info(TAG + " epub opf: " + opfPath + ", len=" + opfXml.length)
      }

      let coverHref = BookTool.parseCoverFromOpf(opfXml)
      if (!coverHref) {
        console.warn(TAG + " epub no cover in opf: " + uri)
        return undefined
      }

      // 3. 提取封面图片
      let coverPath = coverHref.startsWith("/") ? coverHref.substring(1) : opfDir + coverHref
      // URL 解码（有些 epub 的 href 是 URL 编码的）
      try {
        coverPath = decodeURIComponent(coverPath)
      } catch (_) {
      }
      if (BuildProfile.DEBUG) {
        console.info(TAG + " epub cover: " + coverPath)
      }

      let coverBuf = await BookTool.readZipFileByName(file.fd, fileStat.size, entries, coverPath)
      if (!coverBuf || coverBuf.byteLength === 0) {
        console.warn(TAG + " epub cover extract failed: " + coverPath)
        return undefined
      }

      imageSource = image.createImageSource(coverBuf)
      let pixelMap = await imageSource.createPixelMap()
      imageSource.release()
      return pixelMap
    } catch (e) {
      if (BuildProfile.DEBUG) {
        console.error(TAG + " epub error: " + JSON.stringify(e))
      }
      imageSource?.release()
      return undefined
    } finally {
      if (file) {
        await fs.close(file.fd)
      }
    }
  }

  // ==================== MOBI 封面提取 ====================

  /**
   * 从 mobi/azw 文件中提取封面图片
   */
  private static async extractMobiCover(uri: string): Promise<PixelMap | undefined> {
    let file: fs.File | undefined
    let imageSource: image.ImageSource | undefined
    try {
      file = await fs.open(uri, fs.OpenMode.READ_ONLY)

      // PalmDOC header (前78字节)
      let headerBuf = new ArrayBuffer(78)
      await fs.read(file.fd, headerBuf)
      let headerView = new DataView(headerBuf)
      let numRecords = headerView.getUint16(76, false)
      if (numRecords <= 0) {
        console.warn(TAG + " mobi no records: " + uri)
        return undefined
      }

      // record info list
      let recordInfoBuf = new ArrayBuffer(numRecords * 8)
      await fs.read(file.fd, recordInfoBuf, { offset: 78 })
      let recordInfoView = new DataView(recordInfoBuf)
      let recordOffsets = new Array<number>()
      for (let i = 0; i < numRecords; i++) {
        recordOffsets.push(recordInfoView.getUint32(i * 8, false))
      }

      // record 0
      let record0Offset = recordOffsets[0]
      let record0Size = (numRecords > 1 ? recordOffsets[1] : 0) - record0Offset
      if (record0Size <= 0) record0Size = 4096
      if (record0Size > 65536) record0Size = 65536
      let record0Buf = new ArrayBuffer(record0Size)
      await fs.read(file.fd, record0Buf, { offset: record0Offset })
      let record0View = new DataView(record0Buf)

      // MOBI magic at offset 16
      if (record0View.getUint32(16, false) !== 0x4D4F4249) {
        console.warn(TAG + " mobi magic mismatch: " + uri)
        return undefined
      }

      let mobiHeaderLength = record0View.getUint32(20, false)

      // EXTH flags at offset 128
      if (128 + 4 > record0Size) {
        console.warn(TAG + " mobi record0 too small: " + uri)
        return undefined
      }
      let exthFlags = record0View.getUint32(128, false)
      if ((exthFlags & 0x40) === 0) {
        console.warn(TAG + " mobi no EXTH: " + uri)
        return undefined
      }

      // EXTH header
      let exthOffset = 16 + mobiHeaderLength
      if (exthOffset + 12 > record0Size) {
        console.warn(TAG + " mobi EXTH out of bounds: " + uri)
        return undefined
      }
      if (record0View.getUint32(exthOffset, false) !== 0x45585448) {
        console.warn(TAG + " mobi EXTH magic mismatch: " + uri)
        return undefined
      }

      let exthRecordCount = record0View.getUint32(exthOffset + 8, false)
      // first image record index
      let firstImageIndex = 0
      if (mobiHeaderLength >= 112) {
        firstImageIndex = record0View.getUint32(16 + 108, false)
      }
      if (firstImageIndex <= 0 || firstImageIndex >= numRecords) {
        console.warn(TAG + " mobi invalid firstImageIndex: " + firstImageIndex + ", " + uri)
        return undefined
      }

      // 遍历 EXTH records 查找 cover offset (type 201)
      let pos = exthOffset + 12
      let coverIndex: number = -1
      for (let i = 0; i < exthRecordCount; i++) {
        if (pos + 8 > record0Size) break
        let recType = record0View.getUint32(pos, false)
        let recLen = record0View.getUint32(pos + 4, false)
        if (recLen < 8) break
        if (recType === 201 && recLen === 12) {
          coverIndex = record0View.getUint32(pos + 8, false)
        }
        pos += recLen
      }

      if (coverIndex < 0) coverIndex = 0

      let imageRecordIndex = firstImageIndex + coverIndex
      if (BuildProfile.DEBUG) {
        console.info(TAG + " mobi imageRecord: " + imageRecordIndex +
          " (first=" + firstImageIndex + " cover=" + coverIndex + ")")
      }
      if (imageRecordIndex >= numRecords) {
        console.warn(TAG + " mobi imageRecord out of range: " + uri)
        return undefined
      }

      // 读取图片 record
      let imgOffset = recordOffsets[imageRecordIndex]
      let imgEnd = imageRecordIndex + 1 < numRecords ? recordOffsets[imageRecordIndex + 1] : 0
      if (imgEnd <= imgOffset) {
        let fileStat = await fs.stat(uri)
        imgEnd = fileStat.size
      }
      let imgSize = imgEnd - imgOffset
      if (imgSize <= 0 || imgSize > 10 * 1024 * 1024) {
        console.warn(TAG + " mobi img size invalid: " + imgSize + ", " + uri)
        return undefined
      }

      let imgBuf = new ArrayBuffer(imgSize)
      await fs.read(file.fd, imgBuf, { offset: imgOffset })

      imageSource = image.createImageSource(imgBuf)
      let pixelMap = await imageSource.createPixelMap()
      imageSource.release()
      return pixelMap
    } catch (e) {
      if (BuildProfile.DEBUG) {
        console.error(TAG + " mobi error: " + JSON.stringify(e))
      }
      imageSource?.release()
      return undefined
    } finally {
      if (file) {
        await fs.close(file.fd)
      }
    }
  }

  // ==================== 入口 ====================

  public static async extractCover(uri: string): Promise<PixelMap | undefined> {
    let pixel: PixelMap | undefined
    try {
      let type = await FileUtil.getBookType(uri)
      if (type === BookType.PDF) {
        pixel = await BookTool.extractPdfCover(uri)
      } else if (type === BookType.OTHER) {
        pixel = await BookTool.extractOtherCover(uri)
      }
    } catch (e) {
      if (BuildProfile.DEBUG) {
        console.error(TAG + " extractCover error: " + JSON.stringify(e))
      }
    }
    if (!pixel) {
      console.warn(TAG + " no cover: " + uri)
    }
    return pixel
  }

  private static async extractOtherCover(uri: string): Promise<PixelMap | undefined> {
    let index = uri.lastIndexOf(".")
    if (index < 0) return undefined
    let suffix = uri.substring(index + 1).toLowerCase()
    if (suffix === "epub" || suffix === "azw3") {
      return BookTool.extractEpubCover(uri)
    } else if (suffix === "mobi" || suffix === "azw") {
      return BookTool.extractMobiCover(uri)
    }
    return undefined
  }

  // ==================== 工具方法 ====================

  private static bufferToString(buffer: ArrayBuffer): string {
    let decoder = new util.TextDecoder("utf-8")
    return decoder.decodeToString(new Uint8Array(buffer))
  }

  private static parseOpfPath(xml: string): string | undefined {
    let regex = /rootfile[^>]+full-path\s*=\s*"([^"]+)"/i
    let match = regex.exec(xml)
    return match ? match[1] : undefined
  }

  private static parseCoverFromOpf(opfXml: string): string | undefined {
    // 策略1: <meta name="cover" content="cover-id"/>
    let metaRegex = /<meta[^>]+name\s*=\s*"cover"[^>]+content\s*=\s*"([^"]+)"/i
    let metaMatch = metaRegex.exec(opfXml)
    if (metaMatch) {
      let coverId = metaMatch[1]
      let href = BookTool.findManifestItemById(opfXml, coverId)
      if (href) return href
    }

    // 策略2: <item properties="cover-image" .../>
    let propsRegex = /<item[^>]+properties\s*=\s*"[^"]*cover-image[^"]*"[^>]+href\s*=\s*"([^"]+)"/i
    let propsMatch = propsRegex.exec(opfXml)
    if (propsMatch) return propsMatch[1]
    let propsRegex2 = /<item[^>]+href\s*=\s*"([^"]+)"[^>]+properties\s*=\s*"[^"]*cover-image[^"]*"/i
    let propsMatch2 = propsRegex2.exec(opfXml)
    if (propsMatch2) return propsMatch2[1]

    // 策略3: id 包含 "cover" 且 media-type 是图片
    let itemRegex = /<item[^>]+>/gi
    let itemMatch: RegExpExecArray | null
    while ((itemMatch = itemRegex.exec(opfXml)) !== null) {
      let tag = itemMatch[0]
      let idMatch = /id\s*=\s*"([^"]+)"/i.exec(tag)
      let hrefMatch = /href\s*=\s*"([^"]+)"/i.exec(tag)
      let typeMatch = /media-type\s*=\s*"([^"]+)"/i.exec(tag)
      if (idMatch && hrefMatch && typeMatch) {
        let id = idMatch[1].toLowerCase()
        let mediaType = typeMatch[1].toLowerCase()
        if (id.includes("cover") && mediaType.startsWith("image/")) {
          return hrefMatch[1]
        }
      }
    }

    return undefined
  }

  private static findManifestItemById(opfXml: string, id: string): string | undefined {
    let escapedId = ""
    let specials = ".*+?^${}()|[]\\"
    for (let i = 0; i < id.length; i++) {
      let ch = id.charAt(i)
      if (specials.includes(ch)) {
        escapedId += "\\" + ch
      } else {
        escapedId += ch
      }
    }
    let regex1 = new RegExp('<item[^>]+id\\s*=\\s*"' + escapedId + '"[^>]+href\\s*=\\s*"([^"]+)"', "i")
    let match1 = regex1.exec(opfXml)
    if (match1) return match1[1]
    let regex2 = new RegExp('<item[^>]+href\\s*=\\s*"([^"]+)"[^>]+id\\s*=\\s*"' + escapedId + '"', "i")
    let match2 = regex2.exec(opfXml)
    if (match2) return match2[1]
    return undefined
  }

}
