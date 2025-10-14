import { Fonts } from "../entity/Fonts";
import { FontSlider } from "./FontSlider";
import { bookParser, readerCore } from "@kit.ReaderKit";
import { CommonConstants } from "../../../common/CommonConstants";

@Component
export struct FontView {

  @Consume bookSetting: readerCore.ReaderSetting

  @Consume bookHandler: bookParser.BookParserHandler

  aboutToAppear(): void {
  }

  build() {
    Column({space: CommonConstants.SPACE_16}) {

      // 字体
      GridRow({
        columns: Fonts.FONTS.length,
        gutter: CommonConstants.SPACE_16,
        direction: GridRowDirection.Row
      }) {
        ForEach(Fonts.FONTS, (font: string) => {
          GridCol({ span: 1 }) {
            FontItemView({font: font})
          }
        });
      }
      .alignItems(ItemAlign.Center)
      .width('100%')
      .constraintSize({maxWidth: 400})

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

  @Consume @Watch('onSettingChanged') bookSetting: readerCore.ReaderSetting

  @Consume bookHandler: bookParser.BookParserHandler

  @Require @State font: string

  @State fontSelected: boolean = false

  aboutToAppear(): void {
    this.onSettingChanged()
  }

  build() {
    Text(Fonts.FONT_NAME[this.font])
      .fontSize(14)
      .borderRadius(12)
      .borderWidth(1.5)
      .width('100%')
      .height(48)
      .textAlign(TextAlign.Center)
      .fontColor(this.fontSelected ? Color.Red : Color.Black)
      .backgroundColor(this.fontSelected ? $r('app.color.ic_bg_font_selected') : $r('app.color.ic_bg_grey'))
      .borderColor(this.fontSelected ? $r('app.color.ic_border_font_selected') : $r('app.color.color_transparent'))
      .width('100%')
      .onClick(() => {
        this.bookSetting.fontName = this.font
        this.bookSetting.fontPath = Fonts.FONT_PATH[this.font]
      })
  }

  private onSettingChanged() {
    this.fontSelected = this.bookSetting.fontPath === Fonts.FONT_PATH[this.font]
  }

}