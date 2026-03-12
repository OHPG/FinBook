import { CommonConstants } from "../../../common/CommonConstants"
import { HomeControl } from "../HomeControl"
import { TreeControl } from "../../../widget/tree/TreeControl"
import { HomeToolBar } from "../../../widget/bar/HomeToolBar"
import { AppRouter } from "../../../router/AppRouter"
import { LocalViewModel } from "./LocalViewModel"
import { TreeView } from "../../../widget/tree/TreeView"
import { SortMenu } from "../../../widget/menu/SortMenu"

@Component
export struct LocalPage {

  @StorageLink("currentHomeControl") homeControl?: HomeControl = undefined

  private control = new TreeControl()

  aboutToAppear(): void {
    this.homeControl!.callback = (): boolean => {
      return this.onBackPress()
    }
  }

  build() {
    Column() {
      HomeToolBar({
        title: $r('app.string.tab_local'),
        // searchEnable: false,
        // searchCallback: (args) => {
        //   AppRouter.goToLocalSearch(this.getUIContext(), args)
        // }
      }) {
        SymbolGlyph($r('sys.symbol.arrow_counterclockwise_clock'))
          .fontSize($r('sys.float.Title_M'))
          .fontColor([$r('sys.color.font_primary')])
          .onClick(() => {
            AppRouter.goToHistory(this.getUIContext())
          })

        SortMenu({enableSortDir: true})
      }

      TreeView({
        control: this.control,
        mediaData: new LocalViewModel(this.getUIContext().getHostContext()!),
        emptyOrErrorResource: $r('app.string.global_content_empty')
      })
        .width(CommonConstants.FULL_PERCENT)
        .layoutWeight(1)
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

  onBackPress(): boolean {
    return this.control.goBack()
  }

  aboutToDisappear(): void {
    this.homeControl!.callback = undefined
  }

}