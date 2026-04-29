import { zlib } from "@kit.BasicServicesKit";
import fs from '@ohos.file.fs';

/**
 * 轻量级 zip 单文件提取器
 * 通过解析 End of Central Directory 和 Central Directory 定位文件
 * 只读取和解压需要的文件，不解压整个 zip
 */
export class ZipReader {

  private fd: number
  private fileSize: number
  private entries: Map<string, ZipEntry> = new Map()

  private constructor(fd: number, fileSize: number) {
    this.fd = fd
    this.fileSize = fileSize
  }

  /**
   * 打开 zip 文件
   */
  public static async open(path: string): Promise<ZipReader | undefined> {
    try {
      let file = await fs.open(path, fs.OpenMode.READ_ONLY)
      let stat = await fs.stat(path)
      let reader = new ZipReader(file.fd, stat.size)
      let ok = await reader.readCentralDirectory()
      if (!ok) {
        await fs.close(file.fd)
        return undefined
      }
      return reader
    } catch (e) {
      return undefined
    }
  }

  /**
   * 获取所有文件名
   */
  public getEntryNames(): string[] {
    return Array.from(this.entries.keys())
  }

  /**
   * 提取指定文件内容
   */
  public async extract(name: string): Promise<ArrayBuffer | undefined> {
    let entry = this.entries.get(name)
    if (!entry) return undefined

    try {
      // 读取 Local File Header 获取实际数据偏移
      let lfhBuf = new ArrayBuffer(30)
      await fs.read(this.fd, lfhBuf, { offset: entry.localHeaderOffset })
      let lfhView = new DataView(lfhBuf)

      // 验证 Local File Header 签名 0x04034b50
      if (lfhView.getUint32(0, true) !== 0x04034b50) return undefined

      let nameLen = lfhView.getUint16(26, true)
      let extraLen = lfhView.getUint16(28, true)
      let dataOffset = entry.localHeaderOffset + 30 + nameLen + extraLen

      // 读取压缩数据
      let compressedBuf = new ArrayBuffer(entry.compressedSize)
      await fs.read(this.fd, compressedBuf, { offset: dataOffset })

      if (entry.compressionMethod === 0) {
        // STORED - 无压缩
        return compressedBuf
      } else if (entry.compressionMethod === 8) {
        // DEFLATED - 需要解压
        return await ZipReader.inflateRaw(compressedBuf, entry.uncompressedSize)
      }
      return undefined
    } catch (e) {
      return undefined
    }
  }

  /**
   * 关闭文件
   */
  public async close(): Promise<void> {
    try {
      await fs.close(this.fd)
    } catch (_) {
    }
  }

  /**
   * 解析 End of Central Directory 和 Central Directory
   */
  private async readCentralDirectory(): Promise<boolean> {
    // 从文件末尾搜索 EOCD 签名 0x06054b50
    // EOCD 最小 22 字节，最大 22 + 65535 (comment)
    let searchSize = Math.min(this.fileSize, 65557)
    let searchOffset = this.fileSize - searchSize
    let searchBuf = new ArrayBuffer(searchSize)
    await fs.read(this.fd, searchBuf, { offset: searchOffset })
    let searchView = new DataView(searchBuf)

    let eocdOffset = -1
    for (let i = searchSize - 22; i >= 0; i--) {
      if (searchView.getUint32(i, true) === 0x06054b50) {
        eocdOffset = i
        break
      }
    }
    if (eocdOffset < 0) return false

    // 解析 EOCD
    let cdEntryCount = searchView.getUint16(eocdOffset + 10, true)
    let cdSize = searchView.getUint32(eocdOffset + 12, true)
    let cdOffset = searchView.getUint32(eocdOffset + 16, true)

    // 读取 Central Directory
    let cdBuf = new ArrayBuffer(cdSize)
    await fs.read(this.fd, cdBuf, { offset: cdOffset })
    let cdView = new DataView(cdBuf)

    let pos = 0
    for (let i = 0; i < cdEntryCount; i++) {
      if (pos + 46 > cdSize) break
      // 验证 Central Directory 签名 0x02014b50
      if (cdView.getUint32(pos, true) !== 0x02014b50) break

      let method = cdView.getUint16(pos + 10, true)
      let compSize = cdView.getUint32(pos + 20, true)
      let uncompSize = cdView.getUint32(pos + 24, true)
      let nameLen = cdView.getUint16(pos + 28, true)
      let extraLen = cdView.getUint16(pos + 30, true)
      let commentLen = cdView.getUint16(pos + 32, true)
      let localOffset = cdView.getUint32(pos + 42, true)

      // 读取文件名
      let nameBytes = new Uint8Array(cdBuf, pos + 46, nameLen)
      let name = ZipReader.decodeFileName(nameBytes)

      this.entries.set(name, {
        compressionMethod: method,
        compressedSize: compSize,
        uncompressedSize: uncompSize,
        localHeaderOffset: localOffset
      })

      pos += 46 + nameLen + extraLen + commentLen
    }

    return this.entries.size > 0
  }

  /**
   * 解码文件名（UTF-8）
   */
  private static decodeFileName(bytes: Uint8Array): string {
    let result = ""
    let i = 0
    while (i < bytes.length) {
      let byte = bytes[i]
      if (byte < 0x80) {
        result += String.fromCharCode(byte)
        i++
      } else if ((byte & 0xE0) === 0xC0) {
        let code = ((byte & 0x1F) << 6) | (bytes[i + 1] & 0x3F)
        result += String.fromCharCode(code)
        i += 2
      } else if ((byte & 0xF0) === 0xE0) {
        let code = ((byte & 0x0F) << 12) | ((bytes[i + 1] & 0x3F) << 6) | (bytes[i + 2] & 0x3F)
        result += String.fromCharCode(code)
        i += 3
      } else if ((byte & 0xF8) === 0xF0) {
        let code = ((byte & 0x07) << 18) | ((bytes[i + 1] & 0x3F) << 12) | ((bytes[i + 2] & 0x3F) << 6) | (bytes[i + 3] & 0x3F)
        // 处理 surrogate pair
        code -= 0x10000
        result += String.fromCharCode(0xD800 + (code >> 10), 0xDC00 + (code & 0x3FF))
        i += 4
      } else {
        i++
      }
    }
    return result
  }

  /**
   * 使用 zlib 解压 raw deflate 数据
   */
  private static async inflateRaw(compressed: ArrayBuffer, uncompressedSize: number): Promise<ArrayBuffer | undefined> {
    try {
      let zip = zlib.createZipSync()
      let strm: zlib.ZStream = {}
      // windowBits 为负数表示 raw deflate（无 zlib header）
      await zip.inflateInit2(strm, -15)

      let outBuf = new ArrayBuffer(uncompressedSize)
      strm.availableIn = compressed.byteLength
      strm.nextIn = compressed
      strm.availableOut = uncompressedSize
      strm.nextOut = outBuf

      await zip.inflate(strm, zlib.CompressFlushMode.FINISH)
      zip.inflateEnd(strm)

      return outBuf
    } catch (e) {
      return undefined
    }
  }

}

interface ZipEntry {
  compressionMethod: number
  compressedSize: number
  uncompressedSize: number
  localHeaderOffset: number
}
