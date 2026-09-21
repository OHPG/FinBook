import { window } from '@kit.ArkUI'
import { GridRefreshView, ToolBar } from '@ohpg/fin-framework'
import { BreakpointSystem } from '@ohpg/fin-core'
import { CommonConstants } from '../../common/CommonConstants'
import { MediaItem } from '../../widget/item/MediaItem'
import { SortMenu } from '../../widget/menu/SortMenu'
import { MediaArgs } from '../detail/MediaArgs'
import { SeriesViewModel } from './SeriesViewModel'

@Entry
@Component
struct SeriesPage {

  private readonly args: MediaArgs = this.getUIContext().getRouter().getParams() as MediaArgs

  private viewModel = new SeriesViewModel(getContext(), this.args)

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT) currentWidthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM

  @Builder
  mediaListView(info: ESObject, index: number) {
    MediaItem({item: info})
  }

  build() {
    Column() {
      ToolBar({
        title: this.args.name
      }) {
        SortMenu()
      }

      GridRefreshView({
        source: this.viewModel,
        gridAttribute: (attr) => {
          attr.padding = {
            left: CommonConstants.SPACE_16,
            right: CommonConstants.SPACE_16,
            bottom: this.currentAvoidArea?.bottomRect.height
          }
          attr.rowsGap = CommonConstants.SPACE_12
          attr.columnsGap = CommonConstants.SPACE_12
          // 封面列宽随宽度断点放大，Pad 上封面更大（进入页面时确定，与本地列表一致）
          attr.columnsTemplate = `repeat(auto-fit, ${this.currentWidthBreakpoint >= WidthBreakpoint.WIDTH_LG
            ? 160
            : (this.currentWidthBreakpoint >= WidthBreakpoint.WIDTH_MD ? 140 : 110)}vp)`
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
