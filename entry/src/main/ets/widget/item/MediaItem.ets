import { ImageKnifeComponent } from '@ohos/imageknife'
import { FinItem, FinItemType } from '@ohpg/fin-core'
import { CommonConstants } from '@ohpg/fin-framework'
import { MediaArgs } from '../../pages/detail/MediaArgs'
import { AppRouter } from '../../router/AppRouter'

@Reusable
@Component
export struct MediaItem {

  @Require @State item?: FinItem = undefined

  aboutToReuse(params: Record<string, object>): void {
    this.item = params['item'] as FinItem
  }
  build() {
    Column({space: CommonConstants.SPACE_8}) {
      Image(this.item?.image?.primary)
        .alt($r('app.media.alt'))
        .objectFit(ImageFit.Cover)
        .autoResize(true)
        .borderRadius(CommonConstants.SPACE_16)
        .width('100%')
        .aspectRatio(0.67)

      Text(this.item?.name)
        .width('100%')
        .maxLines(1)
    }
    .onClick(() => {
      let args: MediaArgs = {
        id: this.item?.id!,
        name: this.item?.name!,
      }
      if (this.item?.type === FinItemType.Folder) {
        AppRouter.goToGrid(this.getUIContext(), args)
      } else {
        AppRouter.goToDetail(this.getUIContext(), args)
      }
    })
  }

  aboutToRecycle(): void {
  }

}