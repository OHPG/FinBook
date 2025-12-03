import { CommonConstants } from "../../../common/CommonConstants"
import { AppRouter } from "../../../router/AppRouter"
import { HomeToolBar } from "../../../widget/bar/HomeToolBar"

@Component
export struct LocalPage {

  build() {
    Column() {
      HomeToolBar({
        title: $r('app.string.tab_local'),
        searchEnable: true,
        searchCallback: (args) => {
          AppRouter.goToLocalSearch(this.getUIContext(), args)
        }
      })

    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

}