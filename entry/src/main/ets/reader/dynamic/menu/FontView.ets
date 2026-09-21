import { FontSlider } from "./FontSlider";
import { bookParser, readerCore } from "@kit.ReaderKit";
import { CommonConstants } from "../../../common/CommonConstants";
import { FontManager } from "../entity/FontManager";
import { FontInfo } from "../entity/FontInfo";
import { AppRouter } from "../../../router/AppRouter";

@Component
export struct FontView {

  @Consume bookSetting: readerCore.ReaderSetting

  @Consume bookHandler: bookParser.BookParserHandler

  private fontManager: FontManager = AppStorage.get(FontManager.MANAGER)!

  @State fonts: FontInfo[] = []

  aboutToAppear(): void {
    this.loadFonts()
  }

  private loadFonts() {
    // 系统字体 + 沙盒中已导入的字体
    this.fonts = this.fontManager.getAllFonts()
  }

  private isSelected(info: FontInfo): boolean {
    if (info.isSystem()) {
      return !this.bookSetting.fontPath
    }
    return this.bookSetting.fontPath === this.fontManager.getFontPath(info.fileName)
      || (!!info.fileName && this.bookSetting.fontPath.endsWith(info.fileName))
  }

  private onFontClick(info: FontInfo) {
    if (info.isSystem()) {
      this.bookSetting.fontName = info.key
      this.bookSetting.fontPath = ''
    } else {
      this.bookSetting.fontName = info.name
      this.bookSetting.fontPath = this.fontManager.getFontPath(info.fileName)
    }
    this.fonts = this.fonts.slice()
  }

  build() {
    Column({space: CommonConstants.SPACE_16}) {

      // 字体
      GridRow({
        columns: 2,
        gutter: CommonConstants.SPACE_16,
        direction: GridRowDirection.Row
      }) {
        ForEach(this.fonts, (info: FontInfo) => {
          GridCol({ span: 1 }) {
            FontItemView({
              info: info,
              selected: this.isSelected(info),
              onFontClick: () => {
                this.onFontClick(info)
              }
            })
          }
        }, (info: FontInfo) => info.key);
      }
      .alignItems(ItemAlign.Center)
      .width('100%')
      .constraintSize({maxWidth: 400})

      // 管理字体入口
      Text($r('app.string.font_manage_entry'))
        .fontSize(13)
        .fontColor($r('sys.color.ohos_id_color_component_activated'))
        .onClick(() => {
          AppRouter.goToFonts(this.getUIContext())
        })

      // 分割线
      Divider()
        .width('90%')
        .height(1)
        .backgroundColor($r('sys.color.ohos_id_divider_color'))

      // 字号
      FontSlider({
        step: 2,
        min: 12,
        max: 32,
        value: Number(this.bookSetting.fontSize),
        onSliderChange: (value) => {
          this.bookSetting.fontSize = value
        }
      })

      // 行高
      FontSlider({
        pre: '三',
        suf: '三',
        step: 0.1,
        min: 1.0,
        max: 2.0,
        value: Number(this.bookSetting.lineHeight),
        onSliderChange: (value) => {
          this.bookSetting.lineHeight = value
        }
      })
    }
    .width('100%')
    .backgroundColor($r('sys.color.background_primary'))
    .borderRadius({ topRight: CommonConstants.CORNER_16, topLeft: CommonConstants.CORNER_16 })
    .padding(CommonConstants.SPACE_16)
    .onClick(() => {})
  }

}

@Component
struct FontItemView {

  @Require @Prop info: FontInfo

  @Require @Prop selected: boolean

  onFontClick: () => void = () => {}

  build() {
    Text(this.info.name)
      .fontSize(14)
      .borderRadius(12)
      .borderWidth(1.5)
      .width('100%')
      .height(48)
      .textAlign(TextAlign.Center)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .padding({ left: 8, right: 8 })
      .fontColor(this.selected ? Color.Red : Color.Black)
      .backgroundColor(this.selected ? $r('app.color.ic_bg_font_selected') : $r('app.color.ic_bg_grey'))
      .borderColor(this.selected ? $r('app.color.ic_border_font_selected') : $r('app.color.color_transparent'))
      .onClick(() => {
        this.onFontClick()
      })
  }

}
