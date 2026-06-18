import { BreakpointSystem, FinItem, FinItemType, FinPerson, FinPersonType } from "@ohpg/fin-core"
import { CommonConstants } from "../../common/CommonConstants"
import { DetailViewModel } from "./DetailViewModel"
import { MediaArgs } from "./MediaArgs"
import { AppRouter } from "../../router/AppRouter"
import { CoverImage } from "../../widget/cover/CoverImage"
import { DownloadState } from "../../down/DownloadState"

/**
 * 操作按钮组件：阅读 + 下载进度叠加显示
 */
@Component
export struct DetailOperate {

  @LocalStorageLink("viewModel") viewModel?: DetailViewModel = undefined

  @Require @Prop item?: FinItem = undefined

  // 用 @State 强制追踪 downloadState 的变化
  @State downloadingState: boolean = false
  @State downloadProgress: number = 0
  @State downloadSizeText: string = ''
  @State downloadSpeedText: string = ''

  // 定时器ID，用于轮询 downloadState
  private pollTimer?: number = undefined

  aboutToAppear(): void {
    // 启动轮询，每100ms检查一次downloadState
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
    Column({ space: 8 }) {
      // 阅读/下载按钮
      Button({ type: ButtonType.Capsule }) {
        Row({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.book_pages_fill_1'))
            .fontColor([$r('sys.color.font_on_primary')])
            .fontSize($r('sys.float.Title_S'))
          
          Text(this.downloadingState ? '下载中' : '阅读')
            .fontColor($r('sys.color.font_on_primary'))
            .fontSize($r('sys.float.Body_M'))
        }
        .justifyContent(FlexAlign.Center)
      }
      .width(120)
      .height(40)
      .enabled(!this.downloadingState)
      .onClick(() => this.playOrNot())

      // 下载进度信息（独立在按钮下方）
      if (this.downloadingState) {
        Column({ space: 4 }) {
          // 进度条
          Row({ space: 8 }) {
            Progress({
              value: this.downloadProgress,
              total: 100,
              type: ProgressType.Linear
            })
              .width(200)
              .height(4)
              .color($r('sys.color.ohos_id_color_emphasize'))

            Text(Math.floor(this.downloadProgress) + '%')
              .fontSize($r('sys.float.Body_S'))
              .fontColor($r('sys.color.font_primary'))
          }

          // 详细信息（大小 + 速度）
          Text(this.getDownloadInfo())
            .fontSize($r('sys.float.Body_S'))
            .fontColor($r('sys.color.font_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
      }
    }
    .alignItems(HorizontalAlign.Start)
  }

  private getDownloadInfo(): string {
    const parts: string[] = []
    
    // 已下载 / 总大小
    if (this.downloadSizeText) {
      parts.push(this.downloadSizeText)
    }
    
    // 下载速度
    if (this.downloadSpeedText) {
      parts.push(this.downloadSpeedText)
    }
    
    return parts.join('  •  ')
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
 * 详情页头部（封面 + 标题 + 元数据）
 */
@Component
export struct DetailHeader {

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT)
  currentWidthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM

  @Prop item: FinItem

  build() {
    Column({ space: 16 }) {
      // 封面区域（高斯模糊背景 + 居中封面）
      Stack() {
        // 背景模糊
        CoverImage({ image: this.item?.image, imageBlur: 20 })
          .width('100%')
          .height('100%')

        // 半透明遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.4)')

        // 居中封面
        CoverImage({ image: this.item?.image })
          .width(140)
          .aspectRatio(0.67)
          .borderRadius(8)
          .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.3)', offsetY: 4 })
      }
      .width('100%')
      .height(this.currentWidthBreakpoint <= WidthBreakpoint.WIDTH_SM ? 240 : 300)

      // 标题 + 元数据区
      Column({ space: 12 }) {
        // 主标题
        Text(this.item.name)
          .fontSize($r('sys.float.Title_L'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 副标题（年份、类型等）
        if (this.item.productionYear || this.item.genres) {
          Row({ space: 8 }) {
            if (this.item.productionYear) {
              Text(this.item.productionYear)
                .fontSize($r('sys.float.Body_M'))
                .fontColor($r('sys.color.font_secondary'))
            }
            if (this.item.genres && this.item.genres.length > 0) {
              Text('·')
                .fontSize($r('sys.float.Body_M'))
                .fontColor($r('sys.color.font_secondary'))
              Text(this.item.genres.join(' / '))
                .fontSize($r('sys.float.Body_M'))
                .fontColor($r('sys.color.font_secondary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
        }

        // 评分
        if (this.item.communityRating) {
          Row({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.star_fill'))
              .fontSize($r('sys.float.Body_S'))
              .fontColor([Color.Orange])
            Text(this.item.communityRating)
              .fontSize($r('sys.float.Body_M'))
              .fontColor($r('sys.color.font_primary'))
          }
        }

        // 操作按钮（仅书籍类型显示）
        if (this.item.type === FinItemType.Book) {
          DetailOperate({ item: this.item })
            .margin({ top: 4 })
        }

        // 作者信息
        this.buildPersonInfo()

        // 简介
        if (this.item.overview) {
          Column({ space: 4 }) {
            Text('简介')
              .fontSize($r('sys.float.Body_M'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))

            Text(this.item.overview)
              .fontSize($r('sys.float.Body_M'))
              .fontColor($r('sys.color.font_secondary'))
              .lineHeight(22)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ top: 8 })
        }

        // 文件信息（大小、格式、来源路径等）
        this.buildFileInfo()
      }
      .padding({ left: 16, right: 16, bottom: 16 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
  }

  @Builder
  buildPersonInfo() {
    Column({ space: 8 }) {
      // 作者
      if (this.getPersonsByType(FinPersonType.Author)) {
        this.buildInfoRow('作者', this.getPersonsByType(FinPersonType.Author))
      }

      // 插画师
      if (this.getPersonsByType(FinPersonType.Illustrator)) {
        this.buildInfoRow('插画', this.getPersonsByType(FinPersonType.Illustrator))
      }

      // 译者
      if (this.getPersonsByType(FinPersonType.Translator)) {
        this.buildInfoRow('译者', this.getPersonsByType(FinPersonType.Translator))
      }
    }
    .width('100%')
  }

  private getPersonsByType(type: FinPersonType): string {
    let persons = this.item.person?.filter(p => p.type === type)
    if (persons && persons.length > 0) {
      return persons.map(p => p.name).join('、')
    }
    return ''
  }

  @Builder
  buildFileInfo() {
    Column({ space: 8 }) {
      Divider()
        .color($r('sys.color.comp_divider'))
        .margin({ top: 8, bottom: 8 })

      Text('文件信息')
        .fontSize($r('sys.float.Body_M'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))

      // 文件格式
      if (this.getFileSuffix(this.item.path ?? '')) {
        this.buildInfoRow('格式', this.getFileSuffix(this.item.path ?? '').toUpperCase())
      }

      // 文件路径
      if (this.item.path) {
        this.buildInfoRow('来源', this.item.path)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  buildInfoRow(label: string, value: string) {
    Row({ space: 12 }) {
      Text(label)
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_secondary'))
        .width(60)

      Text(value)
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_primary'))
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  private getFileSuffix(path: string): string {
    let index = path.lastIndexOf('.')
    if (index >= 0) {
      return path.substring(index + 1)
    }
    return ''
  }
}
