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
      MenuItem({ content: $r('app.string.menu_flip_normal')})
        .selectIcon(true)
        .selected(this.bookSetting.flipMode === FlipMode.PAPER)
        .onClick(() => {
          this.bookSetting.flipMode = FlipMode.PAPER
        })

      MenuItem({ content: $r('app.string.menu_flip_slid') })
        .selectIcon(true)
        .selected(this.bookSetting.flipMode === FlipMode.SLID)
        .onClick(() => {
          this.bookSetting.flipMode = FlipMode.SLID
        })
    }
  }

  build() {
    Row() {
      Row() {
        Text($r('app.string.menu_flip_title'))
          .fontSize(16)
          .margin({ left: 16 })

        Row() {
          Text(this.bookSetting.flipMode === FlipMode.PAPER
            ? $r('app.string.menu_flip_normal')
            : $r('app.string.menu_flip_slid'))
            .fontSize(16)
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
      .height(60)
      .width(CommonConstants.FULL_PERCENT)
      .constraintSize({maxWidth: 400})
      .justifyContent(FlexAlign.SpaceAround)
    }
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('sys.color.background_primary'))
    .borderRadius({ topRight: CommonConstants.CORNER_16, topLeft: CommonConstants.CORNER_16 })
    .width(CommonConstants.FULL_PERCENT)
    .onClick(() => {})
  }
}