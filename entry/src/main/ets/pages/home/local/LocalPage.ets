import { CommonConstants } from "../../../common/CommonConstants"
import { HomeToolBar } from "../../../widget/bar/HomeToolBar"
import { LocalViewModel } from "./LocalViewModel"
import { NormalView } from "../com/NormalView"

@Component
export struct LocalPage {

  build() {
    Column() {
      HomeToolBar({
        title: $r('app.string.tab_local'),
        // searchEnable: false,
        // searchCallback: (args) => {
        //   AppRouter.goToLocalSearch(this.getUIContext(), args)
        // }
      })

      NormalView({
        mediaData: new LocalViewModel(this.getUIContext().getHostContext()!)
      })
        .width(CommonConstants.FULL_PERCENT)
        .layoutWeight(1)
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

}

