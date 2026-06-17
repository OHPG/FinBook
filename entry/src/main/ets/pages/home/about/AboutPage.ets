import { window } from '@kit.ArkUI'
import { MarketUtil } from '@ohpg/fin-core'
import { CommonConstants, FinRouter, FinWebTool, ToolBar } from '@ohpg/fin-framework'
import { pasteboard } from '@kit.BasicServicesKit'
import { Repository } from '../../../data/Repository'
import { AppRouter } from '../../../router/AppRouter'
import { FileUtil } from '../../../util/FileUtil'
import { common } from '@kit.AbilityKit'
import { PreferItem } from '../../../widget/item/PreferItem'
import { groupAttributeModifier, itemDividerBuilder } from '../../../style/Modifier'
import BuildProfile from 'BuildProfile'
import { HomeToolBar } from '../../../widget/bar/HomeToolBar'

@Component
export struct AboutPage {

  @Consume("navBottomOffset") navBottomOffset: number

  @Consume("navStartOffset") navStartOffset: number

  private repository: Repository = AppStorage.get(Repository.REPOSITORY)!

  private showClearLocalCopyDialog() {
    this.getUIContext().getPromptAction().showDialog({
      title: getContext().resourceManager.getStringSync($r('app.string.prefer_clear_local_copy_confirm_title')),
      message: getContext().resourceManager.getStringSync($r('app.string.prefer_clear_local_copy_confirm_msg')),
      buttons: [
        { text: getContext().resourceManager.getStringSync($r('app.string.prefer_clear_local_copy_cancel')), color: $r('sys.color.ohos_id_color_text_secondary') },
        { text: getContext().resourceManager.getStringSync($r('app.string.prefer_clear_local_copy_confirm')), color: $r('sys.color.ohos_id_color_warning') }
      ]
    }).then((result) => {
      if (result.index === 1) {
        FileUtil.clearLocalCopyFiles(getContext()).then(() => {
          this.getUIContext().getPromptAction().showToast({ message: $r('app.string.prefer_clear_local_copy_success') })
        })
      }
    })
  }

  build() {
    Column({space: CommonConstants.SPACE_8}) {
      HomeToolBar({
        title: $r('app.string.about')
      })

      Scroll() {
        Column() {

          Column() {
            // 服务器设置组
            PreferItem({
              icon: $r('sys.symbol.externaldrive'),
              title: $r('app.string.prefer_server'),
              tips: this.repository?.getActiveInfo()?.serverInfo.serverName || $r('app.string.prefer_server_hint'),
              callback: () => {
                if (this.repository?.getActiveInfo()) {
                  FinRouter.editServer(this.getUIContext())
                } else {
                  FinRouter.auth(this.getUIContext())
                }
              }
            })

            itemDividerBuilder()

            PreferItem({
              icon: $r('sys.symbol.worldclock'),
              title: $r('app.string.prefer_address'),
              tips: this.repository?.getActiveInfo()?.addressInfo.address || $r('app.string.prefer_server_hint'),
              callback: () => {
                if (this.repository?.getActiveInfo()) {
                  FinRouter.editAddress(this.getUIContext())
                } else {
                  FinRouter.auth(this.getUIContext())
                }
              }
            })

            itemDividerBuilder()

            PreferItem({
              icon: $r('sys.symbol.person'),
              title: $r('app.string.prefer_user'),
              tips: this.repository?.getActiveInfo()?.userInfo.userName || $r('app.string.prefer_server_hint'),
              callback: () => {
                if (this.repository?.getActiveInfo()) {
                  FinRouter.editUser(this.getUIContext())
                } else {
                  FinRouter.auth(this.getUIContext())
                }
              }
            })
          }
          .attributeModifier(groupAttributeModifier)

          Column() {
            // 界面设置
            PreferItem({
              icon: $r('sys.symbol.satellite_map_fill'),
              title: $r('app.string.prefer_interface'),
              callback: () => {
                AppRouter.goToInterface(this.getUIContext())
              }
            })

            itemDividerBuilder()

            // 清理缓存
            PreferItem({
              icon: $r('sys.symbol.trash'),
              title: $r('app.string.prefer_clear_local_copy'),
              callback: () => {
                this.showClearLocalCopyDialog()
              }
            })
          }
          .attributeModifier(groupAttributeModifier)

          Column() {

            // 隐私政策
            PreferItem({
              icon: $r('sys.symbol.doc_plaintext'),
              title: $r('app.string.prefer_privacy'),
              callback: () => {
                FinWebTool.open(this.getUIContext(), $r('app.string.prefer_privacy'), "https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1574188982982436096")
              }
            })

            itemDividerBuilder()

            // 版本信息
            PreferItem({
              icon: $r('sys.symbol.bag'),
              title: $r('app.string.prefer_version'),
              tips: `V${BuildProfile.VERSION_NAME}(${BuildProfile.VERSION_CODE})`,
              callback: () => {
                MarketUtil.gotoMarket(this.getUIContext().getHostContext()! as common.UIAbilityContext)
              }
            })
          }
          .attributeModifier(groupAttributeModifier)
        }
        .constraintSize({minHeight: "100%"})
      }
      .width(CommonConstants.FULL_PERCENT)
      .layoutWeight(1)

      // 联系信息
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
      // ICP备案信息
      Row({space: CommonConstants.SPACE_4}) {
        Text("ICP备案：")
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))

        Text("豫ICP备2025110731号-6A")
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_component_activated'))
          .onClick(() => {
            FinWebTool.openSystemBrowser(this.getUIContext(), "https://beian.miit.gov.cn")
          })
      }
    }
    .alignItems(HorizontalAlign.Center)
    .padding({left: this.navStartOffset, bottom: this.navBottomOffset})
    .backgroundColor($r('sys.color.background_secondary'))
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }
}