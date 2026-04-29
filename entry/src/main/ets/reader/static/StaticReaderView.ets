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
import { ComponentContent, OverlayManager } from '@kit.ArkUI';
import { inputConsumer, KeyEvent as InputKeyEvent } from '@kit.InputKit';
import { KeyCode } from '@kit.InputKit';

/**
 * 滑动条 overlay 参数
 */
class SliderOverlayParams {
  controller: SwiperController
  touching: boolean = false
  onTouchChange?: (touching: boolean) => void
  constructor(controller: SwiperController) {
    this.controller = controller
  }
}

@Builder
function sliderOverlayBuilder(params: SliderOverlayParams) {
  Row() {
    Blank()
    Column() {
      Slider({
        value: AppStorage.get<number>('staticReaderProgress') ?? 0,
        min: 0,
        max: Math.max((AppStorage.get<number>('staticReaderPageCount') ?? 1) - 1, 0),
        step: 1,
        style: SliderStyle.OutSet,
        direction: Axis.Vertical
      })
        .selectedColor($r('sys.color.ohos_id_color_component_activated'))
        .trackColor('#33808080')
        .trackThickness(2)
        .blockSize({ width: 12, height: 12 })
        .backgroundColor('#40000000')
        .borderRadius(10)
        .onChange((value: number, mode: SliderChangeMode) => {
          let index = Math.round(value)
          let current = AppStorage.get<number>('staticReaderProgress') ?? 0
          if (index !== current) {
            AppStorage.setOrCreate('staticReaderProgress', index)
            params.controller.changeIndex(index, false)
          }
          let isTouching = mode === SliderChangeMode.Begin || mode === SliderChangeMode.Moving
          if (isTouching !== params.touching) {
            params.onTouchChange?.(isTouching)
          }
        })
        .height('100%')
    }
    .justifyContent(FlexAlign.Center)
    .width(48)
    .padding({ top: 16, bottom: 16, left: 14, right: 14 })
    .margin({ top: 32, bottom: 32 })
    .opacity(params.touching ? 1 : 0)
    .animation({ duration: 200 })
  }
  .width('100%')
  .height('100%')
  .hitTestBehavior(HitTestMode.Transparent)
}

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

  private volumeUpCallback?: (event: InputKeyEvent) => void
  private volumeDownCallback?: (event: InputKeyEvent) => void

  private overlayManager?: OverlayManager
  private overlayContent?: ComponentContent<SliderOverlayParams>
  private sliderParams?: SliderOverlayParams

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
    this.registerVolumeKeyListener()
    this.addSliderOverlay()
  }

  private addSliderOverlay() {
    AppStorage.setOrCreate('staticReaderProgress', this.readProgress)
    AppStorage.setOrCreate('staticReaderPageCount', 0)
    let uiContext = this.getUIContext()
    this.overlayManager = uiContext.getOverlayManager()
    this.sliderParams = new SliderOverlayParams(this.controller)
    this.sliderParams.onTouchChange = (touching: boolean) => {
      this.sliderParams!.touching = touching
      this.overlayContent?.update(this.sliderParams!)
    }
    this.overlayContent = new ComponentContent(
      uiContext,
      wrapBuilder<[SliderOverlayParams]>(sliderOverlayBuilder),
      this.sliderParams
    )
    this.overlayManager.addComponentContent(this.overlayContent, 0)
    // 进入时短暂显示滑动条，提示用户
    this.sliderParams.touching = true
    this.overlayContent.update(this.sliderParams)
    setTimeout(() => {
      if (this.sliderParams && this.overlayContent) {
        this.sliderParams.touching = false
        this.overlayContent.update(this.sliderParams)
      }
    }, 1500)
  }

  private removeSliderOverlay() {
    if (this.overlayContent) {
      this.overlayManager?.removeComponentContent(this.overlayContent)
      this.overlayContent = undefined
    }
    AppStorage.delete('staticReaderProgress')
    AppStorage.delete('staticReaderPageCount')
  }

  private constructData(count: number) {
    this.bookChapter = count
    AppStorage.setOrCreate('staticReaderPageCount', count)
    let dataArray = new Array<ImagePageInfo>()
    for (let i = 0; i < count; i++) {
      dataArray.push({
        index: i,
        count: count
      })
    }
    this.dataSource.pushArrayData(dataArray)
  }

  private registerVolumeKeyListener() {
    if (!this.appPrefer?.getVolumeKeyPageTurn()) return
    this.volumeUpCallback = (event: InputKeyEvent) => {
      if (this.readProgress > 0) {
        this.controller.showPrevious()
      }
    }
    this.volumeDownCallback = (event: InputKeyEvent) => {
      if (this.readProgress < this.dataSource.totalCount() - 1) {
        this.controller.showNext()
      }
    }
    inputConsumer.on('keyPressed', {
      key: KeyCode.KEYCODE_VOLUME_UP,
      action: 1,
      isRepeat: false
    }, this.volumeUpCallback)
    inputConsumer.on('keyPressed', {
      key: KeyCode.KEYCODE_VOLUME_DOWN,
      action: 1,
      isRepeat: false
    }, this.volumeDownCallback)
  }

  private unregisterVolumeKeyListener() {
    if (this.volumeUpCallback) {
      inputConsumer.off('keyPressed', this.volumeUpCallback)
      this.volumeUpCallback = undefined
    }
    if (this.volumeDownCallback) {
      inputConsumer.off('keyPressed', this.volumeDownCallback)
      this.volumeDownCallback = undefined
    }
  }

  aboutToDisappear() {
    this.removeSliderOverlay()
    this.unregisterVolumeKeyListener()
    this.imageLoader?.release()
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
        AppStorage.setOrCreate('staticReaderProgress', index)
      })
    }
    .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
      this.sizeOptions = newValue
    })
    .width('100%')
    .height('100%')
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