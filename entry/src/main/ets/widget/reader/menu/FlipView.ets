import { readerCore } from '@kit.ReaderKit';
import { FlipMode } from '../enum/FlipMode';
import { CommonConstants } from '../../../common/CommonConstants';

@Component
export struct FlipView {

  @Consume bookSetting: readerCore.ReaderSetting

  @State flipMenu: boolean = false

  aboutToAppear(): void {
    this.bookSetting.flipMode
  }

  @Builder
  bindFlipModelMenu() {
    Menu() {
      MenuItem({ content: '仿真模式' })
        .selectIcon(true)
        .selected(this.bookSetting.flipMode === FlipMode.PAPER)
        .onClick(() => {
          this.bookSetting.flipMode = FlipMode.PAPER
        })

      MenuItem({ content: '横滑模式' })
        .selectIcon(true)
        .selected(this.bookSetting.flipMode === FlipMode.SLID)
        .onClick(() => {
          this.bookSetting.flipMode = FlipMode.SLID
        })
    }
  }

  build() {
    Column() {
      Row() {
        Row() {
          Text('翻页方式')
            .fontSize(16)
            .fontColor(Color.Black)
            .margin({ left: 16 })

          Row() {
            Text(this.bookSetting.flipMode === FlipMode.PAPER ? '仿真模式' : '横滑翻页')
              .fontSize(16)
              .fontColor(Color.Black)
              .margin({ left: 16 })
            SymbolGlyph($r('sys.symbol.hand_point_up_tap_fill'))
              .fontSize(18)
              .fontWeight(600)
              .renderingStrategy(SymbolRenderingStrategy.SINGLE)
              .effectStrategy(SymbolEffectStrategy.NONE)
          }
          .clickEffect({ level: ClickEffectLevel.MIDDLE })
          .bindContextMenu(this.flipMenu, this.bindFlipModelMenu, {
            aboutToDisappear: () => {
              this.flipMenu = false
            }
          })
          .onClick(() => {
            this.flipMenu = true
          })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('60%')
      .margin({ top: 24, left: 16, right: 16 })
    }
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)
    .width(CommonConstants.FULL_PERCENT)
    .hitTestBehavior(HitTestMode.Transparent)
  }
}