import { CommonConstants } from "../../../common/CommonConstants"
import { Colors } from "../entity/Colors"
import { readerCore } from "@kit.ReaderKit"

@Component
export struct ThemeView {

  aboutToAppear(): void {
  }

  build() {
    Scroll() {
      Row({ space: 12 }) {
        ForEach(Colors.THEMES, (item: string) => {
          ThemeItemView({themeColorKey: item})
        })
      }
    }
    .backgroundColor($r('sys.color.background_primary'))
    .borderRadius({ topRight: CommonConstants.CORNER_16, topLeft: CommonConstants.CORNER_16 })
    .padding(CommonConstants.SPACE_16)
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width(CommonConstants.FULL_PERCENT)
    .onClick(() => {})
  }

  aboutToDisappear(): void {

  }

}

@Component
struct ThemeItemView {

  @Consume bookSetting: readerCore.ReaderSetting

  @Require @State themeColorKey: string

  @State themeColorValue: string = ''

  aboutToAppear(): void {
    this.themeColorValue = Colors.THEME_COLOR[this.themeColorKey]
  }

  build() {
    Row()
      .width(80)
      .height(40)
      .borderWidth(this.bookSetting.themeColor === this.themeColorValue ? 1 : 2)
      .borderColor(this.bookSetting.themeColor === this.themeColorValue ? $r('app.color.ic_border_unselect') : this.themeColorValue)
      .backgroundImage(this.getBackgroundImage())
      .backgroundColor(this.themeColorValue)
      .backgroundImagePosition(Alignment.BottomEnd)
      .backgroundImageSize(ImageSize.Cover)
      .borderRadius(20)
      .onClick(() => {
        this.bookSetting.themeColor = this.themeColorValue
        let fontColor = '#000000'
        let nightMode = false
        let themeBg = ''
        if (this.themeColorKey === 'whiteSky') {
          themeBg = 'white_sky_first.jpg'
        } else if (this.themeColorKey === 'darkSky') {
          themeBg = 'dark_sky_first.jpg'
          nightMode = true
          fontColor = '#FFFFFF'
        } else if (this.themeColorKey === 'dark') {
          nightMode = true
          fontColor = '#FFFFFF'
        }
        this.bookSetting.fontColor = fontColor
        this.bookSetting.themeBgImg = themeBg
        this.bookSetting.nightMode = nightMode
      })
  }

  getBackgroundImage(): ResourceStr {
    if (this.themeColorKey === 'whiteSky') {
      return $r('app.media.white_sky_icon');
    } else if (this.themeColorKey === 'darkSky') {
      return $r('app.media.dark_sky_icon');
    }
    return '';
  }

  aboutToDisappear(): void {

  }

}