import { window } from "@kit.ArkUI"
import { CommonConstants } from "../../common/CommonConstants"
import { SearchArgs } from "../../pages/search/SearchArgs"
import { AppRouter } from "../../router/AppRouter"

@Component
export struct HomeToolBar {

  @Require @Prop title: ResourceStr

  @StorageProp("currentAvoidArea") avoidArea?: window.AvoidArea = undefined

  build() {
    Column() {
      Column()
        .width('100%')
        .height(px2vp(this.avoidArea?.topRect.height))

      Row() {
        Text(this.title)
          .fontSize($r('app.float.header_font_size'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Start)
          .fontFamily(CommonConstants.HARMONY_HEITI_BOLD_FONT_FAMILY)
          .margin({ right: $r('app.float.sm_padding_margin') })

        Row({space: CommonConstants.SPACE_8}) {
          Search({ placeholder: $r('app.string.search_title') })
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .textFont({ size: $r('app.float.large_text_size') })
            .width($r('app.float.search_width'))
            .height($r('app.float.search_height'))
            .onSubmit((word: string) => {
              this.getUIContext().getFocusController().clearFocus()
              let searchArgs: SearchArgs = {
                word: word
              }
              AppRouter.goToSearch(this.getUIContext(), searchArgs)
            })

          SymbolGlyph($r('sys.symbol.gearshape_fill'))
            .fontSize($r('app.float.header_font_size'))
            .fontColor([$r('sys.color.ohos_id_color_text_primary')])
            .onClick(() => {
              AppRouter.goToAbout(this.getUIContext())
            })
        }
      }
      .padding({
        left: $r('app.float.xxl_padding_margin'),
        right: $r('app.float.lg_padding_margin'),
      })
      .justifyContent(FlexAlign.SpaceBetween)
      .width(CommonConstants.FULL_PERCENT)
      .height($r('app.float.top_navigation_height'))
    }
  }

}