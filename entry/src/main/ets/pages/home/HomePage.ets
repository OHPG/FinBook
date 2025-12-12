import { window } from '@kit.ArkUI'
import { BreakpointSystem } from '@ohpg/fin-core'
import { CommonConstants } from '../../common/CommonConstants'
import { AboutPage } from './about/AboutPage'
import { HomeControl } from './HomeControl'
import { LocalPage } from './local/LocalPage'
import { OnlinePage } from './online/OnlinePage'
import { StoragePage } from './storage/StoragePage'

@Entry
@Component
struct HomePage {

  @State currentIndex: number = 0;

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT) currentWidthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM

  @StorageProp(BreakpointSystem.CURRENT_HEIGHT_BREAKPOINT) currentHeightBreakpoint: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM

  private tabsController: TabsController = new TabsController();

  private homeControl = new HomeControl()

  aboutToAppear(): void {
    AppStorage.setOrCreate("currentHomeControl", this.homeControl)
  }

  @Builder TabBuilder(title: ResourceStr, targetIndex: number, img: Resource) {
    Column({
      space: CommonConstants.SPACE_4
    }) {
      SymbolGlyph(img)
        .fontSize(24)
        .fontColor([this.currentIndex === targetIndex ?  '#1698CE' : '#6B6B6B' ])
      Text(title)
        .fontSize($r('sys.float.Body_M'))
        .fontColor(this.currentIndex === targetIndex ? '#1698CE' : '#6B6B6B')
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
      this.tabsController.changeIndex(this.currentIndex);
    })
  }

  // https://developer.huawei.com/consumer/cn/design/harmonyos-symbol/
  build() {
    Tabs({ barPosition: this.currentWidthBreakpoint >= WidthBreakpoint.WIDTH_MD
      ? BarPosition.Start : BarPosition.End, controller: this.tabsController }) {
      TabContent() {
        LocalPage()
      }
      .tabBar(this.TabBuilder($r('app.string.tab_local'), 0, $r('sys.symbol.house_fill')))

      TabContent() {
        StoragePage()
      }
      .tabBar(this.TabBuilder($r('app.string.tab_storage'), 1, $r('sys.symbol.externaldrive_fill_3')))

      TabContent() {
        OnlinePage()
      }
      .tabBar(this.TabBuilder($r('app.string.tab_online'), 2, $r('sys.symbol.worldclock_fill')))

      TabContent() {
        AboutPage()
      }
      .tabBar(this.TabBuilder($r('app.string.tab_about'), 3, $r('sys.symbol.square_fill_grid_2x2')))
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .vertical(this.currentWidthBreakpoint >= WidthBreakpoint.WIDTH_MD)
    .barWidth(this.currentWidthBreakpoint >= WidthBreakpoint.WIDTH_MD ? 72 : '100%')
    .barHeight(this.currentWidthBreakpoint >= WidthBreakpoint.WIDTH_MD ? '100%' : 50)
    .animationDuration(0)
    .backgroundColor($r('sys.color.background_primary'))
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .padding({
      bottom: this.currentWidthBreakpoint >= WidthBreakpoint.WIDTH_MD
        ? 0
        : px2vp(this.currentAvoidArea?.bottomRect.height)
    })
    .scrollable(false)
    .width('100%')
    .height('100%')
  }

  onBackPress(): boolean | void {
    if (this.currentIndex > 0) {
      return false
    }
    return this.homeControl.goBack()
  }

  aboutToDisappear(): void {
    AppStorage.delete("currentHomeControl")
  }

}