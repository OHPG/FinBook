import deviceInfo from "@ohos.deviceInfo"
import { AppEvent } from "../../event/AppEvent"
import { AppThumb } from "../../thumb/AppThumb"
import { fileUri } from '@kit.CoreFileKit';
import { MenuType } from "../../enum/MenuType"
import { window } from "@kit.ArkUI";
import { TreeData } from "./TreeData";
import { Pair } from "../../comp/Pair"
import { CommonConstants } from "../../common/CommonConstants";
import { FolderItem } from "../../entity/FolderItem";
import { BookItem } from "../../entity/BookItem";
import { BookHistory } from "../../entity/BookHistory";
import { ProgressDialog } from "@ohpg/fin-framework";
import LazyDataSource from "../../common/LazyDataSource";
import { BreakpointSystem } from "@ohpg/fin-core";

@Component
export struct TreeBodyView {

  private mediaDataSource = new LazyDataSource<BookItem>()

  @Require mediaData: TreeData

  @Require mediaItemCallback: Callback<BookItem>

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT) currentWidthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM

  @StorageProp(BreakpointSystem.CURRENT_HEIGHT_BREAKPOINT) currentHeightBreakpoint: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM

  @State isRefreshing: boolean = false

  @State info?: FolderItem = undefined

  @Consume emptyOrErrorResource: ResourceStr = $r('app.string.global_content_empty')

  @State errorOrEmptyContent: ResourceStr | undefined = undefined

  private readonly mediaMenuCallback: Callback<Pair<MenuType, BookItem>> = (item) => {
    if (item.first === MenuType.DELETE) {
      this.removeData(item.second)
    }
  }

  private readonly mediaHistoryChangeCallback: Function = (history: BookHistory) => {
    let index = this.mediaDataSource.getDataList().findIndex((item) => item.id === history.id)
    if (index <0 ) {
      return
    }
    let mediaItem = this.mediaDataSource.getData(index)
    mediaItem.history = history
    this.mediaDataSource.notifyDataChange(index)
  }

  private readonly mediaForceRefreshCallback: Function = () => {
    this.updateData(true)
  }

  private readonly mediaHistoryCleanCallback: Function = () => {
    // 切换为移除记录，并刷新列表。
    this.updateData(true)
  }

  private readonly mediaSortCallback = () => {
    this.sortData()
  }

  private async updateData(force?: boolean): Promise<void> {
    this.errorOrEmptyContent = undefined
    // 更新当前目录下的元素
    let items: Array<BookItem> | undefined = undefined
    let errors: ResourceStr | undefined = this.emptyOrErrorResource
    if (force || this.info?.items === undefined) {
      this.isRefreshing = true
      try {
        items = await this.mediaData.loadData(this.info!.item)
      } catch (error) {
        errors = "Error: " + (error as Error).message
      }
      this.isRefreshing = false
    } else {
      items = this.info.items
    }
    if (items && items.length > 0) {
      this.info!.items = items
      this.mediaDataSource.pushArrayData(items)
    } else {
      this.mediaDataSource.clear()
      this.errorOrEmptyContent = errors
    }
  }

  private sortData(): void {
    let items = this.info?.items
    if (!items || items.length <= 0) return
    this.mediaData.sortData(items)
    this.mediaDataSource.pushArrayData(items)
  }

  aboutToAppear(): void {
    this.getUIContext().getHostContext()?.eventHub
      .on(AppEvent.EVENT_MEDIA_INFO_HISTORY_CHANGED, this.mediaHistoryChangeCallback)
    this.getUIContext().getHostContext()?.eventHub
      .on(AppEvent.EVENT_SORT_CHANGED, this.mediaSortCallback)
    this.isRefreshing = true
  }

  build() {
    Stack() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Grid() {
          LazyForEach(this.mediaDataSource, (item: BookItem) => {
            GridItem() {
              BookItemView({mediaItem: item,
                callback: this.mediaItemCallback,
                menuCallback: this.mediaMenuCallback})
            }
          }, (item: BookItem) => item.key)
        }
        .padding({
          left: CommonConstants.SPACE_16,
          right: CommonConstants.SPACE_16,
          bottom: this.currentWidthBreakpoint >= WidthBreakpoint.WIDTH_MD ?
            px2vp(this.currentAvoidArea?.bottomRect.height) :
            0
        })
        .rowsGap(CommonConstants.SPACE_12)
        .columnsGap(CommonConstants.SPACE_12)
        .columnsTemplate("repeat(auto-fit, 100)")
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
      .refreshOffset(64)
      .pullToRefresh(true)
      .height(CommonConstants.FULL_PERCENT)
      .width(CommonConstants.FULL_PERCENT)
      .onRefreshing(() => {
        this.updateData(true)
      })

      // error empty
      Text(this.errorOrEmptyContent)
        .textAlign(TextAlign.Center)
        .visibility(this.errorOrEmptyContent ? Visibility.Visible : Visibility.Hidden)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontColor($r('sys.color.font_secondary'))
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

  private async removeData(item: BookItem): Promise<void> {
    let name = item.alias || item.name
    if (typeof name !== "string") {
      name = this.getUIContext().getHostContext()!.resourceManager.getStringSync(name.id)
    }
    let response = await this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.dialog_delete_title'),
      message: $r('app.string.dialog_delete_msg', name),
      buttons: [
        {
          text: $r("app.string.dialog_delete_cancel"),
          color: $r("sys.color.ohos_id_color_text_secondary")
        },
        {
          text: $r("app.string.dialog_delete_confirm"),
          color: $r("sys.color.brand")
        }
      ]})
    if (response.index <= 0) return
    let progressDialog = new ProgressDialog(this.getUIContext())
    try {
      await progressDialog.show()
      await this.mediaData.removeData(item)
      let index = this.mediaDataSource.dataArray.findIndex((value) => value.id === item.id)
      if (index >= 0) {
        this.mediaDataSource.deleteData(index)
      }
      this.getUIContext().getPromptAction().showToast({message: $r('app.string.file_delete_success', name)})
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({message: e['message']})
    }
    await progressDialog.dismiss(true)
  }

  aboutToDisappear(): void {
    this.getUIContext().getHostContext()?.eventHub
      .off(AppEvent.EVENT_MEDIA_INFO_HISTORY_CHANGED, this.mediaHistoryChangeCallback)
    this.getUIContext().getHostContext()?.eventHub
      .off(AppEvent.EVENT_SORT_CHANGED, this.mediaSortCallback)
  }

}

