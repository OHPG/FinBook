import { PdfLoader } from './loader/PdfLoader';
import { ArchiveLoader } from './loader/ArchiveLoader';
import { ImagePageInfo } from './ImagePageInfo';
import LazyDataSource from '../../common/LazyDataSource';
import { CommonConstants } from '../../common/CommonConstants';
import { CacheRef } from '@ohpg/fin-core';
import { BookType } from '../../enum/BookType';
import { ImageLoader } from './loader/ImageLoader';

@Reusable
@Component
export struct StaticReaderView {

  @StorageProp('currentWidthBreakpoint') currentBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;

  private dataSource: LazyDataSource<ImagePageInfo> = new LazyDataSource<ImagePageInfo>();

  private controller = new SwiperController()

  @Consume immersiveMode: boolean

  @Consume readProgress: number

  @Require @Prop bookPath: string = '';

  @Require @Prop bookType: BookType

  @Provide imageLoader?: ImageLoader = undefined

  aboutToAppear() {
    this.imageLoader = this.bookType === BookType.ARCHIVE ? new ArchiveLoader() : new PdfLoader()
    this.imageLoader.load(this.bookPath)
      .then((count) => {
        this.constructData(count)
      })
      .catch((error: Error) => {
        // 显示错误，重试等
      })
  }

  private constructData(count: number) {
    let dataArray = new Array<ImagePageInfo>()
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
        LazyForEach(this.dataSource, (info: ImagePageInfo) => {
          StaticPage({info: info})
        }, (item: ImagePageInfo, index: number) => item.index.toString())
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
    this.imageLoader?.release()
  }

}

@Reusable
@Component
struct StaticPage {

  @Consume imageLoader: ImageLoader

  @Consume immersiveMode: boolean

  @Require @State info?: ImagePageInfo = undefined

  @State pixel?: PixelMap = undefined

  @State pixelFit:ImageFit = ImageFit.Contain

  private pixelRef?: CacheRef<PixelMap>

  aboutToAppear(): void {
    this.acquireImage()
  }

  aboutToReuse(params: Record<string, ESObject>): void {
    this.info = params['info']
    this.acquireImage()
  }

  private async acquireImage() {
    let index = this.info!.index
    this.pixelRef = await this.imageLoader.get(index)
    this.pixel = this.pixelRef.acquire()
  }

  build() {
    Stack({alignContent: Alignment.Bottom}) {
      // pdf
      Image(this.pixel)
        .objectFit(this.pixelFit)
        .width(CommonConstants.FULL_PERCENT)
        .height(CommonConstants.FULL_PERCENT)

      // index
      Text((this.info!.index + 1) + "/" + this.info!.count)
        .fontColor(Color.Gray)
        .visibility(this.immersiveMode ? Visibility.Hidden : Visibility.Visible)
        .margin(CommonConstants.SPACE_16)
    }
    .gesture(TapGesture({count: 2})
      .onAction((event) => {
        if (this.pixelFit === ImageFit.Contain) {
          this.pixelFit = ImageFit.Cover
        } else if (this.pixelFit === ImageFit.Cover) {
          this.pixelFit = ImageFit.Contain
        } else {
          // ignore
        }
      })
    )
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

  private releaseImage() {
    this.pixelRef?.release()
    this.pixelRef = undefined
  }

  aboutToRecycle(): void {
    this.pixelFit = ImageFit.Contain
    this.releaseImage()
  }

  aboutToDisappear(): void {
    this.pixelFit = ImageFit.Contain
    this.releaseImage()
  }

}