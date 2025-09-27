import { pdfService } from "@kit.PDFKit";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/9/27 23:25
 * @Version V1.0
 * @Description
 */
export class PDFLoader {

  private readonly document: pdfService.PdfDocument = new pdfService.PdfDocument()

  private readonly cacheMap = new Map<number, PixelMap>()

  constructor() {
  }

  getSubstringAfterLastSlash(str: string): string | undefined {
    const parts = str.split('/'); // 使用 / 来分割字符串
    return parts.pop(); // 返回分割后的数组中的最后一个元素
  }

  public async load(path: string): Promise<number> {
    let loadResult: pdfService.ParseResult = this.document.loadDocument(path, '');
    if (loadResult !== pdfService.ParseResult.PARSE_SUCCESS) {
      throw new Error("Load error " + loadResult)
    }
    return this.document.getPageCount()
  }

  public peekPage(index: number): PixelMap | undefined {
    return this.cacheMap.get(index)
  }

  public async getPage(index: number): Promise<PixelMap> {
    let page = await this.document.getPage(index);
    let pixel = await page.getPagePixelMap();
    this.cacheMap.set(index, pixel)
    return pixel
  }

  public release() {
    this.document.releaseDocument()
  }

}