import { Pair } from "../../../comp/Pair"
import { CommonConstants } from "../../../common/CommonConstants"
import { StorageItem } from "../../../entity/StorageItem"
import { AppRouter } from "../../../router/AppRouter"
import { AppDataStore } from "../../../store/AppDataStore"
import { HomeToolBar } from "../../../widget/bar/HomeToolBar"
import { NormalView } from "../com/NormalView"
import { StorageViewModel } from "./StorageViewModel"
import { MenuType } from "../../../enum/MenuType"
import LazyDataSource from "../../../common/LazyDataSource"

@Component
export struct StoragePage {

  private readonly dataStore: AppDataStore = AppStorage.get(AppDataStore.APP_DATA_STORE)!

  private storageData = new StorageData(this.getUIContext().getHostContext()!)

  @StorageProp('currentAvoidArea') avoidArea?: window.AvoidArea = undefined

  @State isRefreshing: boolean = false

  @State storageMenu: boolean = false

  @State errorOrEmptyContent: ResourceStr | undefined = undefined

  private storageDataSource = new LazyDataSource<StorageItem>()

  private menuCallback: Callback<Pair<MenuType, StorageItem>> = (pair) => {
    if (pair.first === MenuType.EDIT) {
      this.editStorage(pair.second.info)
    } else if (pair.first === MenuType.DELETE) {
      this.deleteStorage(pair.second.info)
    }
  }

  aboutToAppear(): void {
    this.getUIContext().getHostContext()?.eventHub.on(AppEvent.EVENT_STORAGE_CHANGED, () => {
      this.updateData(true)
    })
    this.updateData(true)
  }

  private async updateData(force?: boolean) {
    let errors: ResourceStr | undefined = $r('app.string.global_content_empty')
    if (force) {
      this.errorOrEmptyContent = undefined
      let items: Array<StorageItem> | undefined = undefined
      this.isRefreshing = true
      try {
        items = await this.storageData.loadStorage()
      } catch (error) {
        errors = (error as Error).message
      }
      this.isRefreshing = false
      if (items && items.length > 0) {
        this.storageDataSource.pushArrayData(items)
      } else {
        this.storageDataSource.clear()
        this.errorOrEmptyContent = errors
      }
    } else {
      if (this.storageDataSource.totalCount() > 0) {
        this.errorOrEmptyContent = undefined
      } else {
        this.errorOrEmptyContent = errors
      }
    }
  }

  @Builder
  bindStorageMenu() {
    Menu() {
      // MenuItem({ content: $r('app.string.storage_smb')})
      //   .selectIcon(true)
      //   .onClick(() => {
      //     let smbDialog = new SmbDialog(this.getUIContext())
      //     smbDialog.show()
      //   })

      MenuItem({ content: $r('app.string.storage_dav') })
        .selectIcon(true)
        .onClick(() => {
          let davDialog = new DavDialog(this.getUIContext())
          davDialog.show()
        })
    }
  }

