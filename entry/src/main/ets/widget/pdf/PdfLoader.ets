import { pdfService } from "@kit.PDFKit";
import { pdfCache } from "./PdfCache";

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
      pixel = page.getPagePixelMap();
      pdfCache.put(index, pixel)
    }
    return pixel
  }

  public release() {
    pdfCache.clear()
    this.document.releaseDocument()
  }

}