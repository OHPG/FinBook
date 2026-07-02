import { CacheRef } from "@ohpg/fin-core";
import { ImageLoader } from "./ImageLoader";
import { imageCache } from "../ImageCache";
import { image } from "@kit.ImageKit";
import { MinizipNative } from "@ohos/minizip";

export class ArchiveLoader implements ImageLoader {

  private archiveArray = new Array<string>()

  private minizipEntry?: MinizipNative

  async load(file: string): Promise<number> {
    this.archiveArray.splice(0)
    // 先尝试默认编码（UTF-8）打开
    let minizip = new MinizipNative(file);
    if (minizip.Open() != 0) {
      return 0
    }
    let entryNames = minizip.GetEntryNames();
    if (ArchiveLoader.needsGBKDecoding(entryNames)) {
      // 文件名非UTF-8，用GBK重新打开
      // @ohos/minizip 的 bug: SetCharEncoding 对 UTF-8 条目也强制转码
      // 所以只有检测到确实是 GBK 时才设置
      minizip = new MinizipNative(file);
      minizip.SetCharEncoding(936)
      if (minizip.Open() != 0) {
        return 0
      }
      entryNames = minizip.GetEntryNames();
    }
    this.minizipEntry = minizip
    for (let i = 0; i < entryNames.length; i++) {
      if(!entryNames[i].endsWith("/")) {
        this.archiveArray.push(entryNames[i])
      }
    }
    return this.archiveArray.length
  }

  /**
   * 检测文件名是否需要GBK解码。
   * 当minizip以UTF-8解码GBK编码的文件名时，会产生Latin-1范围的乱码字符。
   */
  private static needsGBKDecoding(names: string[]): boolean {
    for (let name of names) {
      if (name.endsWith("/")) {
        continue
      }
      // 提取不含扩展名的文件名部分来检测
      let lastSlash = name.lastIndexOf("/")
      let baseName = lastSlash >= 0 ? name.substring(lastSlash + 1) : name
      let dotIndex = baseName.lastIndexOf(".")
      let nameWithoutExt = dotIndex > 0 ? baseName.substring(0, dotIndex) : baseName

      let suspiciousCount = 0
      for (let i = 0; i < nameWithoutExt.length; i++) {
        let code = nameWithoutExt.charCodeAt(i)
        // U+FFFD 替换字符，或 0x80-0x1FF 范围的Latin-1字符
        // 这些是GBK字节被当作单字节解码的典型特征
        if (code === 0xFFFD || (code >= 0x80 && code <= 0x1FF)) {
          suspiciousCount++
        }
      }
      // 如果可疑字符占比超过一半，判定为需要GBK解码
      if (nameWithoutExt.length > 0 && suspiciousCount > nameWithoutExt.length / 2) {
        return true
      }
    }
    return false
  }

  async get(index: number): Promise<CacheRef<PixelMap>> {
    let pixelRef = imageCache.get(index)
    if (!pixelRef) {
      let path = this.archiveArray[index]
      let arrBuffer = this.minizipEntry?.ExtractFileToJS(path, "");
      if (!arrBuffer) {
        throw new Error("Unzip error.")
      }
      let source = image.createImageSource(arrBuffer)
      try {
        let pixelMap = await source.createPixelMap()
        pixelRef = new CacheRef<PixelMap>(pixelMap)
        imageCache.put(index, pixelRef)
      } finally {
        source.release()
      }
    }
    return pixelRef
  }

  async release(): Promise<void> {
    imageCache.clear()
    this.archiveArray.splice(0)
  }

}