  build() {

    Column() {
      ToolBar({
        title: $r('app.string.storage')
      }) {
        SymbolGlyph($r('sys.symbol.plus_circle_fill'))
          .fontSize($r('sys.float.Title_M'))
          .fontColor([$r('sys.color.font_primary')])
          .bindContextMenu(this.storageMenu, this.bindStorageMenu, {
            aboutToDisappear: () => {
              this.storageMenu = false
            }
          })
          .onClick(() => {
            this.storageMenu = true
          })
      }

      Stack() {
        Refresh({ refreshing: $$this.isRefreshing }) {
          List() {
            LazyForEach(this.storageDataSource, (item: StorageItem) => {
              ListItem() {
                StorageItemView({storageItem: item, menuCallback: this.menuCallback})
              }
              .swipeAction({
                end: actionMenuMediaItem.bind(this, item, this.menuCallback)
              })
            }, (item: StorageItem) => item.key)
          }
          .divider({
            strokeWidth: 1,
            color: $r('sys.color.comp_divider')
          })
          .contentEndOffset(px2vp(this.avoidArea?.bottomRect.height))
          .width('100%')
          .height('100%')
          .alignListItem(ListItemAlign.Center)
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

  }

  editStorage(info: StorageInfo) {
    let dialog: Dialog
    if (info.type === ProtocolType.SMB) {
      let smbDialog = new SmbDialog(this.getUIContext())
      smbDialog.setStorageInfo(info)
      smbDialog.show()
    } else if (info.type === ProtocolType.DAV) {
      let davDialog = new DavDialog(this.getUIContext())
      davDialog.setStorageInfo(info)
      davDialog.show()
    } else {
      // Ignore
    }
  }

  deleteStorage(info: StorageInfo) {
    this.dataStore.deleteStorageInfo(info.id)
      .then((result) => {
        if (result) {
          this.getUIContext().getPromptAction().showToast({message: $r('app.string.global_delete_success')})
          let index = this.storageDataSource.getDataList().findIndex((value) => value.info.id === info.id)
          if (index >= 0) {
            this.storageDataSource.deleteData(index)
          }
          this.updateData()
        } else {
          this.getUIContext().getPromptAction().showToast({message: $r('app.string.global_delete_fail')})
        }
      })
      .catch((error: Error) => {
        this.getUIContext().getPromptAction().showToast({message: error.message})
      })
  }

  aboutToDisappear(): void {
    this.getUIContext().getHostContext()?.eventHub.off(AppEvent.EVENT_STORAGE_CHANGED)
  }

}


@Reusable
@Component
struct StorageItemView {

  @Require @State storageItem?: StorageItem = undefined

  menuCallback?: Callback<Pair<MenuType, StorageItem>>

  @Builder
  menuBuilder() {
    // https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-popup-and-menu-components-menu
    Menu() {
      MenuItem({
        startIcon: $r('sys.media.ohos_ic_public_edit'),
        content: $r('app.string.menu_edit')
      })
        .onClick(() => {
          this.menuCallback?.({first: MenuType.EDIT, second: this.storageItem!})
        })
      MenuItem({
        startIcon: $r('sys.media.ohos_ic_public_remove_filled'),
        content: $r('app.string.menu_delete')
      })
        .onClick(() => {
          this.menuCallback?.({first: MenuType.DELETE, second: this.storageItem!})
        })
    }
  }

  aboutToAppear(): void {
  }

  aboutToReuse(params: Record<string, object>): void {
    this.storageItem = params['storageItem'] as StorageItem
  }

  build() {
    Row({space: CommonConstants.SPACE_8}) {

      RelativeContainer() {

        SymbolGlyph($r('sys.symbol.cloud_fill'))
          .fontSize(36)
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

        // new
        Text(this.storageItem?.info.type)
          .fontColor($r('sys.color.white'))
          .fontSize(12)
          .padding({left: CommonConstants.SPACE_4, right: CommonConstants.SPACE_4})
          .backgroundColor($r('sys.color.ohos_id_color_activated'))
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
      .width(68)
      .height(68)

      Column() {
        Text(this.storageItem?.info.name)
          .maxLines(2)
          .ellipsisMode(EllipsisMode.END)
          .wordBreak(WordBreak.BREAK_ALL)
          .textOverflow({overflow: TextOverflow.Ellipsis})
          .width(CommonConstants.FULL_PERCENT)
          .fontSize($r('sys.float.Subtitle_M'))

        Text(this.storageItem?.info.url)
          .maxLines(1)
          .ellipsisMode(EllipsisMode.END)
          .wordBreak(WordBreak.BREAK_ALL)
          .textOverflow({overflow: TextOverflow.Ellipsis})
          .width(CommonConstants.FULL_PERCENT)
          .fontSize($r('sys.float.Subtitle_S'))
      }
      .justifyContent(FlexAlign.SpaceAround)
      .height(68)
      .layoutWeight(1)
    }
    .bindContextMenu(this.menuBuilder, ResponseType.LongPress)
    .bindContextMenu(this.menuBuilder, ResponseType.RightClick)
    .padding({
      left: CommonConstants.SPACE_16
    , right: CommonConstants.SPACE_16})
    .width(CommonConstants.FULL_PERCENT)
    .height(78)
    .onClick(() => {
      AppRouter.goToStorageDetail(this.getUIContext(), this.storageItem!.info)
    })
  }

  aboutToRecycle(): void {

  }

  aboutToDisappear(): void {

  }

}