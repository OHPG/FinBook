import { window } from '@kit.ArkUI'
import { GridRefreshView, ToolBar } from '@ohpg/fin-framework'
import { CommonConstants } from '../../common/CommonConstants'
import { MediaItem } from '../../widget/item/MediaItem'
import { MediaArgs } from '../detail/MediaArgs'
import { GridViewModel } from './GridViewModel'

@Entry
@Component
struct GridPage {

  private readonly args: MediaArgs = this.getUIContext().getRouter().getParams() as MediaArgs

  private viewModel = new GridViewModel(getContext(), this.args)

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @Builder
  mediaListView(info: ESObject, index: number) {
    MediaItem({item: info})
  }

  build() {
    Column() {
      ToolBar({
        title: this.args.name
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
          attr.columnsTemplate = ('repeat(auto-fit, 100)')
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
