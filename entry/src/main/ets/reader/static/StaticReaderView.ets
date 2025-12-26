import { PhotoView } from '@ohos/photoview';
import { PdfLoader } from './loader/PdfLoader';
import { ArchiveLoader } from './loader/ArchiveLoader';
import { ImagePageInfo } from './ImagePageInfo';
import LazyDataSource from '../../common/LazyDataSource';
import { CommonConstants } from '../../common/CommonConstants';
import { CacheRef } from '@ohpg/fin-core';
import { BookType } from '../../enum/BookType';
import { ImageLoader } from './loader/ImageLoader';
import { AppPrefer } from '../../prefer/AppPrefer';

@Reusable
@Component
export struct StaticReaderView {

  @StorageProp('currentWidthBreakpoint') currentBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;

  @StorageLink(AppPrefer.PREFER) appPrefer?: AppPrefer = undefined

  private dataSource: LazyDataSource<ImagePageInfo> = new LazyDataSource<ImagePageInfo>();

  private sizeOptions?: SizeOptions

  private controller = new SwiperController()

  @Consume immersiveMode: boolean

  @Consume bookChapter: number

  @Consume readProgress: number

  @Require @Prop bookPath: string = '';

  @Require @Prop bookType: BookType

  @Provide imageLoader?: ImageLoader = undefined

  @Provide isVertical: boolean = false

  private tapCallback: Callback<number> = (x) => {
    if (this.dataSource.totalCount() <= 0 || !this.sizeOptions?.width) return
    let width = this.sizeOptions.width as number
    if (x < width / 3) {
      if (this.readProgress <= 0) {
        this.getUIContext().getPromptAction().showToast({message: $r('app.string.read_not_previous')})
      } else {
        this.controller.showPrevious()
      }
    } else if (x > width * 2 / 3) {
      if (this.readProgress >= this.dataSource.totalCount() - 1) {
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.read_not_next') })
      } else {
        this.controller.showNext()
      }
    } else {
      this.immersiveMode = !this.immersiveMode
    }
  }

  aboutToAppear() {
    this.isVertical = this.appPrefer?.getBookOrientation() ? true : false
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
    this.bookChapter = count
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
          StaticPage({ info: info, tapCallback: this.tapCallback })
        }, (item: ImagePageInfo, index: number) => item.index.toString())
      }
      .index(this.readProgress)
      .displayCount(this.currentBreakpoint >= WidthBreakpoint.WIDTH_LG ? 2 : 1, true)
      .vertical(this.isVertical)
      .indicator(false)
      .width('100%')
      .height('100%')
      .loop(false)
      .onChange((index) => {
        this.readProgress = index;
      })
    }
    .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
      this.sizeOptions = newValue
    })
    .width('100%')
    .height('100%')
  }

  aboutToDisappear() {
    this.imageLoader?.release()
  }
}

interface OnViewTapListener {

  /**
   * A callback to receive where the user taps on a ImageView. You will receive a callback if
   * the user taps anywhere on the view, tapping on 'whitespace' will not be ignored.
   *
   * @param x    - where the user tapped from the left of the View.
   * @param y    - where the user tapped from the top of the View.
   */

  onViewTap(x: number, y: number): void;

}

class OnViewTapListenerImpl implements OnViewTapListener {

  private readonly callback: Callback<number>

  constructor(callback: Callback<number>) {
    this.callback = callback
  }

  onViewTap(x: number, y: number): void {
    this.callback(px2vp(x))
  }

}

@Reusable
@Component
struct StaticPage {

  private model: PhotoView.Model = new PhotoView.Model();

  @Consume imageLoader: ImageLoader

  @Consume immersiveMode: boolean

  @Consume isVertical: boolean

  @Require @State info?: ImagePageInfo = undefined

  private pixelRef?: CacheRef<PixelMap>

  tapCallback?: Callback<number>

  aboutToAppear(): void {
    let tapListener = new OnViewTapListenerImpl(this.tapCallback!)
    Object.bind(tapListener, this)
    this.model
      .setScale(1, false)
      .setVertical(this.isVertical)
      .setImageFit(ImageFit.Contain)
      .setOnViewTapListener(tapListener)
    this.acquireImage()
  }

  aboutToReuse(params: Record<string, ESObject>): void {
    this.info = params['info']
    this.acquireImage()
  }

  private async acquireImage() {
    let index = this.info!.index
    this.pixelRef = await this.imageLoader.get(index)
    let pixel = this.pixelRef.acquire()
    this.model.setImageElement(pixel)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // pdf
      PhotoViewV1({ model: this.model })
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

  private releaseImage() {
    this.pixelRef?.release()
    this.pixelRef = undefined
  }

  aboutToRecycle(): void {
    this.model.resetMatrix()
    this.releaseImage()
  }

  aboutToDisappear(): void {
    this.model.resetMatrix()
    this.releaseImage()
  }
}

@ComponentV2
struct PhotoViewV1 {
  @Param model?: PhotoView.Model = undefined

  build() {
    PhotoView({ model: this.model })
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
  }
}