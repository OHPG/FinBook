import { window } from '@kit.ArkUI'
import { ToolBar } from '@ohpg/fin-framework'
import { CommonConstants, GridRefreshView } from '@ohpg/fin-framework'
import { HistoryViewModel } from './HistoryViewModel'
import { BreakpointSystem } from '@ohpg/fin-core'
import { BookItem } from '../../entity/BookItem'
import { MenuType } from '../../enum/MenuType'
import { Pair } from '../../comp/Pair'
import { AppRouter } from '../../router/AppRouter'
import { MediaArgs } from '../detail/MediaArgs'
import { BookItemView } from '../../widget/tree/TreeBodyView'

@Entry
@Component
struct HistoryPage {

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT) currentWidthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM

  private readonly viewModel: HistoryViewModel = new HistoryViewModel(this.getUIContext().getHostContext()!)

  @StorageProp('currentAvoidArea') avoidArea?: window.AvoidArea = undefined

  private readonly mediaItemCallback: Callback<BookItem> = (item) => {
    let playerArgs: MediaArgs = {
      id: item.id,
      name: item.name,
      uri: item.uri
    }
    AppRouter.goToLocalReader(this.getUIContext(), playerArgs)
  }

  private readonly mediaMenuCallback: Callback<Pair<MenuType, BookItem>> = (item) => {
    if (item.first === MenuType.DELETE) {
      this.viewModel.deleteData(item.second)
    }
  }

  @Builder
  mediaListView(info: ESObject, index: number) {
    BookItemView({mediaItem: info as BookItem,
      callback: this.mediaItemCallback,
      menuCallback: this.mediaMenuCallback})
  }

  build() {

    Column() {
      ToolBar({title: $r('app.string.history_title')})
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
        itemLayout: this.mediaListView.bind(this)
      })
        .width(CommonConstants.FULL_PERCENT)
        .layoutWeight(1)
    }

  }

}