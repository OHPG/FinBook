import { FontSlider } from "./FontSlider";
import { FontFileInfo } from "../info/FontFileInfo";
import { bookParser, readerCore } from "@kit.ReaderKit";

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
    Column() {
      Column() {
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
        }.margin({ top: 24, left: 16, right: 16 })

        Text()
          .width('92%')
          .height(1)
          .margin({ left: 16, top: 12, right: 16 })
          .backgroundColor($r('app.color.ic_bg_grey'))

        FontSlider({
          step: 2,
          min: 12,
          max: 32,
          value: Number(this.bookSetting.fontSize),
          onSliderChange: (value) => {
            this.bookSetting.fontSize = value
          }
        })
          .margin({ top: 12, bottom: 12 })

        FontSlider({
          pre: '三',
          suf: '三',
          step: 0.2,
          min: 1.2,
          max: 2.5,
          value: Number(this.bookSetting.lineHeight),
          onSliderChange: (value) => {
            this.bookSetting.lineHeight = value
          }
        })
          .margin({ top: 12, bottom: 12 })
      }
      .width('60%')
    }
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)
    .width('100%')
    .zIndex(3)
  }

}

@Component
struct FontItemView {

  build() {

  }

}