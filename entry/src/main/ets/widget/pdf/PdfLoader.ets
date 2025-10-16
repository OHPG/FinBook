import { pdfService } from "@kit.PDFKit";
import { pdfCache } from "./PdfCache";
import { deviceInfo } from "@kit.BasicServicesKit";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/9/27 23:25
 * @Version V1.0
 * @Description
 */
export class PdfLoader {

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

  public getPage(index: number): PixelMap {
    let pixel = pdfCache.get(index)
    if (!pixel) {
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
      if (deviceInfo.sdkApiVersion >= 18) {
        let options: pdfService.PixelOptions = new pdfService.PixelOptions();
        options.isGray = false;
        options.drawAnnotations = true;
        options.isTransparent = false;
        pixel = page.getAreaPixelMapWithOptions(pdfMatrix, width, height, options);
      } else {
        pixel = page.getAreaPixelMap(pdfMatrix, width, height, false, true)
      }
      pdfCache.put(index, pixel)
    }
    return pixel
  }

  public release() {
    pdfCache.clear()
    this.document.releaseDocument()
  }

}