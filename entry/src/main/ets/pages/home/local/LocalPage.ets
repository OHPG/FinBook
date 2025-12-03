import { AppThumb } from "../../../thumb/AppThumb"
import { CommonConstants } from "../../../common/CommonConstants"
import { BookItem } from "../../../entity/BookItem"
import { AppRouter } from "../../../router/AppRouter"
import { HomeToolBar } from "../../../widget/bar/HomeToolBar"
import { HomeControl } from "../HomeControl"
import { deviceInfo } from "@kit.BasicServicesKit"

@Component
export struct LocalPage {

  @StorageLink("currentHomeControl") homeControl?: HomeControl = undefined

  aboutToAppear(): void {
    // this.homeControl!.callback = () => {
    //
    // }
  }

  build() {
    Column() {
      HomeToolBar({
        title: $r('app.string.tab_local'),
        searchEnable: true,
        searchCallback: (args) => {
          AppRouter.goToLocalSearch(this.getUIContext(), args)
        }
      })

    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

  aboutToDisappear(): void {
    this.homeControl!.callback = undefined
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
    }, item.header)
  }

  private clearThumbWatch() {
    if (this.mediaImageKey) {
      this.thumb?.cancel(this.mediaImageKey)
    }
    this.mediaImage = undefined
    this.mediaImageKey = undefined
  }

  private updateState() {
    this.finished = (this.mediaItem?.history && (this.mediaItem.history.duration - this.mediaItem.history.position < 5000)) ? true : false;
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
    Row({space: CommonConstants.SPACE_8}) {

      RelativeContainer() {

        if (this.mediaImage) {
          Image(fileUri.getUriFromPath(this.mediaImage))
            .objectFit(ImageFit.Cover)
            .width(CommonConstants.FULL_PERCENT)
            .height(CommonConstants.FULL_PERCENT)
        } else {
          SymbolGlyph(this.mediaItem?.dir ? $r('sys.symbol.folder_fill') : $r('sys.symbol.template_fill'))
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
        }

        // 角标背景
        Shape() {
          Path({width: 38, height: 38, commands: 'M0 0 L100 0 L100 100 Z'})
        }
        .width(38)
        .height(38)
        .visibility(this.finished ? Visibility.Visible : Visibility.Hidden)
        .viewPort({ x: 0, y: 0, width: "100px", height: "100px" })
        // .stroke($r('sys.color.ohos_id_color_activated'))
        .strokeWidth(0)
        .fill($r('sys.color.ohos_id_color_activated'))
        .alignRules({
          end: {
            anchor: "__container__",
            align: HorizontalAlign.End
          },
          top: {
            anchor: "__container__",
            align: VerticalAlign.Top
          }
        })

        // 完成标签
        SymbolGlyph($r('sys.symbol.checkmark'))
        // .fontSize(16)
          .width(19)
          .height(19)
          .visibility(this.finished ? Visibility.Visible : Visibility.Hidden)
          .fontColor([$r('sys.color.white')])
          .alignRules({
            end: {
              anchor: "__container__",
              align: HorizontalAlign.End
            },
            top: {
              anchor: "__container__",
              align: VerticalAlign.Top
            }
          })

        // 进度
        Progress({ value: this.mediaItem?.history?.position, total: this.mediaItem?.history?.duration, type: ProgressType.Linear })
          .visibility(this.mediaItem?.history && !this.finished ? Visibility.Visible : Visibility.Hidden)
          .alignRules({
            start: {
              anchor: "__container__",
              align: HorizontalAlign.Start
            },
            end: {
              anchor: "__container__",
              align: HorizontalAlign.End
            },
            bottom: {
              anchor: "__container__",
              align: VerticalAlign.Bottom
            }
          })

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
      .aspectRatio(16/9.0)
      .height(68)

      Column() {
        Text(this.mediaItem?.alias || this.mediaItem?.name)
          .maxLines(2)
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
      .height(68)
      .layoutWeight(1)
    }
    .padding({
      left: CommonConstants.SPACE_16
    , right: CommonConstants.SPACE_16})
    .width(CommonConstants.FULL_PERCENT)
    .height(78)
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