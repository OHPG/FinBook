import { CommonConstants, GridRefreshView, ToolBar } from '@ohpg/fin-framework'
import { SearchArgs } from './SearchArgs'
import { MediaItem } from '../../widget/item/MediaItem'
import { SearchViewModel } from './SearchViewModel'
import { window } from '@kit.ArkUI'

@Entry
@Component
struct SearchPage {

  private readonly args: SearchArgs = this.getUIContext().getRouter().getParams() as SearchArgs

  private viewModel = new SearchViewModel(getContext(), this.args.word)

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @Builder
  mediaListView(info: ESObject, index: number) {
    MediaItem({item: info})
  }

  build() {
    Column() {
      ToolBar({
        title: this.args.word
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