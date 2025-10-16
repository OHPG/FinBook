import router from '@ohos.router'
import { window } from '@kit.ArkUI'
import { ScrollRefreshView, ToolBar } from '@ohpg/fin-framework'
import { CommonConstants } from '../../common/CommonConstants'
import { ReaderViewModel } from './ReaderViewModel'
import { MediaArgs } from '../detail/MediaArgs'
import { PdfView } from '../../widget/pdf/PdfView'
import { FinBookRawSource } from '../../entity/FinBookRawSource'
import { XReaderView } from '../../widget/reader/XReaderView'
import { common } from '@kit.AbilityKit'

@Entry
@Component
struct ReaderPage {
  private args: MediaArgs = router.getParams() as MediaArgs

  private viewModel = new ReaderViewModel(getContext(), this.args)

  private immersiveModeTimer?: number = undefined

  @StorageProp("currentAvoidArea") avoidArea?: window.AvoidArea = undefined

  @Provide bookTitle: string = this.args.name

  /**
   * 是否是沉浸式
   */
  @Provide @Watch("onImmersiveModeChange") immersiveMode: boolean = false

  /**
   * 菜单是否可用
   */
  @State menuEnable: boolean = false

  /**
   * 菜单是否可见
   */
  @Provide menuVisible: boolean = false

  /**
   * 阅读进度
   */
  @Provide @Watch('onProgressChange') readProgress: number = 0

  aboutToAppear(): void {
    this.viewModel.startRead()
  }

  @Builder
  pdfView(path: string) {
    PdfView({
        pdfPath: path,
    })
  }

  @Builder
  normalView(path: string) {
    XReaderView({
      bookPath: path
    })
  }

  build() {
   Stack({alignContent: Alignment.Top}) {
     ScrollRefreshView({
       refreshEnable: false,
       source: this.viewModel,
       itemLayout: (source: FinBookRawSource) => {
         if (this.judgementType(source)) {
           this.pdfView(source.path)
         } else {
           this.normalView(source.path)
         }
       }
     })
       .width(CommonConstants.FULL_PERCENT)
       .height(CommonConstants.FULL_PERCENT)

     Row() {
       ToolBar({title: this.args.name}) {
         SymbolGlyph($r('sys.symbol.slider_horizontal_2'))
           .fontSize($r('sys.float.Title_L'))
           .fontColor([$r('sys.color.font_primary')])
           .visibility(this.menuEnable ? Visibility.Visible : Visibility.Hidden)
           .onClick(() => {
             this.menuVisible = true
           })
       }
     }
     .backgroundColor($r('sys.color.background_primary'))
     .visibility(this.immersiveMode ? Visibility.Hidden : Visibility.Visible)
   }
   .width(CommonConstants.FULL_PERCENT)
   .height(CommonConstants.FULL_PERCENT)
  }

  private judgementType(source: FinBookRawSource): boolean {
    this.readProgress = source.progress
    this.bookTitle = source.name
    this.menuEnable = source.pdf ? false: true
    this.addImmersiveModeTimer()
    return source.pdf ? true : false
  }

  private clearImmersiveModeTimer() {
    if (this.immersiveModeTimer === undefined) return
    clearTimeout(this.immersiveModeTimer)
    this.immersiveModeTimer = undefined
  }

  private addImmersiveModeTimer() {
    if (this.immersiveModeTimer !== undefined) return
    this.immersiveModeTimer = setTimeout(() => {
      this.immersiveMode = true
      this.immersiveModeTimer = undefined
    }, 3000)
  }

  private onProgressChange() {
    this.viewModel.updateProgress(this.readProgress)
  }

  private async onImmersiveModeChange() {
    try {
      let window = (this.getUIContext().getHostContext() as common.UIAbilityContext).windowStage.getMainWindowSync()
      if (this.immersiveMode) {
        this.clearImmersiveModeTimer()
        await window.setWindowSystemBarEnable([])
      } else {
        await window.setWindowSystemBarEnable(['status', 'navigation'])
        this.addImmersiveModeTimer()
      }
    } catch (e) {

    }
  }

  onBackPress(): boolean | void {
    if (this.menuVisible) {
      this.menuVisible = false
      return true
    }
    return false
  }

  aboutToDisappear(): void {
    this.immersiveMode = false
    this.viewModel.stopRead(this.readProgress)
  }

}