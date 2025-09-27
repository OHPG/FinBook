import { GridRefreshView } from '@ohpg/fin-framework'
import { CommonConstants } from '../../common/CommonConstants'
import { HomeToolBar } from '../../widget/bar/HomeToolBar'
import { HomeViewModel } from './HomeViewModel'
import { window } from '@kit.ArkUI'
import { FinItem } from '@ohpg/fin-core'
import { Repository } from '../../data/Repository'
import { MediaArgs } from '../detail/MediaArgs'
import { AppRouter } from '../../router/AppRouter'

@Entry
@Component
struct HomePage {

  private viewModel = new HomeViewModel(getContext())

  @StorageProp('currentBreakpoint') currentBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  aboutToAppear(): void {
    this.viewModel.loadData('Init')
  }

  @Builder
  mediaListView(info: ESObject, index: number) {
    MediaItem({item: info})
  }

  build() {

    Column() {
      HomeToolBar({
        title: $r('app.string.app_name')
      })

      GridRefreshView({
        source: this.viewModel,
        gridAttribute: (attr) => {
          attr.padding = {
            left: CommonConstants.SPACE_16,
            right: CommonConstants.SPACE_16,
            bottom: px2vp(this.currentAvoidArea?.bottomRect.height)
          }
          attr.rowsGap = CommonConstants.SPACE_12
          attr.columnsGap = CommonConstants.SPACE_12
          attr.columnsTemplate = ('1fr 1fr')
          attr.width = CommonConstants.FULL_PERCENT
          attr.height = CommonConstants.FULL_PERCENT
        },
        itemLayout: this.mediaListView
      })
        .width(CommonConstants.FULL_PERCENT)
        .layoutWeight(1)
    }

  }

}


@Reusable
@Component
struct MediaItem {

  @StorageLink("Repository") repository?: Repository = undefined

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
      AppRouter.goToDetail(this.getUIContext(), args)
    })
  }

  aboutToRecycle(): void {
  }

}