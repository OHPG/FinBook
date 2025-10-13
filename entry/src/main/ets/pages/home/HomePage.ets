import { window } from '@kit.ArkUI'
import { GridRefreshView } from '@ohpg/fin-framework'
import { CommonConstants } from '../../common/CommonConstants'
import { HomeToolBar } from '../../widget/bar/HomeToolBar'
import { MediaItem } from '../../widget/item/MediaItem'
import { HomeViewModel } from './HomeViewModel'

@Entry
@Component
struct HomePage {

  private viewModel = new HomeViewModel(getContext())

  @StorageProp('currentBreakpoint') currentBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @Builder
  mediaListView(info: ESObject, index: number) {
    MediaItem({item: info})
  }

  build() {

    Column() {
      HomeToolBar({
        title: $r('app.string.app_name')
      })

      GridRefreshView({
        source: this.viewModel,
        gridAttribute: (attr) => {
          attr.padding = {
            left: CommonConstants.SPACE_16,
            right: CommonConstants.SPACE_16,
            bottom: px2vp(this.currentAvoidArea?.bottomRect.height)
          }
          attr.rowsGap = CommonConstants.SPACE_12
          attr.columnsGap = CommonConstants.SPACE_12
          attr.columnsTemplate = ('repeat(auto-fit, 140)')
          attr.width = CommonConstants.FULL_PERCENT
          attr.height = CommonConstants.FULL_PERCENT
        },
        itemLayout: this.mediaListView
      })
        .width(CommonConstants.FULL_PERCENT)
        .layoutWeight(1)
    }

  }

}