import { window } from '@kit.ArkUI'
import { WebTool } from '@ohpg/fin-core'
import { Repository } from '../../data/Repository'
import { CommonConstants } from '../../common/CommonConstants'
import { FinRouter, ToolBar } from '@ohpg/fin-framework'
import { pasteboard } from '@kit.BasicServicesKit'

@Entry
@Component
struct AboutPage {

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
      ToolBar({
        title: $r('app.string.about')
      })

      Column({ space: CommonConstants.SPACE_12}) {
        Row() {
          Text($r('app.string.prefer_current_server'))
          Text(this.repository?.getActiveInfo()?.serverInfo.serverName)
        }
        Row() {
          Text($r('app.string.prefer_current_address'))
          Text(this.repository?.getActiveInfo()?.addressInfo.address)
        }
        Row() {
          Text($r('app.string.prefer_current_user'))
          Text(this.repository?.getActiveInfo()?.userInfo.userName)
        }
      }
      .width(CommonConstants.FULL_PERCENT)
      .alignItems(HorizontalAlign.Start)
      .padding({
        left: CommonConstants.SPACE_16,
        right: CommonConstants.SPACE_16
      })

      this.preferItemBuilder($r('sys.symbol.externaldrive'), $r('app.string.prefer_server'), () => {
        FinRouter.editServer()
      })
      this.preferItemBuilder($r('sys.symbol.worldclock'), $r('app.string.prefer_address'), () => {
        FinRouter.editAddress()
      })
      this.preferItemBuilder($r('sys.symbol.person'), $r('app.string.prefer_user'), () => {
        FinRouter.editUser()
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