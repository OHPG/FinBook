import { window } from '@kit.ArkUI'
import { ActiveInfo, AppStorageKeys } from '@ohpg/fin-core'
import { CommonConstants, FinRouter, ListRefreshView } from '@ohpg/fin-framework'
import { AppRouter } from '../../../router/AppRouter'
import { HomeToolBar } from '../../../widget/bar/HomeToolBar'
import { MediaGroup } from '../../../widget/item/MediaGroup'
import { OnlineViewModel } from './OnlineViewModel'

@Component
export struct OnlinePage {

  private viewModel = new OnlineViewModel(getContext())

  @StorageProp('currentAvoidArea') avoidArea?: window.AvoidArea = undefined

  @StorageLink(AppStorageKeys.KEY_ACTIVE_INFO) activeInfo?: ActiveInfo = undefined

  @Builder
  mediaCategory(info: ESObject, index: number) {
    MediaGroup({item: info})
  }

  build() {

    Column() {
      HomeToolBar({
        title: $r('app.string.tab_online'),
        searchEnable: true,
        searchCallback: (args) => {
          if (!this.activeInfo) {
            this.getUIContext().getPromptAction().showToast({message: $r('app.string.prefer_server_hint')})
            return
          }
          AppRouter.goToOnlineSearch(this.getUIContext(), args)
        }
      })

      if (this.activeInfo) {
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
          }
        })
          .width(CommonConstants.FULL_PERCENT)
          .layoutWeight(1)
      } else {
        Stack() {
          Text($r('app.string.tab_online_empty_tips'))
            .textAlign(TextAlign.Center)
            .fontSize(22)
            .onClick(() => {
              FinRouter.auth(this.getUIContext())
            })
        }
          .width(CommonConstants.FULL_PERCENT)
          .layoutWeight(1)
      }
    }
  }

}