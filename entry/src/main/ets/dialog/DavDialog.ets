import { Dialog } from "./Dialog";
import { ComponentContent } from "@kit.ArkUI";
import { CommonConstants } from "../common/CommonConstants";
import { AuthType, WebDAV } from "@ohpg/dav";
import { ProgressDialog } from "./ProgressDialog";
import { DataStore } from "../store/DataStore";
import { StorageInfo } from "../store/entity/StorageInfo";
import { AppEvent } from "../event/AppEvent";
import { MD5 } from "../crypto/MD5";
import { uri } from "@kit.ArkTS";
import { ProtocolType } from "../enum/ProtocolType";
import { WebTool } from "../tool/WebTool";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/8/9 15:49
 * @Version V1.0
 * @Description WebDAV dialog
 */
export class DavDialog extends Dialog {

  private info?: StorageInfo

  public setStorageInfo(info?: StorageInfo) {
    this.info = info
  }

  protected onCreateContent(): ComponentContent<object> {
    let args: DavArgs = {
      info: this.info,
      callback: () => {
        this.dismiss(true)
      }
    }
    return new ComponentContent(this.uiContext, wrapBuilder(addDavBuilder), args)
  }

}

interface DavArgs {

  info?: StorageInfo

  callback?: Callback<void>

}

@Builder
function addDavBuilder(args: DavArgs) {
  DavComponent({
    args: args
  })
    .align(Alignment.Center)
    .onClick(() => {
      args.callback?.()
    })
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .width('100%')
    .height('100%')
}

@Component
struct DavComponent {

  args?: DavArgs

  private readonly progressDialog = new ProgressDialog(this.getUIContext())

  private readonly dataStore: DataStore = AppStorage.get(DataStore.DATA_STORE)!

  @State name?: string = undefined

  @State address?: string = undefined

  @State port: string = "80"

  @State auth: boolean = true

  @State userName?: string = undefined

  @State userPsw?: string = undefined

  @State path?: string = undefined

  aboutToAppear(): void {
    if (this.args?.info) {
      let info = this.args.info
      this.name = info.name
      let u = new uri.URI(info.url)
      this.address = u.scheme + "://" + u.host
      this.port = u.port
      this.path = u.path
      if (info.authType !== AuthType.NONE) {
        this.userName = info.authName
        this.userPsw = info.authPsw
        this.auth = true
      } else {
        this.auth = false
      }
    }
  }

  build() {

    Column({space: CommonConstants.SPACE_12}) {
      Text($r("app.string.storage_dav"))
        .fontSize(22)

      // 名称
      Row({space: CommonConstants.SPACE_8}) {
        Text($r('app.string.storage_name'))
        TextInput({text: $$this.name, placeholder: $r('app.string.storage_name_hint')})
          .layoutWeight(1)
      }

      // 地址
      Row({space: CommonConstants.SPACE_8}) {
        Text($r('app.string.storage_address'))
        TextInput({text: $$this.address, placeholder: $r('app.string.storage_address_dav_hint')})
          .type(InputType.URL)
          .layoutWeight(1)
      }

      // 端口
      Row({space: CommonConstants.SPACE_8}) {
        Text($r('app.string.storage_port'))
        TextInput({text: $$this.port})
          .type(InputType.Number)
          .layoutWeight(1)
      }

      // 认证
      Row({space: CommonConstants.SPACE_8}) {
        Text($r('app.string.storage_auth'))
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: $$this.auth })
      }
      .width(CommonConstants.FULL_PERCENT)

      // 用户名
      Row({space: CommonConstants.SPACE_8}) {
        Text($r('app.string.storage_user_name'))
        TextInput({text: $$this.userName})
          .layoutWeight(1)
      }
      .visibility(this.auth ? Visibility.Visible : Visibility.None)

      // 密码
      Row({space: CommonConstants.SPACE_8}) {
        Text($r('app.string.storage_user_psw'))
        TextInput({text: $$this.userPsw})
          .type(InputType.Password)
          .layoutWeight(1)
      }
      .visibility(this.auth ? Visibility.Visible : Visibility.None)

