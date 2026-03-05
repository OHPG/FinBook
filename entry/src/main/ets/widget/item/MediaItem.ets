import { FinItem, FinItemType } from '@ohpg/fin-core'
import { CommonConstants } from '@ohpg/fin-framework'
import { MediaArgs } from '../../pages/detail/MediaArgs'
import { AppRouter } from '../../router/AppRouter'
import { CoverImage } from '../cover/CoverImage'

@Reusable
@Component
export struct MediaItem {

  @Require @State item?: FinItem = undefined

  @State itemWidth: string | number = CommonConstants.FULL_PERCENT

  aboutToReuse(params: Record<string, object>): void {
    this.item = params['item'] as FinItem
  }
  build() {
    Column({space: CommonConstants.SPACE_8}) {

      CoverImage({ image: this.item?.image, imageBorderRadius: CommonConstants.SPACE_16 })
        .width('100%')
        .aspectRatio(0.67)

      Text(this.item?.name)
        .width('100%')
        .wordBreak(WordBreak.BREAK_ALL)
        .maxLines(1)
    }
    .width(this.itemWidth)
    .onClick(() => {
      let args: MediaArgs = {
        id: this.item?.id!,
        name: this.item?.name!,
        type: this.item?.type
      }
      if (this.item?.type === FinItemType.Series) {
        AppRouter.goToSeries(this.getUIContext(), args)
      } else {
        AppRouter.goToDetail(this.getUIContext(), args)
      }
    })
  }

  aboutToRecycle(): void {
  }

}