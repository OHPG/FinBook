import { window } from "@kit.ArkUI"
import { CommonConstants } from "../../common/CommonConstants"
import { SearchArgs } from "../../pages/search/SearchArgs"
import { AppRouter } from "../../router/AppRouter"

@Component
export struct HomeToolBar {

  @Require @Prop title: ResourceStr

  @Prop searchEnable: boolean = false

  searchCallback?: Callback<SearchArgs>

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

        if (this.searchEnable) {
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
                this.searchCallback?.(searchArgs)
              })
          }
        }
      }
      .padding({
        left: CommonConstants.SPACE_16,
        right: CommonConstants.SPACE_16
      })
      .justifyContent(FlexAlign.SpaceBetween)
      .width(CommonConstants.FULL_PERCENT)
      .height($r('app.float.top_navigation_height'))
    }
  }

}