      // 路径
      Row({space: CommonConstants.SPACE_8}) {
        Text($r('app.string.storage_path'))
        TextInput({text: $$this.path, placeholder: $r('app.string.storage_path_dav_hint')})
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.questionmark_circle'))
          .fontSize(24)
          .fontColor([$r('sys.color.ohos_id_color_text_primary')])
          .onClick(() => {
            WebTool.openBrowserDAV(this.getUIContext().getHostContext()!)
          })
      }

      Row({space: CommonConstants.SPACE_8}) {

        Text($r('app.string.storage_cancel'))
          .textAlign(TextAlign.Center)
          .height(48)
          .width(64)
          .onClick(() => {
            this.args?.callback?.()
          })

        Text($r('app.string.storage_add'))
          .textAlign(TextAlign.Center)
          .fontColor($r('sys.color.ohos_id_color_activated'))
          .height(48)
          .width(64)
          .onClick(() => {
            this.addServer()
          })

      }
      .justifyContent(FlexAlign.End)
      .width(CommonConstants.FULL_PERCENT)

    }
    .onClick(() => {})
    .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
    .border({ radius: CommonConstants.SPACE_16 })
    .padding(CommonConstants.SPACE_16)
    .width(360)
    .height('auto')
    .constraintSize({
      minWidth: 300,
      maxWidth: '80%'
    })

  }

  aboutToDisappear(): void {


  }

  private async addServer() {
    let name = this.name?.trim()
    if (!name || name.length <= 0) {
      this.getUIContext().getPromptAction().showToast({message: $r('app.string.storage_name_empty')})
      return
    }

    let address = this.address?.trim()
    if (!address || address.length <= 0) {
      this.getUIContext().getPromptAction().showToast({message: $r('app.string.storage_address_empty')})
      return
    }
    if (!address.startsWith('http')) {
      this.getUIContext().getPromptAction().showToast({message: $r('app.string.storage_address_invalidate')})
      return
    }

    let port = this.port?.trim()
    if (!port || port.length <= 0) {
      this.getUIContext().getPromptAction().showToast({message: $r('app.string.storage_port_empty')})
      return
    }

    let userName: string | undefined
    let userPsw: string | undefined
    if (this.auth) {
      if (!this.userName || this.userName.trim().length <= 0) {
        this.getUIContext().getPromptAction().showToast({message: $r('app.string.storage_user_name_empty')})
        return
      }
      userName = this.userName.trim()

      if (!this.userPsw || this.userPsw.trim().length <= 0) {
        this.getUIContext().getPromptAction().showToast({message: $r('app.string.storage_user_psw_empty')})
        return
      }
      userPsw = this.userPsw.trim()
    }

    // path可以为空
    let url = address + ":" + port
    let path = this.path?.trim()
    if (path && path.length > 0) {
      if (!path.startsWith("/")) {
        path = "/" + path
      }
      url += path
    }
    let authType = this.auth ? AuthType.Basic : AuthType.NONE
    let dav = new WebDAV(url, authType, userName, userPsw)
    try {
      await this.progressDialog.show()
      await dav.connect()
      // insert
      let storageInfo: StorageInfo = {
        // 复用之前的id
        id: this.args?.info?.id
          ? this.args?.info?.id
          : MD5.digestSync(name + "-" + url),
        type: ProtocolType.DAV,
        name: name,
        url: url,
        authType: authType,
        authName: userName,
        authPsw: userPsw,
        time: Date.now()
      }
      await this.dataStore.insertStorageInfo(storageInfo)
      // notify
      this.getUIContext().getHostContext()?.eventHub.emit(AppEvent.EVENT_STORAGE_CHANGED)
      this.args?.callback?.()
    } catch (e) {
      let msg = (e as Error).message
      if (!msg) {
        msg = e["data"]
      }
      this.getUIContext().getPromptAction().showToast({message: msg})
    } finally {
      await this.progressDialog.dismiss(true)
      dav.disconnect()
    }
  }

}