import { BreakpointSystem } from '@ohpg/fin-core'
import { CommonConstants } from '../../common/CommonConstants'
import { HomeControl } from './HomeControl'
import { LocalPage } from './local/LocalPage'
import { window } from '@kit.ArkUI'

@Entry
@Component
struct MainPage {

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT) currentWidthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM

  @StorageProp(BreakpointSystem.CURRENT_HEIGHT_BREAKPOINT) currentHeightBreakpoint: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM

  private homeControl = new HomeControl()

  aboutToAppear(): void {
    AppStorage.setOrCreate("currentHomeControl", this.homeControl)
  }

  build() {
    Stack() {
      LocalPage()
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
    }
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
  }

  onBackPress(): boolean | void {
    return this.homeControl.goBack()
  }

  aboutToDisappear(): void {
    AppStorage.delete("currentHomeControl")
  }

}