import { FinItem } from '@ohpg/fin-core'
import { CommonConstants } from '@ohpg/fin-framework'
import { MediaArgs } from '../../pages/detail/MediaArgs'
import { AppRouter } from '../../router/AppRouter'

const COLORS: Array<string> = [
  "#0068BA", "#00A8E9", "#91D5F1", "#CFDFEF", "#E1BB3E",
  "#00427C", "#006DA1", "#80B7DE", "#F08160", "#EDD1B9",
  "#0068A7", "#61B0D3", "#F1F0F8", "#6C84B1", "#F8B5B5"
]

@Reusable
@Component
export struct LibraryItem {

  @Require @State item?: FinItem = undefined

  @Require @State index: number = 0

  aboutToReuse(params: Record<string, object>): void {
    this.item = params['item'] as FinItem
  }
  build() {
    Text(this.item?.name)
    .fontColor(Color.White)
    .textAlign(TextAlign.Center)
    .borderRadius(CommonConstants.SPACE_16)
    .height(60)
    .width(100)
    .backgroundColor(COLORS[this.index % COLORS.length])
    .onClick(() => {
      let args: MediaArgs = {
        id: this.item?.id!,
        name: this.item?.name!,
        type: this.item?.type
      }
      AppRouter.goToLibrary(this.getUIContext(), args)
    })
  }

  aboutToRecycle(): void {
  }

}