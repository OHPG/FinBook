import { zlib } from "@kit.BasicServicesKit";
import { util } from "@kit.ArkTS";
import fs from '@ohos.file.fs';

/**
 * 轻量级 zip 单文件提取器
 * 通过解析 End of Central Directory 和 Central Directory 定位文件
 * 只读取和解压需要的文件，不解压整个 zip
 *
 * 编码策略（与 WinRAR 一致）：
 * - 每个条目的 General Purpose Bit Flag bit 11 标记是否为 UTF-8
 * - bit 11 = 1：使用 UTF-8 解码
 * - bit 11 = 0：检测字节是否为合法 UTF-8，是则用 UTF-8，否则用 GBK
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

      let gpFlag = cdView.getUint16(pos + 8, true)
      let method = cdView.getUint16(pos + 10, true)
      let compSize = cdView.getUint32(pos + 20, true)
      let uncompSize = cdView.getUint32(pos + 24, true)
      let nameLen = cdView.getUint16(pos + 28, true)
      let extraLen = cdView.getUint16(pos + 30, true)
      let commentLen = cdView.getUint16(pos + 32, true)
      let localOffset = cdView.getUint32(pos + 42, true)

      // 读取文件名，根据 bit 11 (Language Encoding Flag) 决定编码
      let nameBytes = new Uint8Array(cdBuf, pos + 46, nameLen)
      let isUtf8Flag = (gpFlag & 0x0800) !== 0
      let name = ZipReader.decodeName(nameBytes, isUtf8Flag)

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
   * 根据 UTF-8 标志位和字节内容智能解码文件名
   * @param bytes 原始文件名字节
   * @param isUtf8Flag bit 11 是否设置（明确标记为 UTF-8）
   */
  private static decodeName(bytes: Uint8Array, isUtf8Flag: boolean): string {
    if (isUtf8Flag) {
      // bit 11 明确标记为 UTF-8
      return ZipReader.decodeUtf8(bytes)
    }
    // bit 11 未设置，需要启发式判断
    // 先检查是否为合法 UTF-8 序列
    if (ZipReader.isValidUtf8(bytes)) {
      return ZipReader.decodeUtf8(bytes)
    }
    // 不是合法 UTF-8，用 GBK 解码
    return ZipReader.decodeGBK(bytes)
  }

  /**
   * 检测字节序列是否为合法 UTF-8
   * 纯 ASCII 也算合法 UTF-8，但对于纯 ASCII 无需区分
   */
  private static isValidUtf8(bytes: Uint8Array): boolean {
    let i = 0
    while (i < bytes.length) {
      let b = bytes[i]
      if (b < 0x80) {
        // ASCII
        i++
      } else if ((b & 0xE0) === 0xC0) {
        // 2字节序列 110xxxxx
        if (i + 1 >= bytes.length) return false
        if ((bytes[i + 1] & 0xC0) !== 0x80) return false
        // 排除 overlong: 最小值应为 0x80，即首字节至少 0xC2
        if (b < 0xC2) return false
        i += 2
      } else if ((b & 0xF0) === 0xE0) {
        // 3字节序列 1110xxxx
        if (i + 2 >= bytes.length) return false
        if ((bytes[i + 1] & 0xC0) !== 0x80) return false
        if ((bytes[i + 2] & 0xC0) !== 0x80) return false
        // 排除 overlong
        if (b === 0xE0 && bytes[i + 1] < 0xA0) return false
        i += 3
      } else if ((b & 0xF8) === 0xF0) {
        // 4字节序列 11110xxx
        if (i + 3 >= bytes.length) return false
        if ((bytes[i + 1] & 0xC0) !== 0x80) return false
        if ((bytes[i + 2] & 0xC0) !== 0x80) return false
        if ((bytes[i + 3] & 0xC0) !== 0x80) return false
        // 排除 overlong
        if (b === 0xF0 && bytes[i + 1] < 0x90) return false
        i += 4
      } else {
        // 无效的起始字节
        return false
      }
    }
    return true
  }

  /**
   * UTF-8 解码
   */
  private static decodeUtf8(bytes: Uint8Array): string {
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
   * GBK 解码
   */
  private static decodeGBK(bytes: Uint8Array): string {
    let decoder = new util.TextDecoder("gbk")
    return decoder.decodeToString(bytes)
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
