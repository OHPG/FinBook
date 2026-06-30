import { BreakpointSystem, FinItem, FinItemType, FinPersonType } from "@ohpg/fin-core"
import { CommonConstants } from "../../common/CommonConstants"
import { DetailViewModel } from "./DetailViewModel"
import { MediaArgs } from "./MediaArgs"
import { AppRouter } from "../../router/AppRouter"
import { CoverImage } from "../../widget/cover/CoverImage"

/**
 * 操作按钮组件：收藏 + 阅读 + 下载进度
 */
@Component
export struct DetailOperate {

  @LocalStorageLink("viewModel") viewModel?: DetailViewModel = undefined

  @Require @Prop item?: FinItem = undefined

  @State downloadingState: boolean = false
  @State downloadProgress: number = 0
  @State downloadSizeText: string = ''
  @State downloadSpeedText: string = ''

  private pollTimer?: number = undefined

  aboutToAppear(): void {
    this.pollTimer = setInterval(() => {
      if (this.viewModel?.downloadState) {
        const state = this.viewModel.downloadState
        this.downloadingState = state.downloading
        this.downloadProgress = state.progress >= 0 ? state.progress * 100 : 0
        this.downloadSizeText = state.sizeText
        this.downloadSpeedText = state.speedText
      }
    }, 100)
  }

  aboutToDisappear(): void {
    if (this.pollTimer) {
      clearInterval(this.pollTimer)
      this.pollTimer = undefined
    }
  }

  build() {
    Column({ space: 12 }) {
      // 按钮行：收藏 + 阅读
      Row({ space: 12 }) {
        // 收藏按钮
        Button({ type: ButtonType.Capsule }) {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.star'))
              .fontColor([$r('sys.color.font_primary')])
              .fontSize(16)
            Text('收藏')
              .fontColor($r('sys.color.font_primary'))
              .fontSize($r('sys.float.Body_M'))
          }
          .justifyContent(FlexAlign.Center)
        }
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .height(36)
        .layoutWeight(1)
        .onClick(() => {
          this.viewModel?.favouriteOrNot(this.item?.data?.isFavorite)
        })

        // 阅读按钮
        Button({ type: ButtonType.Capsule }) {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.book_pages_fill_1'))
              .fontColor([$r('sys.color.font_on_primary')])
              .fontSize(16)
            Text(this.downloadingState ? '下载中' : '阅读')
              .fontColor($r('sys.color.font_on_primary'))
              .fontSize($r('sys.float.Body_M'))
          }
          .justifyContent(FlexAlign.Center)
        }
        .height(36)
        .layoutWeight(1)
        .enabled(!this.downloadingState)
        .onClick(() => this.playOrNot())
      }
      .width('100%')

      // 下载进度（在按钮下方显示）
      if (this.downloadingState) {
        Column({ space: 6 }) {
          Progress({
            value: this.downloadProgress,
            total: 100,
            type: ProgressType.Linear
          })
            .width('100%')
            .height(4)
            .color($r('sys.color.ohos_id_color_emphasize'))

          Row() {
            Text(Math.floor(this.downloadProgress) + '%')
              .fontSize($r('sys.float.Body_S'))
              .fontColor($r('sys.color.font_secondary'))

            Blank()

            Text(this.getDownloadInfo())
              .fontSize($r('sys.float.Body_S'))
              .fontColor($r('sys.color.font_secondary'))
          }
          .width('100%')
        }
      }
    }
    .width('100%')
  }

  private getDownloadInfo(): string {
    const parts: string[] = []
    if (this.downloadSizeText) {
      parts.push(this.downloadSizeText)
    }
    if (this.downloadSpeedText) {
      parts.push(this.downloadSpeedText)
    }
    return parts.join('  ·  ')
  }

  private playOrNot() {
    const item = this.item
    if (!item) return

    const args: MediaArgs = { id: item.id, name: item.name }

    this.viewModel?.getCachedFilePath(item)
      .then((cachedPath) => {
        if (cachedPath) {
          AppRouter.goToOnlineReader(this.getUIContext(), args)
        } else {
          this.viewModel?.downloadBook(item)
            .then(() => {
              AppRouter.goToOnlineReader(this.getUIContext(), args)
            })
            .catch((error: Error) => {
              console.error('FinBook download failed: ' + error.message)
            })
        }
      })
      .catch((error: Error) => {
        console.error('FinBook check cache failed: ' + error.message)
      })
  }
}

