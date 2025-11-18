import { CommonConstants } from "../../../common/CommonConstants"
import { CataView } from "./CataView"
import { FlipView } from "./FlipView"
import { FontView } from "./FontView"
import { ThemeView } from "./ThemeView"
import { window } from "@kit.ArkUI"

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/10/11 15:22
 * @Version V1.0
 * @Description:
 */
@Component
export struct XMenuView {

  @StorageProp("currentAvoidArea") avoidArea?: window.AvoidArea = undefined

  @Consume menuVisible: boolean

  private tabsController: TabsController = new TabsController();

  @State currentIndex: number = 0;

  @Builder TabBuilder(title: ResourceStr, targetIndex: number, img: Resource) {
    Column({
      space: CommonConstants.SPACE_4
    }) {
      SymbolGlyph(img)
        .fontSize(18)
        .fontWeight(600)
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

  build() {
    Stack({alignContent: Alignment.Bottom}) {
      Row()
      .backgroundColor($r('sys.color.background_primary'))
        .width(CommonConstants.FULL_PERCENT)
        .height(50 + this.getUIContext().px2vp(this.avoidArea?.bottomRect.height) + 2)

      Tabs({ barPosition: BarPosition.End, controller: this.tabsController}) {
        TabContent() {
          CataView()
        }
        .tabBar(this.TabBuilder($r('app.string.menu_spine'), 0, $r('sys.symbol.list_bullet')))
        TabContent() {
          FontView()
        }
        .tabBar(this.TabBuilder($r('app.string.menu_font'), 1, $r('sys.symbol.textformat_size_square')))
        TabContent() {
          ThemeView()
        }
        .tabBar(this.TabBuilder($r('app.string.menu_theme'), 2, $r('sys.symbol.sun_min')))
        TabContent() {
          FlipView()
        }
        .tabBar(this.TabBuilder($r('app.string.menu_flip'), 3, $r('sys.symbol.book_open_fill')))
      }
      .vertical(false)
      .barWidth(CommonConstants.FULL_PERCENT)
      .barHeight(50)
      .margin({bottom: this.getUIContext().px2vp(this.avoidArea?.bottomRect.height)})
      .scrollable(false)
      .animationDuration(0)
      .width(CommonConstants.FULL_PERCENT)
      .height('auto')
      .onChange((index: number) => {
        this.currentIndex = index;
      })
    }
    .onClick(() => { this.menuVisible = false })
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

}