import { CommonConstants } from '../../common/CommonConstants';
import LazyDataSource from '../../common/LazyDataSource';
import { PdfLoader } from './PdfLoader';
import { PdfPageInfo } from './PdfPageInfo';

@Component
export struct PdfView {

  @StorageProp('currentBreakpoint') currentBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;

  private dataSource: LazyDataSource<PdfPageInfo> = new LazyDataSource<PdfPageInfo>();

  private index: number = 0

  @Require @Prop pdfPath: string = '';

  @Provide pdfLoader: PdfLoader = new PdfLoader()

  aboutToAppear() {
    this.pdfLoader.load(this.pdfPath)
      .then((count) => {
        this.constructData(count)
      })
      .catch((error: Error) => {
        // 显示错误，重试等
      })
  }

  private constructData(count: number) {
    let dataArray = new Array<PdfPageInfo>()
    for (let i = 0; i < count; i++) {
      dataArray.push({
        index: i,
        count: count
      })
    }
    this.dataSource.pushArrayData(dataArray)
  }

  build() {
    Stack() {
      Swiper() {
        LazyForEach(this.dataSource, (info: PdfPageInfo) => {
          PdfPage({info: info})
        }, (item: PdfPageInfo, index: number) => item.index.toString())
      }
      .displayCount(this.currentBreakpoint >= WidthBreakpoint.WIDTH_LG ? 2 : 1, true)
      .indicator(false)
      .width('100%')
      .height('100%')
      .loop(false)
      .onChange((index) => {
        this.index = index;
      })
    }
    .width('100%')
    .height('100%')
  }

  aboutToDisappear() {
    this.pdfLoader.release()
  }

}

@Reusable
@Component
struct PdfPage {

  @Consume pdfLoader: PdfLoader

  @Require @State info?: PdfPageInfo = undefined

  @State pixel?: PixelMap = undefined

  aboutToAppear(): void {
    this.updateImage()
  }

  aboutToReuse(params: Record<string, ESObject>): void {
    this.info = params['info']
    this.updateImage()
  }

  private updateImage() {
    let index = this.info!.index
    this.pixel = this.pdfLoader.getPage(index)
  }

  build() {
    Stack({alignContent: Alignment.Bottom}) {
      // pdf
      Image(this.pixel)
        .objectFit(ImageFit.Contain)
        .width(CommonConstants.FULL_PERCENT)
        .height(CommonConstants.FULL_PERCENT)

      // index
      Text((this.info!.index + 1) + "/" + this.info!.count)
        .margin(CommonConstants.SPACE_16)
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

  aboutToRecycle(): void {
  }

  aboutToDisappear(): void {

  }

}
