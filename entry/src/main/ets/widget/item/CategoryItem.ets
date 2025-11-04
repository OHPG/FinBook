import { CommonConstants } from "@ohpg/fin-framework";
import { CategoryInfo } from "../../entity/CategoryInfo";
import { AppRouter } from "../../router/AppRouter";

@Reusable
@Component
export struct CategoryItem {

  @Require @State item?: CategoryInfo = undefined

  aboutToReuse(params: Record<string, object>): void {
    this.item = params['item'] as CategoryInfo
  }

  build() {

    Row() {
      Text(this.item?.category?.name)
        .fontSize($r('app.float.lg_font_size'))
        .fontWeight(FontWeight.Medium)
        .fontFamily(CommonConstants.HARMONY_HEITI_MEDIUM_FONT_FAMILY)
      if (/*this.item?.type === "Normal"*/true) {
        Row() {
          Text($r('app.string.more'))
            .fontSize($r('app.float.md_font_size'))
            .opacity(CommonConstants.SECOND_LEVEL_OPACITY)

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .opacity(CommonConstants.THIRD_LEVEL_OPACITY)
            .fontSize($r('app.float.more_arrow_icon_height'))
        }
        .onClick(() => {
          if (!this.item) return
          AppRouter.goToGrid(this.getUIContext(), {
            name: this.item.category.name,
            id: this.item.category.id
          })
        })
      }
    }
    .alignItems(VerticalAlign.Center)
    .padding({
      right: CommonConstants.SPACE_16,
      left: CommonConstants.SPACE_16,
      top: CommonConstants.SPACE_8,
      bottom: CommonConstants.SPACE_8
    })
    .width(CommonConstants.FULL_PERCENT)
    .justifyContent(FlexAlign.SpaceBetween)
  }

  aboutToRecycle(): void {
  }
}