import { HomeToolBar } from "../../../widget/bar/HomeToolBar"
import { ProgressDialog } from "@ohpg/fin-framework"
import { SandboxFinder } from "@cxy/sandboxfinder"
import { common } from "@kit.AbilityKit"
import { AppDir } from "../../../app/AppDir"
import { CommonConstants } from "../../../common/CommonConstants"
import { ContinuousTask } from "../../../task/ContinuousTask"
import { socket } from "@kit.NetworkKit";

@Component
export struct WifiPage {

  private appDir = new AppDir(this.getUIContext().getHostContext()!)

  private appTask = new ContinuousTask(this.getUIContext().getHostContext()!)

  private progressDialog = new ProgressDialog(this.getUIContext())

  @State wifiAddress?: socket.NetAddress = undefined

  @State wifiInfo: ResourceStr = $r('app.string.trans_normal_tips')

  build() {
    Column() {
      HomeToolBar({
        title: $r('app.string.tab_trans'),
      })
      Column() {

        Stack() {
          Button(this.wifiAddress ? $r('app.string.trans_stop') : $r("app.string.trans_start"))
            .width(100)
            .onClick(() => {
              this.toggleFinder()
            })
        }
          .width(CommonConstants.FULL_PERCENT)
          .layoutWeight(1)

        Text(this.wifiInfo)
          .textAlign(TextAlign.Center)
          .width(CommonConstants.FULL_PERCENT)
          .layoutWeight(2)

      }
        .width(CommonConstants.FULL_PERCENT)
        .layoutWeight(1)
    }
  }

  private toggleFinder() {
    if (this.wifiAddress) {
      this.closeFinder()
    } else {
      this.openFinder()
    }
  }

  private async openFinder(): Promise<void> {
    try {
      await this.progressDialog.show()
      await this.appTask.startContinuousTask()
      let path = await this.appDir.acquireRootUri(this.getUIContext().getHostContext()!)
      this.wifiAddress = await SandboxFinder.run(this.getUIContext().getHostContext()! as common.UIAbilityContext, 8888, path)
      let address = `http://${this.wifiAddress.address}:${this.wifiAddress.port}`
      this.wifiInfo = $r('app.string.trans_working_tips', address)
    } catch (e) {
      this.wifiInfo = $r('app.string.trans_working_error', (e as Error).message)
    }
    await this.progressDialog.dismiss(true)
  }

  private async closeFinder(): Promise<void> {
    if (!this.wifiAddress) return
    try {
      await SandboxFinder.stop()
    } catch (e) {
    } finally {
      this.appTask.stopContinuousTask()
      this.wifiAddress = undefined
      this.wifiInfo = $r('app.string.trans_normal_tips')
    }
  }

  aboutToDisappear(): void {
    this.closeFinder()
  }

}