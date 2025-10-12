import { FontSlider } from "./FontSlider";
import { FontFileInfo } from "../info/FontFileInfo";
import { bookParser, readerCore } from "@kit.ReaderKit";
import { CommonConstants } from "../../../common/CommonConstants";

@Component
export struct FontView {

  @Consume bookHandler: bookParser.BookParserHandler

  @Consume bookSetting: readerCore.ReaderSetting

  fontList: Array<FontFileInfo> = [];

  aboutToAppear(): void {
    let context = this.getUIContext().getHostContext()!
    this.fontList =
      [new FontFileInfo(context.resourceManager.getStringSync($r('app.string.system_font')),
        ''),
        new FontFileInfo(context.resourceManager.getStringSync($r('app.string.source_han_serif_font')),
          'fonts/SourceHanSerifCN-VF.ttf')];
  }

  build() {
    Stack({alignContent: Alignment.Bottom}) {

      Column({space: CommonConstants.SPACE_16}) {
        GridRow({
          columns: { xs: 4, sm: 4, md: 9, lg: 12 },
          gutter: { x: 8, y: 8 },
          breakpoints: { value: ['0vp', '520vp', '840vp'] },
          direction: GridRowDirection.Row
        }) {
          ForEach(this.fontList, (data: FontFileInfo) => {
            GridCol({
              span: { xs: 1, sm: 2, md: 3, lg: 4 },
              offset: 0,
              order: 0
            }) {
              Column() {
                Text(data.getAlias())
                  .fontSize(14)
                  .borderRadius(12)
                  .borderWidth(1.5)
                  .width('100%')
                  .height(48)
                  .textAlign(TextAlign.Center)
                  .fontColor(this.bookSetting.fontPath === data.getPath() ?Color.Red : Color.Black)
                  .backgroundColor(this.bookSetting.fontPath === data.getPath() ? $r('app.color.ic_bg_font_selected') : $r('app.color.ic_bg_grey'))
                  .borderColor(this.bookSetting.fontPath === data.getPath() ? $r('app.color.ic_border_select_white') : $r('app.color.color_transparent'))
              }
              .width('100%')
              .onClick(() => {
                this.bookSetting.fontPath = data.getPath()
              })
            }
          });
        }

        // 分割线
        Divider()
          .width('90%')
          .height(1)
          .backgroundColor($r('app.color.ic_bg_grey'))

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
      .constraintSize({maxWidth: 400})
      .padding(CommonConstants.SPACE_16)
    }
    .hitTestBehavior(HitTestMode.Transparent)
    .width('100%')
    .height('100%')
  }

}

@Component
struct FontItemView {

  build() {

  }

}