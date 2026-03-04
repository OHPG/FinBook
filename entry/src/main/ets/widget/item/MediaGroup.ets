import { FinItem, FinItemType } from "@ohpg/fin-core"
import { CommonConstants } from "@ohpg/fin-framework"
import { CategoryInfo } from "../../entity/CategoryInfo"
import { CategoryItem } from "./CategoryItem"
import { LibraryItem } from "./LibraryItem"
import { MediaItem } from "./MediaItem"

@Reusable
@Component
export struct MediaGroup {

  @Require @State item?: CategoryInfo = undefined

  aboutToReuse(params: Record<string, object>): void {
    this.item = params['item'] as CategoryInfo
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
              LibraryItem({item: item, index: index})
            } else {
              MediaItem({item: item, itemWidth: 140})
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