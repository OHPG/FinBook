import { BreakpointSystem, FinItem, FinItemType } from "@ohpg/fin-core"
import { CommonConstants } from "@ohpg/fin-framework"
import { CategoryInfo } from "../../entity/CategoryInfo"
import { CategoryItem } from "./CategoryItem"
import { LibraryItem } from "./LibraryItem"
import { MediaItem } from "./MediaItem"

@Reusable
@Component
export struct MediaGroup {

  @Require @State item?: CategoryInfo = undefined

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT)
  currentWidthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM

  aboutToReuse(params: Record<string, object>): void {
    this.item = params['item'] as CategoryInfo
  }

  // 封面卡片宽度随宽度断点放大，Pad/大屏上封面更大（与 Library/Series 页一致）
  private mediaItemWidth(): number {
    if (this.currentWidthBreakpoint >= WidthBreakpoint.WIDTH_LG) {
      return 160
    }
    if (this.currentWidthBreakpoint >= WidthBreakpoint.WIDTH_MD) {
      return 140
    }
    return 110
  }

  build() {
    Column() {
      // title
      CategoryItem({item: this.item?.category})
      // list
      List({space: CommonConstants.SPACE_12}) {
        ForEach(this.item?.items, (item: FinItem, index: number) => {
          ListItem() {
            if (item.type === FinItemType.Folder) {
              LibraryItem({item: item, index: index, itemWidth: this.mediaItemWidth()})
            } else {
              MediaItem({item: item, itemWidth: this.mediaItemWidth()})
            }
          }
        })
      }
      .contentStartOffset(CommonConstants.SPACE_16)
      .contentEndOffset(CommonConstants.SPACE_16)
      .width(CommonConstants.FULL_PERCENT)
      .scrollBar(BarState.Off)
      .listDirection(Axis.Horizontal)
    }
    .width(CommonConstants.FULL_PERCENT)
  }

  aboutToRecycle(): void {

  }
}