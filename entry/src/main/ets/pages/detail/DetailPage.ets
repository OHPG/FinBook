import { ScrollRefreshView, ToolBar } from '@ohpg/fin-framework'
import { FinItem } from '@ohpg/fin-core'
import { CommonConstants } from '../../common/CommonConstants'
import { DetailViewModel } from './DetailViewModel'
import { MediaArgs } from './MediaArgs'
import { window } from '@kit.ArkUI'
import { DetailFooter, DetailHeader } from './DetailComp'
let detailStorage: LocalStorage = new LocalStorage();

@Entry(detailStorage)
@Component
struct DetailPage {

  @StorageProp("currentAvoidArea") avoidArea?: window.AvoidArea = undefined

  private args = this.getUIContext().getRouter().getParams() as MediaArgs

  private viewModel = new DetailViewModel(getContext(), this.args)

  aboutToAppear(): void {
    detailStorage.setOrCreate("viewModel", this.viewModel)
  }

  @Builder
  showScrollView(info?: FinItem) {
    Column({space: CommonConstants.SPACE_12}) {
      DetailHeader({item: info})
      DetailFooter({item: info})
    }
    .padding({
      bottom: px2vp(this.avoidArea?.bottomRect.height)
    })
    .width(CommonConstants.FULL_PERCENT)
  }

  build() {
    Stack() {
      ScrollRefreshView({
        refreshEnable: false,
        source: this.viewModel,
        itemLayout: (info: ESObject) => {
          this.showScrollView(info)
        }
      })
      ToolBar({
        color: $r('sys.color.font_on_primary')
      })
    }
    .alignContent(Alignment.Top)
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

}