/**
 * 元数据信息行（标签 + 值，左右布局）
 */
@Component
struct MetadataRow {
  @Prop label: string = ''
  @Prop value: string = ''

  build() {
    Row({ space: 12 }) {
      Text(this.label)
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_secondary'))
        .width(60)
      Text(this.value)
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_primary'))
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }
}

/**
 * 详情页头部（封面 + 标题 + 元数据网格布局）
 */
@Component
export struct DetailHeader {

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT)
  currentWidthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM

  @Prop item: FinItem

  build() {
    Column() {
      // 仅大屏横屏（WIDTH_LG）走左右两栏，其他都线性布局
      if (this.currentWidthBreakpoint >= WidthBreakpoint.WIDTH_LG) {
        this.buildLargeScreenLayout()
      } else {
        this.buildSmallScreenLayout()
      }
    }
    .width('100%')
  }

  /**
   * 线性布局（手机 + pad 竖屏）：顶部（封面左 + 元数据右）→ 操作按钮 → 简介 → 文件信息
   */
  @Builder
  buildSmallScreenLayout() {
    Column({ space: 16 }) {
      // 顶部区域：封面 + 元数据
      Row({ space: 16 }) {
        // 左侧封面（pad 上稍大）
        CoverImage({ image: this.item?.image, imageBorderRadius: 8 })
          .width(this.currentWidthBreakpoint >= WidthBreakpoint.WIDTH_MD ? 150 : 120)
          .aspectRatio(CommonConstants.ITEM_RATIO)
          .shadow({ radius: 12, color: 'rgba(0, 0, 0, 0.15)', offsetY: 4 })

        // 右侧：核心元数据
        Column({ space: 8 }) {
          // 评分
          if (this.item.communityRating) {
            Row({ space: 4 }) {
              SymbolGlyph($r('sys.symbol.star_fill'))
                .fontSize(12)
                .fontColor([Color.Orange])
              Text(this.item.communityRating)
                .fontSize($r('sys.float.Body_S'))
                .fontColor($r('sys.color.font_primary'))
            }
          }

          // 核心元数据（紧凑展示）
          this.buildMetadataGrid()
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      // 操作按钮
      if (this.item.type === FinItemType.Book) {
        DetailOperate({ item: this.item })
      }

      // 简介
      this.buildOverview()

      // 文件信息
      this.buildFileInfo()
    }
    .padding(16)
    .width('100%')
  }

  /**
   * 大屏布局：左栏（封面+元数据+按钮） | 右栏（简介+文件信息）
   */
  @Builder
  buildLargeScreenLayout() {
    Row({ space: 0 }) {
      // 左栏：封面 + 标题 + 元数据 + 操作按钮
      Column({ space: 16 }) {
        // 封面 + 标题/元数据
        Row({ space: 20 }) {
          CoverImage({ image: this.item?.image, imageBorderRadius: 8 })
            .width(160)
            .aspectRatio(CommonConstants.ITEM_RATIO)
            .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.15)', offsetY: 4 })

          Column({ space: 8 }) {
            if (this.item.communityRating) {
              Row({ space: 4 }) {
                SymbolGlyph($r('sys.symbol.star_fill'))
                  .fontSize(12)
                  .fontColor([Color.Orange])
                Text(this.item.communityRating)
                  .fontSize($r('sys.float.Body_S'))
                  .fontColor($r('sys.color.font_primary'))
              }
            }

            this.buildMetadataGrid()
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        // 操作按钮
        if (this.item.type === FinItemType.Book) {
          DetailOperate({ item: this.item })
        }
      }
      .width('40%')
      .padding(20)
      .alignItems(HorizontalAlign.Start)

      // 右栏：简介 + 文件信息
      Scroll() {
        Column({ space: 16 }) {
          this.buildOverview()
          this.buildFileInfo()
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .layoutWeight(1)
      .padding(20)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  /**
   * 元数据列表（行式布局：标签 | 值）
   */
  @Builder
  buildMetadataGrid() {
    Column({ space: 8 }) {
      if (this.getPersonsByType(FinPersonType.Author)) {
        MetadataRow({ label: '作者', value: this.getPersonsByType(FinPersonType.Author) })
      }
      if (this.item.seriesName) {
        MetadataRow({ label: '系列', value: this.item.seriesName })
      }
      if (this.item.index !== undefined && this.item.index !== null) {
        MetadataRow({ label: '卷号', value: 'Vol.' + this.item.index.toString() })
      }
      if (this.item.productionYear) {
        MetadataRow({ label: '年份', value: this.item.productionYear })
      }
      if (this.item.genres && this.item.genres.length > 0) {
        MetadataRow({ label: '类型', value: this.item.genres.join(', ') })
      }
      if (this.getFileSuffix(this.item.path ?? '')) {
        MetadataRow({ label: '格式', value: this.getFileSuffix(this.item.path ?? '').toUpperCase() })
      }
      if (this.getPersonsByType(FinPersonType.Illustrator)) {
        MetadataRow({ label: '插画', value: this.getPersonsByType(FinPersonType.Illustrator) })
      }
      if (this.getPersonsByType(FinPersonType.Translator)) {
        MetadataRow({ label: '译者', value: this.getPersonsByType(FinPersonType.Translator) })
      }
      if (this.getPersonsByType(FinPersonType.Penciller)) {
        MetadataRow({ label: '线稿', value: this.getPersonsByType(FinPersonType.Penciller) })
      }
      if (this.getPersonsByType(FinPersonType.Colorist)) {
        MetadataRow({ label: '上色', value: this.getPersonsByType(FinPersonType.Colorist) })
      }
      if (this.getPersonsByType(FinPersonType.Letterer)) {
        MetadataRow({ label: '嵌字', value: this.getPersonsByType(FinPersonType.Letterer) })
      }
      if (this.getPersonsByType(FinPersonType.Editor)) {
        MetadataRow({ label: '编辑', value: this.getPersonsByType(FinPersonType.Editor) })
      }
    }
    .width('100%')
  }

  /**
   * 简介区域
   */
  @Builder
  buildOverview() {
    if (this.item.overview) {
      Column({ space: 8 }) {
        Text('简介')
          .fontSize($r('sys.float.Body_L'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        Text(this.item.overview)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_secondary'))
          .lineHeight(24)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
  }

  /**
   * 文件信息卡片
   */
  @Builder
  buildFileInfo() {
    if (this.item.path) {
      Column({ space: 8 }) {
        Divider()
          .color($r('sys.color.comp_divider'))
          .margin({ top: 8, bottom: 4 })

        Text('文件信息')
          .fontSize($r('sys.float.Body_L'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        // 文件名卡片
        Column({ space: 4 }) {
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.doc'))
              .fontSize(16)
              .fontColor([$r('sys.color.font_secondary')])

            Text(this.getFileName(this.item.path ?? ''))
              .fontSize($r('sys.float.Body_M'))
              .fontColor($r('sys.color.font_primary'))
              .layoutWeight(1)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')

          // 来源路径
          Text(this.item.path)
            .fontSize($r('sys.float.Body_S'))
            .fontColor($r('sys.color.font_secondary'))
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ left: 24 })
        }
        .padding(12)
        .borderRadius(8)
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
  }

  private getPersonsByType(type: FinPersonType): string {
    let persons = this.item.person?.filter(p => p.type === type)
    if (persons && persons.length > 0) {
      return persons.map(p => p.name).join('、')
    }
    return ''
  }

  private getFileSuffix(path: string): string {
    let index = path.lastIndexOf('.')
    if (index >= 0) {
      return path.substring(index + 1)
    }
    return ''
  }

  private getFileName(path: string): string {
    let slashIndex = path.lastIndexOf('/')
    if (slashIndex < 0) {
      slashIndex = path.lastIndexOf('\\')
    }
    if (slashIndex >= 0) {
      return path.substring(slashIndex + 1)
    }
    return path
  }
}