@Reusable
@Component
export struct BookItemView {

  @StorageLink(AppThumb.THUMB) thumb?: AppThumb = undefined

  @Require callback?: Callback<BookItem>

  @Require menuCallback?: Callback<Pair<MenuType, BookItem>>

  @Require @State mediaItem?: BookItem = undefined

  @State finished: boolean = false

  private mediaImageKey?: string

  @State mediaImage?: string = undefined

  private menuOptions?: ContextMenuOptions

  @Builder
  menuBuilder() {
    // https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-popup-and-menu-components-menu
    Menu() {
      MenuItem({
        startIcon: $r('sys.media.ohos_ic_public_remove_filled'),
        content: $r('app.string.menu_delete')
      })
        .onClick(() => {
          this.menuCallback?.({first: MenuType.DELETE, second: this.mediaItem!})
        })
    }
  }

  aboutToAppear(): void {
    this.menuOptions = {}
    if (deviceInfo.sdkApiVersion >= 20) {
      this.menuOptions.modalMode = ModalMode.TARGET_WINDOW
    }
    this.updateState()
  }

  aboutToReuse(params: Record<string, object>): void {
    this.mediaItem = params['mediaItem'] as BookItem
    this.updateState()
  }

  private addThumbWatch(item: BookItem) {
    this.clearThumbWatch()
    this.mediaImageKey = this.thumb?.load(item.uri, (path) => {
      this.mediaImage = path
      if (this.mediaItem) {
        this.mediaItem.thumb = path
      }
    })
  }

