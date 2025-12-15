import { HomeToolBar } from "../../../widget/bar/HomeToolBar"
import { SandboxFinder } from "@cxy/sandboxfinder"
import { common } from "@kit.AbilityKit"
import { AppDir } from "../../../app/AppDir"
import { CommonConstants } from "../../../common/CommonConstants"

@Component
export struct WifiPage {

  private appDir = new AppDir(this.getUIContext().getHostContext()!)

  @State wifiWorking: boolean = false

  @State wifiInfo: string = ""

  build() {
    Column() {
      HomeToolBar({
        title: $r('app.string.tab_wifi'),
      })
      Stack() {
        Column() {
          Button("打开")
            .onClick(() => {
              this.openFinder()
            })
          Button("关闭")
            .onClick(() => {
              this.closeFinder()
            })

          Text(this.wifiInfo)
        }
      }
        .width(CommonConstants.FULL_PERCENT)
        .layoutWeight(1)
    }
  }

  private async openFinder(): Promise<void> {
    try {
      let path = await this.appDir.acquireRootUri(this.getUIContext().getHostContext()!)
      let info = await SandboxFinder.run(this.getUIContext().getHostContext()! as common.UIAbilityContext, 8888, path)
      this.wifiInfo = JSON.stringify(info)
      this.wifiWorking = true
    } catch (e) {
    }
  }

  private closeFinder() {
    if (!this.wifiWorking) return
    SandboxFinder.stop()
    this.wifiWorking = false
  }

}