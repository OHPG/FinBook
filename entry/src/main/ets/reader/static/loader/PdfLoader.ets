import { pdfService } from "@kit.PDFKit";
import { deviceInfo } from "@kit.BasicServicesKit";
import { imageCache } from "../ImageCache";
import { CacheRef, ImageRef } from "@ohpg/fin-core";
import { ImageLoader } from "./ImageLoader";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/9/27 23:25
 * @Version V1.0
 * @Description
 */
export class PdfLoader implements ImageLoader {

  private readonly document: pdfService.PdfDocument

  constructor() {
    this.document = new pdfService.PdfDocument()
  }

  public async load(path: string): Promise<number> {
    let loadResult: pdfService.ParseResult = this.document.loadDocument(path, '');
    if (loadResult !== pdfService.ParseResult.PARSE_SUCCESS) {
      throw new Error("Load error " + loadResult)
    }
    return this.document.getPageCount()
  }

  public async get(index: number): Promise<CacheRef<PixelMap>> {
    let pixelRef = imageCache.get(index)
    if (!pixelRef) {
      let page = this.document.getPage(index);
      let pdfMatrix: pdfService.PdfMatrix = new pdfService.PdfMatrix();
      let width = page.getWidth()
      let height = page.getHeight()
      // 计算缩放系数，防止画面质量太糊。
      let min = Math.min(width, height)
      if (min < 300) {
        width *= 4
        height *= 4
      } else if (min < 600) {
        width *= 2
        height *= 2
      }
      pdfMatrix.x = 0;
      pdfMatrix.y = 0;
      pdfMatrix.width = width;
      pdfMatrix.height = height;
      pdfMatrix.rotate = 0;
      let pixel: PixelMap
      if (deviceInfo.sdkApiVersion >= 18) {
        let options: pdfService.PixelOptions = new pdfService.PixelOptions();
        options.isGray = false;
        options.drawAnnotations = true;
        options.isTransparent = false;
        pixel = page.getAreaPixelMapWithOptions(pdfMatrix, width, height, options);
      } else {
        pixel = page.getAreaPixelMap(pdfMatrix, width, height, false, true)
      }
      pixelRef = new ImageRef(pixel)
      imageCache.put(index, pixelRef)
    }
    return pixelRef
  }

  public async release(): Promise<void> {
    imageCache.clear()
    this.document.releaseDocument()
  }

}