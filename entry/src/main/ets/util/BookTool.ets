import { BookType } from "../enum/BookType"
import { FileUtil } from "./FileUtil"
import { pdfService } from "@kit.PDFKit"
import { bookParser } from "@kit.ReaderKit";
import { image } from "@kit.ImageKit";

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

  private static async extractOtherCover(uri: string): Promise<PixelMap | undefined> {
    let imageSource: image.ImageSource | undefined
    try {
      let bookHandler = await bookParser.getDefaultHandler(uri)
      let coverImage = bookHandler.getBookInfo().bookCoverImage
      if (coverImage && coverImage.length > 0) {
        let buffer = bookHandler.getResourceContent(-1, coverImage)
        if (buffer && buffer.byteLength > 0) {
          imageSource = image.createImageSource(buffer);
          return imageSource.createPixelMapSync();
        }
      }
    } catch (e) {

    } finally {
      imageSource?.release()
    }
    return undefined
  }

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
      
    }
    return pixel
  }


}