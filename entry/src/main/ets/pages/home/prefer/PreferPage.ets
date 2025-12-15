import { window } from '@kit.ArkUI'
import { WebTool } from '@ohpg/fin-core'
import { CommonConstants, FinRouter } from '@ohpg/fin-framework'
import { pasteboard } from '@kit.BasicServicesKit'
import { Repository } from '../../../data/Repository'
import { HomeToolBar } from '../../../widget/bar/HomeToolBar'


@Component
export struct PreferPage {

  private repository: Repository = AppStorage.get(Repository.REPOSITORY)!

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @Builder
  preferItemBuilder(icon: Resource, title: ResourceStr, callback: Callback<void>) {
    Row({space: CommonConstants.SPACE_12}) {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([$r('sys.color.ohos_id_color_text_primary')])
      Text(title)
        .fontSize(18)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
      Blank()
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(48)
    .padding({
      left: CommonConstants.SPACE_16,
      right: CommonConstants.SPACE_16
    })
    .onClick(() => {
      callback()
    })
  }

  build() {
    Column({space: CommonConstants.SPACE_8}) {
      HomeToolBar({
        title: $r('app.string.about')
      })

      Column({ space: CommonConstants.SPACE_12}) {
        Row() {
          Text($r('app.string.prefer_current_server'))
          Text(this.repository?.getActiveInfo()?.serverInfo.serverName || $r('app.string.prefer_server_hint'))
        }
        Row() {
          Text($r('app.string.prefer_current_address'))
          Text(this.repository?.getActiveInfo()?.addressInfo.address || $r('app.string.prefer_server_hint'))
        }
        Row() {
          Text($r('app.string.prefer_current_user'))
          Text(this.repository?.getActiveInfo()?.userInfo.userName || $r('app.string.prefer_server_hint'))
        }
      }
      .width(CommonConstants.FULL_PERCENT)
      .alignItems(HorizontalAlign.Start)
      .padding({
        left: CommonConstants.SPACE_16,
        right: CommonConstants.SPACE_16
      })

      this.preferItemBuilder($r('sys.symbol.externaldrive'), $r('app.string.prefer_server'), () => {
        if (this.repository?.getActiveInfo()) {
          FinRouter.editServer(this.getUIContext())
        } else {
          FinRouter.auth(this.getUIContext())
        }
      })
      this.preferItemBuilder($r('sys.symbol.worldclock'), $r('app.string.prefer_address'), () => {
        if (this.repository?.getActiveInfo()) {
          FinRouter.editAddress(this.getUIContext())
        } else {
          FinRouter.auth(this.getUIContext())
        }
      })
      this.preferItemBuilder($r('sys.symbol.person'), $r('app.string.prefer_user'), () => {
        if (this.repository?.getActiveInfo()) {
          FinRouter.editUser(this.getUIContext())
        } else {
          FinRouter.auth(this.getUIContext())
        }
      })

      this.preferItemBuilder($r('sys.symbol.doc_plaintext'), $r('app.string.prefer_privacy'), () => {
        WebTool.openBrowser(getContext(), "https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1574188982982436096")
      })

      Blank()

      Row({space: CommonConstants.SPACE_4}) {
        Text($r('app.string.prefer_about_qq_group'))
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))

        Text($r('app.string.prefer_about_qq_group_value'))
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_component_activated'))
          .onClick(() => {
            let text = getContext().resourceManager
              .getStringSync($r('app.string.prefer_about_qq_group_value'))
            const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
            const systemPasteboard = pasteboard.getSystemPasteboard();
            systemPasteboard.setData(pasteboardData);
            this.getUIContext().getPromptAction().showToast({message: $r('app.string.prefer_about_qq_group_copied')})
          })
      }

      Row({space: CommonConstants.SPACE_4}) {
        Text("ICP备案：")
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))

        Text("豫ICP备2025110731号-6A")
          .fontColor($r('sys.color.ohos_id_color_component_activated'))
          .onClick(() => {
            WebTool.openBrowser(getContext(), "https://beian.miit.gov.cn")
          })
      }
      .margin(CommonConstants.SPACE_16)
    }
    .padding({
      bottom: px2vp(this.currentAvoidArea?.bottomRect.height)
    })
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }
}