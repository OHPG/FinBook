import { CommonConstants } from '../../common/CommonConstants';
import LazyDataSource from '../../common/LazyDataSource';
import { PDFLoader } from './PDFLoader';
import { PdfPageInfo } from './PdfPageInfo';

@Component
export struct PDFView {

  @StorageProp('currentBreakpoint') currentBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;

  private dataSource: LazyDataSource<PdfPageInfo> = new LazyDataSource<PdfPageInfo>();

  private index: number = 0

  @Require @Prop pdfPath: string = '';

  @Provide pdfLoader: PDFLoader = new PDFLoader()

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
        })
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

  @Consume pdfLoader: PDFLoader

  @Require @State info?: PdfPageInfo = undefined

  @State pixel?: PixelMap = undefined

  @State loading: boolean = false

  aboutToAppear(): void {
    this.updateImage()
  }

  aboutToReuse(params: Record<string, ESObject>): void {
    this.info = params['info']
    this.updateImage()
  }

  private updateImage() {
    let index = this.info!.index
    this.pixel = this.pdfLoader.peekPage(index)
    this.loading = false
    if (this.pixel) return
    this.loading = true
    this.pdfLoader.getPage(index)
      .then((pixel) => {
        // TODO 考虑一致性问题
        this.pixel = pixel
        this.loading = false
      })
      .catch((error: Error) => {
        this.loading = false
      })
  }

  build() {
    Stack() {
      // pdf
      Image(this.pixel)
        .objectFit(ImageFit.Contain)
        .width(CommonConstants.FULL_PERCENT)
        .height(CommonConstants.FULL_PERCENT)

      // 错误和重试
      Text("加载出错，点击重试！")
        .visibility(Visibility.Hidden)

      // loading
      LoadingProgress()
        .visibility(this.loading ? Visibility.Visible : Visibility.Hidden)
        .width($r('sys.float.ohos_id_progress_default_diameter'))
        .height($r('sys.float.ohos_id_progress_default_diameter'))
        .color($r('sys.color.brand'))

    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
    .onClick(() => {
      this.retryIfNeed()
    })
  }

  private retryIfNeed() {
    if (this.loading || this.pixel) return
    this.updateImage()
  }

  aboutToRecycle(): void {

  }

  aboutToDisappear(): void {

  }

}
