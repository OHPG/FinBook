import router from '@ohos.router'
import { window } from '@kit.ArkUI'
import { ScrollRefreshView, ToolBar } from '@ohpg/fin-framework'
import { CommonConstants } from '../../common/CommonConstants'
import { ReaderViewModel } from './ReaderViewModel'
import { MediaArgs } from '../detail/MediaArgs'
import { PdfView } from '../../widget/pdf/PdfView'
import { FinBookRawSource } from '../../entity/FinBookRawSource'

@Entry
@Component
struct ReaderPage {
  private args: MediaArgs = router.getParams() as MediaArgs

  private viewModel = new ReaderViewModel(getContext(), this.args)

  @StorageProp("currentAvoidArea") avoidArea?: window.AvoidArea = undefined

  aboutToAppear(): void {
  }

  @Builder
  pdfView(path: string) {
    PdfView({
        pdfPath: path,
    })
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
  }

  @Builder
  normalView(path: string) {
    Text(path)
  }

  build() {
   Column() {
     ToolBar({title: this.args.name})
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
       .layoutWeight(1)
       .width(CommonConstants.FULL_PERCENT)
   }
   .width(CommonConstants.FULL_PERCENT)
   .height(CommonConstants.FULL_PERCENT)
  }

  aboutToDisappear(): void {
  }

}