import { Colors } from "./Colors"

@Component
export struct ThemeView {

  @Provide @Watch("onThemeChange") currentTheme: string = ""

  aboutToAppear(): void {
    // TODO 恢复当前主题颜色
    this.currentTheme = Colors.themeList[0]
  }

  build() {
    Scroll() {
      Row({ space: 12 }) {
        ForEach(Colors.themeList, (item: string, index: number) => {
          ThemeItemView({themeColor: item})
        })
      }
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    }
    .margin({ top: 8 })
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  private onThemeChange() {

  }

  aboutToDisappear(): void {

  }

}

@Component
struct ThemeItemView {

  @Consume currentTheme: string

  @Require @State themeColor: string

  aboutToAppear(): void {

  }

  build() {
    Row()
      .width(80)
      .height(40)
      .borderWidth(this.currentTheme === this.themeColor ? 1 : 2)
      .borderColor(this.currentTheme === this.themeColor ? $r('app.color.ic_border_unselect') : this.themeColor)
      .backgroundImage(this.getBackgroundImage(this.themeColor))
      .backgroundColor(this.themeColor)
      .backgroundImagePosition(Alignment.BottomEnd)
      .backgroundImageSize(ImageSize.Cover)
      .borderRadius(20)
      .onClick(() => {
        this.currentTheme = this.themeColor
      })
  }

  getBackgroundImage(themeType: string): ResourceStr {
    if (themeType === 'whiteSky') {
      return $r('app.media.white_sky_icon');
    } else if (themeType === 'darkSky') {
      return $r('app.media.dark_sky_icon');
    }
    return '';
  }

  aboutToDisappear(): void {

  }

}