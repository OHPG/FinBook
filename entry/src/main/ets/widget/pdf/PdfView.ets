import { CommonConstants } from '../../common/CommonConstants';
import LazyDataSource from '../../common/LazyDataSource';
import { PdfLoader } from './PdfLoader';
import { PdfPageInfo } from './PdfPageInfo';

@Reusable
@Component
export struct PdfView {

  @StorageProp('currentWidthBreakpoint') currentBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;

  private dataSource: LazyDataSource<PdfPageInfo> = new LazyDataSource<PdfPageInfo>();

  private controller = new SwiperController()

  @Consume immersiveMode: boolean

  @Consume readProgress: number

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
      Swiper(this.controller) {
        LazyForEach(this.dataSource, (info: PdfPageInfo) => {
          PdfPage({info: info})
        }, (item: PdfPageInfo, index: number) => item.index.toString())
      }
      .index(this.readProgress)
      .displayCount(this.currentBreakpoint >= WidthBreakpoint.WIDTH_LG ? 2 : 1, true)
      .indicator(false)
      .width('100%')
      .height('100%')
      .loop(false)
      .onChange((index) => {
        this.readProgress = index;
      })
    }
    .width('100%')
    .height('100%')
    .gesture(TapGesture({ count: 1 })
      .onAction((event) => {
        if (this.dataSource.totalCount() <= 0) return
        let width = event.target.area.width as number
        let x = event.fingerList[0].localX as number
        if (x < width / 3) {
          if (this.readProgress <= 0) {
            this.getUIContext().getPromptAction().showToast({message: $r('app.string.read_not_previous')})
          } else {
            this.controller.showPrevious()
          }
        } else if (x > width * 2 / 3){
          if (this.readProgress >= this.dataSource.totalCount() -1) {
            this.getUIContext().getPromptAction().showToast({message: $r('app.string.read_not_next')})
          } else {
            this.controller.showNext()
          }
        } else {
          this.immersiveMode = !this.immersiveMode
        }
      }))
  }

  aboutToDisappear() {
    this.pdfLoader.release()
  }

}

@Reusable
@Component
struct PdfPage {

  @Consume pdfLoader: PdfLoader

  @Consume immersiveMode: boolean

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
        .fontColor(Color.Gray)
        .visibility(this.immersiveMode ? Visibility.Hidden : Visibility.Visible)
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
