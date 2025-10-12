import router from '@ohos.router'
import { window } from '@kit.ArkUI'
import { ScrollRefreshView, ToolBar } from '@ohpg/fin-framework'
import { CommonConstants } from '../../common/CommonConstants'
import { ReaderViewModel } from './ReaderViewModel'
import { MediaArgs } from '../detail/MediaArgs'
import { PdfView } from '../../widget/pdf/PdfView'
import { FinBookRawSource } from '../../entity/FinBookRawSource'
import { XReaderView } from '../../widget/reader/XReaderView'

@Entry
@Component
struct ReaderPage {
  private args: MediaArgs = router.getParams() as MediaArgs

  private viewModel = new ReaderViewModel(getContext(), this.args)

  @StorageProp("currentAvoidArea") avoidArea?: window.AvoidArea = undefined
  /**
   * 是否是沉浸式
   */
  @Provide immersiveMode: boolean = false

  /**
   * 菜单是否可见
   */
  @Provide menuVisible: boolean = false

  aboutToAppear(): void {
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
         if (source.pdf) {
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
           .onClick(() => {
             this.menuVisible = true
           })
       }
     }
     .visibility(this.immersiveMode ? Visibility.Hidden : Visibility.Visible)
   }
   .width(CommonConstants.FULL_PERCENT)
   .height(CommonConstants.FULL_PERCENT)
  }

  onBackPress(): boolean | void {
    if (this.menuVisible) {
      this.menuVisible = false
      return true
    }
    return false
  }

  aboutToDisappear(): void {
  }

}