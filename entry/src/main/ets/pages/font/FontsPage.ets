import { window } from '@kit.ArkUI'
import { CommonConstants, ToolBar } from '@ohpg/fin-framework'
import { FontManager } from '../../reader/dynamic/entity/FontManager'
import { FontInfo, FontType } from '../../reader/dynamic/entity/FontInfo'
import { FileUtil } from '../../util/FileUtil'
import { windowAttributeModifier } from '../../style/Modifier'

interface FontRow {
  info: FontInfo
  current: boolean
}

/** 卡片分组样式：宽度 / 圆角 / 裁剪 / 背景，与 groupAttributeModifier 对齐 */
@Extend(ListItemGroup)
function cardStyle() {
  .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
  .backgroundColor($r('sys.color.comp_background_list_card'))
  .clip(true)
}

@Entry
@Component
struct FontsPage {

  private fontManager: FontManager = AppStorage.get(FontManager.MANAGER)!

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  /** 系统字体（单项） */
  @State systemRow?: FontRow = undefined

  /** 我的字体（导入） */
  @State importedRows: FontRow[] = []

  @State fontsSize: string = ''

  aboutToAppear(): void {
    this.refresh()
  }

  private buildRow(info: FontInfo): FontRow {
    return { info: info, current: this.fontManager.isCurrentFont(info) }
  }

  private async refresh() {
    this.systemRow = this.buildRow(this.fontManager.getSystemFont())
    this.importedRows = this.fontManager.getImportedFonts().map((info) => this.buildRow(info))
    let size = await this.fontManager.getFontsSize()
    this.fontsSize = FileUtil.formatFileSize(size)
  }

  /** 选中某字体为当前字体 */
  private selectFont(row: FontRow) {
    if (row.current) {
      return
    }
    let ok = this.fontManager.setCurrentFont(row.info)
    if (ok) {
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.font_apply_success') })
      this.refresh()
    }
  }

  private importFont() {
    this.fontManager.importFont()
      .then((font) => {
        if (font) {
          this.getUIContext().getPromptAction().showToast({ message: $r('app.string.font_import_success') })
          this.refresh()
        }
      })
      .catch(() => {
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.font_import_fail') })
      })
  }

