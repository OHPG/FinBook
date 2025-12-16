import { AppThumb } from "../../../thumb/AppThumb"
import { CommonConstants } from "../../../common/CommonConstants"
import { BookItem } from "../../../entity/BookItem"
import { AppRouter } from "../../../router/AppRouter"
import { HomeToolBar } from "../../../widget/bar/HomeToolBar"
import { HomeControl } from "../HomeControl"
import { deviceInfo } from "@kit.BasicServicesKit"
import { MenuType } from '../../../enum/MenuType'
import { Pair } from "../../../comp/Pair"
import { fileUri } from "@kit.CoreFileKit"
import { FolderItem } from "../../../entity/FolderItem"
import LazyDataSource from "../../../common/LazyDataSource"
import { window } from "@kit.ArkUI"
import { LocalViewModel } from "./LocalViewModel"
import { ProgressDialog } from "@ohpg/fin-framework"
import { MediaArgs } from "../../detail/MediaArgs"
import { BreakpointSystem } from "@ohpg/fin-core"
import { AppEvent } from "../../../event/AppEvent"
import { util } from "@kit.ArkTS"
import { BookHistory } from "../../../entity/BookHistory"

@Component
export struct LocalPage {

  @StorageLink("currentHomeControl") homeControl?: HomeControl = undefined

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT) currentWidthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM

  private readonly mediaData: LocalViewModel = new LocalViewModel(this.getUIContext().getHostContext()!)

  @StorageProp('currentAvoidArea') avoidArea?: window.AvoidArea = undefined

  @State isRefreshing: boolean = false

  @State errorOrEmptyContent: ResourceStr | undefined = undefined

  private folderDataSource = new LazyDataSource<FolderItem>()

  private currentFolder: FolderItem = {
    name: "根目录",
    path: ""
  }

  private mediaDataSource = new LazyDataSource<BookItem>()

  private readonly folderItemCallback: Callback<FolderItem> = (item) => {
    this.backwardFolder(item)
  }

  private readonly mediaItemCallback: Callback<BookItem> = (item) => {
    if (item.dir) {
      this.forwardFolder(item)
    } else {
      this.play(item)
    }
  }

  private readonly mediaMenuCallback: Callback<Pair<MenuType, BookItem>> = (item) => {
    if (item.first === MenuType.DELETE) {
      this.removeData(item.second)
    }
  }

  aboutToAppear(): void {
    this.homeControl!.callback = (): boolean => {
      if (this.folderDataSource.totalCount() > 1) {
        let lastIndex = this.folderDataSource.totalCount() - 1
        this.folderDataSource.deleteData(lastIndex)
        this.currentFolder = this.folderDataSource.getData(lastIndex - 1)
        this.updateData()
        return true
      }
      return false
    }
    this.getUIContext().getHostContext()?.eventHub
      .on(AppEvent.EVENT_MEDIA_INFO_HISTORY_CHANGED, (history: BookHistory) => {
        let index = this.mediaDataSource.getDataList().findIndex((item) => item.id === history.id)
        if (index <0 ) {
          return
        }
        let mediaItem = this.mediaDataSource.getData(index)
        mediaItem.history = history
        mediaItem.key = util.generateRandomUUID(true)
        this.mediaDataSource.notifyDataChange(index)
      })
    this.folderDataSource.pushData(this.currentFolder)
    this.isRefreshing = true
  }

  private backwardFolder(item: FolderItem) {
    if (this.currentFolder === item) {
      return
    }
    let dataList = this.folderDataSource.getDataList()
    let index = dataList.indexOf(item)
    if (index < 0) {
      return
    }
    for (let i = dataList.length - 1; i > index; i--) {
      this.folderDataSource.deleteData(i)
    }
    this.currentFolder = item
    this.updateData()
  }

  private forwardFolder(item: BookItem) {
    if (!this.currentFolder) {
      return
    }
    let newFolder: FolderItem = {
      name: item.name,
      alias: item.alias,
      path: this.currentFolder.path + "/" + item.name,
    }
    this.folderDataSource.pushData(newFolder)
    this.currentFolder = newFolder
    this.isRefreshing = true
  }

  private async updateData(force?: boolean): Promise<void> {
    this.errorOrEmptyContent = undefined
    // 更新当前目录下的元素
    let items: Array<BookItem> | undefined = undefined
    let errors: ResourceStr | undefined
    if (force || this.currentFolder.items === undefined) {
      this.isRefreshing = true
      try {
        items = await this.mediaData.loadByPath(this.currentFolder.path)
      } catch (error) {
        errors = "Error: " + (error as Error).message
      }
      this.isRefreshing = false
    } else {
      items = this.currentFolder.items
    }
    if (items && items.length > 0) {
      this.currentFolder!.items = items
      this.mediaDataSource.pushArrayData(items)
    } else {
      this.mediaDataSource.clear()
      if (errors) {
        this.errorOrEmptyContent = errors
      } else {
        if (this.currentFolder.path.length <= 0) {
          this.errorOrEmptyContent = $r('app.string.global_content_empty')
        } else {
          this.errorOrEmptyContent = $r('app.string.global_content_empty_simple')
        }
      }
    }
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
      await this.mediaData.removeData(item.uri, item.dir)
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


  build() {
    Column() {
      HomeToolBar({
        title: $r('app.string.tab_local'),
        // searchEnable: false,
        // searchCallback: (args) => {
        //   AppRouter.goToLocalSearch(this.getUIContext(), args)
        // }
      })
      Column() {

        // 目录结构
        List() {
          LazyForEach(this.folderDataSource, (item: FolderItem) => {
            ListItem() {
              FolderItemView({folderItem: item, callback: this.folderItemCallback})
            }
          })
        }
        .padding({
          left: CommonConstants.SPACE_16,
          right: CommonConstants.SPACE_16
        })
        .scrollBar(BarState.Off)
        .listDirection(Axis.Horizontal)
        .width(CommonConstants.FULL_PERCENT)
        .height(24)

        // 媒体列表
        Stack() {
          Refresh({ refreshing: $$this.isRefreshing }) {
            Grid() {
              LazyForEach(this.mediaDataSource, (item: BookItem) => {
                GridItem() {
                  BookItemView({mediaItem: item,
                    callback: this.mediaItemCallback,
                    menuCallback: this.mediaMenuCallback})
                }
                // .swipeAction({
                //   end: actionMenuMediaItem.bind(this, item, this.mediaMenuCallback)
                // })
              }, (item: BookItem) => item.key)
            }
            .padding({
              left: CommonConstants.SPACE_16,
              right: CommonConstants.SPACE_16,
              bottom: this.currentWidthBreakpoint >= WidthBreakpoint.WIDTH_MD ?
                px2vp(this.avoidArea?.bottomRect.height) :
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
        .layoutWeight(1)
      }
        .width(CommonConstants.FULL_PERCENT)
        .layoutWeight(1)
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

  play(item: BookItem) {
    // 开始播放
    let playerArgs: MediaArgs = {
      id: item.id,
      name: item.name,
      uri: item.uri
    }
    AppRouter.goToLocalReader(this.getUIContext(), playerArgs)
  }

  aboutToDisappear(): void {
    this.homeControl!.callback = undefined
    this.mediaData?.release()
    this.getUIContext().getHostContext()?.eventHub
      .off(AppEvent.EVENT_MEDIA_INFO_HISTORY_CHANGED)
  }

}


@Reusable
@Component
struct FolderItemView {

  @Require callback?: Callback<FolderItem>

  @Require @State folderItem?: FolderItem = undefined

  aboutToAppear(): void {

  }

  aboutToReuse(params: Record<string, object>): void {
    this.folderItem = params['folderItem'] as FolderItem
  }

  build() {
    Row() {
      Text((this.folderItem?.alias || this.folderItem?.name))
        .height(14)
      Text(" > ")
        .height(14)
    }
    .onClick(() => {
      this.callback?.(this.folderItem)
    })
  }

  aboutToRecycle(): void {

  }

  aboutToDisappear(): void {

  }

}

@Reusable
@Component
struct BookItemView {

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
            .fontColor([$r('sys.color.ohos_id_color_activated')])
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
      .backgroundColor($r('sys.color.background_secondary'))
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

        Text(this.mediaItem?.dir
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