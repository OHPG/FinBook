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
    if (info.isPreset()) {
      return this.bookSetting.fontPath === info.absolutePath
    }
    return this.bookSetting.fontPath === this.fontManager.getFontPath(info.fileName)
      || (!!info.fileName && this.bookSetting.fontPath.endsWith(info.fileName))
  }

  private onFontClick(info: FontInfo) {
    // fontName 使用内核可定位的基名（非 UI 中文名），fontPath 由来源决定
    this.bookSetting.fontName = this.fontManager.getKernelFontName(info)
    this.bookSetting.fontPath = this.fontManager.getFontPathOf(info)
    this.fonts = this.fonts.slice()
  }

  build() {
    Column({space: CommonConstants.SPACE_16}) {

      // 字体：横向滚动，末尾为「添加」入口，屏幕放不下时可左右滑动
      List({ space: CommonConstants.SPACE_16 }) {
        ForEach(this.fonts, (info: FontInfo) => {
          ListItem() {
            FontItemView({
              info: info,
              selected: this.isSelected(info),
              onFontClick: () => {
                this.onFontClick(info)
              }
            })
          }
        }, (info: FontInfo) => info.key)

        // 添加字体入口（跳转字体管理页）
        ListItem() {
          FontAddItemView({
            onAddClick: () => {
              AppRouter.goToFonts(this.getUIContext())
            }
          })
        }
      }
      .listDirection(Axis.Horizontal)
      .width('100%')
      .height(48)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

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
      .width(96)
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

@Component
struct FontAddItemView {

  onAddClick: () => void = () => {}

  build() {
    Row() {
      SymbolGlyph($r('sys.symbol.plus'))
        .fontSize(22)
        .fontColor([Color.Black])
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .borderRadius(12)
    .borderWidth(1.5)
    .width(96)
    .height(48)
    .backgroundColor($r('app.color.ic_bg_grey'))
    .borderColor($r('app.color.color_transparent'))
    .onClick(() => {
      this.onAddClick()
    })
  }

}