  private showDeleteDialog(row: FontRow) {
    // 正在使用的字体不允许删除
    if (row.current) {
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.font_delete_current_forbid') })
      return
    }
    this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.font_delete_confirm_title'),
      message: $r('app.string.font_delete_confirm_msg'),
      buttons: [
        { text: $r('app.string.prefer_clear_local_copy_cancel'), color: $r('sys.color.ohos_id_color_text_secondary') },
        { text: $r('app.string.font_delete_confirm'), color: $r('sys.color.ohos_id_color_warning') }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.fontManager.deleteFont(row.info).then((ok) => {
          if (ok) {
            this.getUIContext().getPromptAction().showToast({ message: $r('app.string.font_delete_success') })
            this.refresh()
          } else {
            this.getUIContext().getPromptAction().showToast({ message: $r('app.string.font_delete_current_forbid') })
          }
        })
      }
    })
  }

  private showClearDialog() {
    this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.font_clear_confirm_title'),
      message: $r('app.string.font_clear_confirm_msg'),
      buttons: [
        { text: $r('app.string.prefer_clear_local_copy_cancel'), color: $r('sys.color.ohos_id_color_text_secondary') },
        { text: $r('app.string.font_delete_confirm'), color: $r('sys.color.ohos_id_color_warning') }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.fontManager.clearAllFonts().then(() => {
          this.getUIContext().getPromptAction().showToast({ message: $r('app.string.font_clear_success') })
          this.refresh()
        })
      }
    })
  }

  /** ToolBar 右上角：导入字体 */
  @Builder
  toolbarActionBuilder() {
    SymbolGlyph($r('sys.symbol.plus'))
      .fontSize(24)
      .fontColor([$r('sys.color.ohos_id_color_text_primary')])
      .onClick(() => {
        this.importFont()
      })
  }

  /** 分组标题：独立成组，透明背景，位于卡片之外 */
  @Builder
  titleGroup(title: ResourceStr) {
    ListItemGroup() {
      ListItem() {
        Text(title)
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .width(CommonConstants.FULL_PERCENT)
          .padding({
            left: $r('sys.float.ohos_id_card_margin_start'),
            top: $r('sys.float.ohos_id_elements_margin_vertical_l'),
            bottom: CommonConstants.SPACE_8
          })
      }
      .selectable(false)
    }
  }

  private typeIcon(type: FontType): Resource {
    if (type === FontType.SYSTEM) {
      return $r('sys.symbol.textformat')
    }
    return $r('sys.symbol.folder')
  }

  private subTitle(row: FontRow): ResourceStr {
    if (row.info.type === FontType.SYSTEM) {
      return $r('app.string.font_desc_system')
    }
    if (row.current) {
      return $r('app.string.font_status_in_use')
    }
    return $r('app.string.font_desc_imported')
  }

  /** 是否允许删除：非系统、非当前 */
  private canDelete(row: FontRow): boolean {
    return !row.info.isSystem() && !row.current
  }

  /** 左滑删除按钮 */
  @Builder
  swipeDeleteBuilder(row: FontRow) {
    Row() {
      SymbolGlyph($r('sys.symbol.trash'))
        .fontSize(22)
        .fontColor([$r('sys.color.font_on_primary')])
      Text($r('app.string.font_delete_confirm'))
        .fontSize(14)
        .fontColor($r('sys.color.font_on_primary'))
        .margin({ left: CommonConstants.SPACE_4 })
    }
    .justifyContent(FlexAlign.Center)
    .width(96)
    .height(CommonConstants.FULL_PERCENT)
    .backgroundColor($r('sys.color.ohos_id_color_warning'))
    .onClick(() => {
      this.showDeleteDialog(row)
    })
  }

  /** 单个字体行内容 */
  @Builder
  fontItemBuilder(row: FontRow) {
    Row({ space: CommonConstants.SPACE_12 }) {
      SymbolGlyph(this.typeIcon(row.info.type))
        .fontSize(24)
        .fontColor([$r('sys.color.ohos_id_color_text_primary')])
      Column({ space: 2 }) {
        Text(row.info.name)
          .fontSize(18)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.subTitle(row))
          .fontSize(13)
          .fontColor(row.current
            ? $r('sys.color.ohos_id_color_component_activated')
            : $r('sys.color.ohos_id_color_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 使用中：勾选标记
      if (row.current) {
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(22)
          .fontColor([$r('sys.color.ohos_id_color_component_activated')])
      }
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(64)
    .padding({ left: CommonConstants.SPACE_16, right: CommonConstants.SPACE_16 })
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .onClick(() => {
      this.selectFont(row)
    })
  }

  @Builder
  fontListItem(row: FontRow) {
    ListItem() {
      this.fontItemBuilder(row)
    }
    .swipeAction(this.canDelete(row) ? {
      end: {
        builder: () => { this.swipeDeleteBuilder(row) }
      }
    } : undefined)
  }

  build() {
    Column({ space: CommonConstants.SPACE_8 }) {
      ToolBar({
        title: $r('app.string.prefer_font_management'),
      }) {
        this.toolbarActionBuilder()
      }

      List({ space: 0 }) {
        // 系统字体组
        this.titleGroup($r('app.string.font_group_system'))
        ListItemGroup() {
          if (this.systemRow) {
            ForEach([this.systemRow], (row: FontRow) => {
              this.fontListItem(row)
            }, (row: FontRow) => `${row.info.key}_${row.current}`)
          }
        }
        .cardStyle()

        // 我的字体组
        this.titleGroup($r('app.string.font_group_imported'))
        ListItemGroup() {
          if (this.importedRows.length > 0) {
            ForEach(this.importedRows, (row: FontRow) => {
              this.fontListItem(row)
            }, (row: FontRow) => `${row.info.key}_${row.current}`)
          } else {
            ListItem() {
              Text($r('app.string.font_imported_empty'))
                .fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .width(CommonConstants.FULL_PERCENT)
                .height(56)
                .textAlign(TextAlign.Center)
                .backgroundColor($r('sys.color.comp_background_list_card'))
            }
          }
        }
        .cardStyle()

        // 清理全部字体
        this.titleGroup($r('app.string.font_group_manage'))
        ListItemGroup() {
          ListItem() {
            Row({ space: CommonConstants.SPACE_12 }) {
              SymbolGlyph($r('sys.symbol.trash'))
                .fontSize(24)
                .fontColor([$r('sys.color.ohos_id_color_text_primary')])
              Text($r('app.string.font_clear'))
                .fontSize(18)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
              Blank()
              Text(this.fontsSize)
                .fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }
            .width(CommonConstants.FULL_PERCENT)
            .height(56)
            .padding({ left: CommonConstants.SPACE_16, right: CommonConstants.SPACE_16 })
            .backgroundColor($r('sys.color.comp_background_list_card'))
            .onClick(() => {
              this.showClearDialog()
            })
          }
        }
        .cardStyle()
        .margin({ bottom: CommonConstants.SPACE_16 })
      }
      .width('90%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Fade)
      .divider({
        strokeWidth: 1,
        color: $r('sys.color.ohos_id_divider_color'),
        startMargin: $r('sys.float.ohos_id_card_margin_start'),
        endMargin: $r('sys.float.ohos_id_card_margin_end')
      })
    }
    .alignItems(HorizontalAlign.Center)
    .padding({
      bottom: this.currentAvoidArea?.bottomRect.height
    })
    .attributeModifier(windowAttributeModifier)
  }
}
