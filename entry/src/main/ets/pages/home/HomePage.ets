import { window } from '@kit.ArkUI'
import { ListRefreshView } from '@ohpg/fin-framework'
import { CommonConstants } from '../../common/CommonConstants'
import { HomeToolBar } from '../../widget/bar/HomeToolBar'
import { MediaGroup } from '../../widget/item/MediaGroup'
import { HomeViewModel } from './HomeViewModel'

@Entry
@Component
struct HomePage {

  private viewModel = new HomeViewModel(getContext())

  @StorageProp('currentAvoidArea') avoidArea?: window.AvoidArea = undefined

  @Builder
  mediaCategory(info: ESObject, index: number) {
    MediaGroup({item: info})
  }

  build() {

    Column() {
      HomeToolBar({
        title: $r('app.string.app_name')
      })

      ListRefreshView({
        source: this.viewModel,
        itemLayout: this.mediaCategory,
        listAttribute: (attr) => {
          attr.divider = {
            color: Color.Transparent,
            strokeWidth: CommonConstants.SPACE_12
          }
          attr.width = CommonConstants.FULL_PERCENT
          attr.height = CommonConstants.FULL_PERCENT
          attr.contentEndOffset = px2vp(this.avoidArea?.bottomRect.height)
        },
      })
        .width(CommonConstants.FULL_PERCENT)
        .layoutWeight(1)
    }
  }

}