  private clearThumbWatch() {
    if (this.mediaImageKey) {
      this.thumb?.cancel(this.mediaImageKey)
    }
    this.mediaImage = undefined
    this.mediaImageKey = undefined
  }

  private updateState() {
    this.finished = (this.mediaItem?.history && (this.mediaItem.history.page >= this.mediaItem.history.pages)) ? true : false;
    if (!this.mediaItem?.dir) {
      // 给缩略图赋值
      this.mediaImage = this.mediaItem?.thumb
      // 缩略图不存在，则加载缩略图并观察结果
      if (!this.mediaImage && this.mediaItem) {
        this.addThumbWatch(this.mediaItem)
      }
    }
  }

  build() {
    Column({space: CommonConstants.SPACE_8}) {

      RelativeContainer() {

        if (this.mediaImage) {
          Image(fileUri.getUriFromPath(this.mediaImage))
            .objectFit(ImageFit.Cover)
            .width(CommonConstants.FULL_PERCENT)
            .height(CommonConstants.FULL_PERCENT)
        } else {
          SymbolGlyph(this.mediaItem?.dir ? $r('sys.symbol.folder_fill') : $r('sys.symbol.book_open_fill'))
            .fontSize(48)
            .fontColor([this.mediaItem?.dir ? $r('app.color.folder_color') : $r('sys.color.ohos_id_color_activated')])
            .alignRules({
              middle: {
                anchor: "__container__",
                align: HorizontalAlign.Center
              },
              center: {
                anchor: "__container__",
                align: VerticalAlign.Center
              }
            })
        }

        // new
        Text("New")
          .fontColor($r('sys.color.white'))
          .fontSize(12)
          .visibility(this.mediaItem?.dir || this.mediaItem?.history ? Visibility.Hidden : Visibility.Visible)
          .padding(CommonConstants.SPACE_4)
          .backgroundColor($r('sys.color.ohos_id_color_badge_red'))
          .alignRules({
            start: {
              anchor: "__container__",
              align: HorizontalAlign.Start
            },
            top: {
              anchor: "__container__",
              align: VerticalAlign.Top
            }
          })
      }
      .clip(true)
      .backgroundColor($r('app.color.placeholder_background'))
      .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
      .width(CommonConstants.FULL_PERCENT)
      .aspectRatio(0.67)

      Column() {
        Text(this.mediaItem?.alias || this.mediaItem?.name)
          .maxLines(1)
          .ellipsisMode(EllipsisMode.END)
          .wordBreak(WordBreak.BREAK_ALL)
          .textOverflow({overflow: TextOverflow.Ellipsis})
          .width(CommonConstants.FULL_PERCENT)
          .fontSize($r('sys.float.Subtitle_M'))

        Text(this.mediaItem?.dir || !this.mediaItem?.size
          ? this.mediaItem?.date
          : this.mediaItem?.size + " / " + this.mediaItem?.date)
          .maxLines(1)
          .ellipsisMode(EllipsisMode.END)
          .textOverflow({overflow: TextOverflow.Ellipsis})
          .wordBreak(WordBreak.BREAK_ALL)
          .width(CommonConstants.FULL_PERCENT)
          .fontSize($r('sys.float.Subtitle_S'))
      }
      .justifyContent(FlexAlign.SpaceAround)
      .height(48)
    }
    .width(CommonConstants.FULL_PERCENT)
    .bindContextMenu(this.menuBuilder, ResponseType.RightClick, this.menuOptions)
    .bindContextMenu(this.menuBuilder, ResponseType.LongPress, this.menuOptions)
    .onClick(() => {
      this.callback?.(this.mediaItem)
    })
  }

  aboutToRecycle(): void {
    this.clearThumbWatch()
  }

  aboutToDisappear(): void {
    this.clearThumbWatch()
  }

}