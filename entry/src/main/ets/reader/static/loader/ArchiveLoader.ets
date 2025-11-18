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
    this.minizipEntry = new MinizipNative(file);
    this.minizipEntry.SetCharEncoding(936)
    if (this.minizipEntry.Open() == 0) {
      let entryNames = this.minizipEntry.GetEntryNames();
      for (let i = 0; i < entryNames.length; i++) {
        if(!entryNames[i].endsWith("/")) {
          this.archiveArray.push(entryNames[i])
        }
      }
    }
    return this.archiveArray.length
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