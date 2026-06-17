import { AdaptiveNavBar, LazyDataSource, NavTabMeta } from '@ohpg/fin-framework'
import { AppPrefer } from '../../prefer/AppPrefer'
import { HomeControl } from './HomeControl'
import { LocalPage } from './local/LocalPage'
import { OnlinePage } from './online/OnlinePage'
import { AboutPage } from './about/AboutPage'

@Entry
@Component
struct HomePage {

  @StorageLink(AppPrefer.PREFER) appPrefer?: AppPrefer = undefined

  @State currentIndex: number = 0

  @Provide("navTopOffset") navTopOffset: number = 0
  @Provide("navBottomOffset") navBottomOffset: number = 0
  @Provide("navStartOffset") navStartOffset: number = 0
  @Provide("navEndOffset") navEndOffset: number = 0

  private homeControl = new HomeControl()

  private swiperController: SwiperController = new SwiperController()

  private tabs: NavTabMeta[] = [
    { title: $r('app.string.tab_local'), icon: $r('sys.symbol.house_fill') } as NavTabMeta,
    { title: $r('app.string.tab_online'), icon: $r('sys.symbol.externaldrive_fill_3') } as NavTabMeta,
    { title: $r('app.string.tab_about'), icon: $r('sys.symbol.square_fill_grid_2x2') } as NavTabMeta,
  ]

  private tabDataSource: LazyDataSource<NavTabMeta> = new LazyDataSource<NavTabMeta>()

  aboutToAppear(): void {
    AppStorage.setOrCreate("currentHomeControl", this.homeControl)
    this.tabDataSource.dataArray = this.tabs
    const savedIndex = this.appPrefer!.getHomeTabIndex()
    this.currentIndex = savedIndex < this.tabs.length ? savedIndex : 0
  }

  private onTabSelect(index: number): void {
    this.currentIndex = index
    this.swiperController.changeIndex(index, false)
    this.appPrefer?.setHomeTabIndex(index)
  }

  build() {
    Stack() {
      // 内容区
      Swiper(this.swiperController) {
        LazyForEach(this.tabDataSource, (item: NavTabMeta, index: number) => {
          if (index === 0) {
            LocalPage()
          } else if (index === 1) {
            OnlinePage()
          } else {
            AboutPage()
          }
        }, (item: NavTabMeta, index: number) => index.toString())
      }
      .cachedCount(1)
      .index(this.currentIndex)
      .indicator(false)
      .loop(false)
      .disableSwipe(true)
      .duration(0)
      .width('100%')
      .height('100%')

      // 导航栏（悬浮在内容上层）
      AdaptiveNavBar({
        tabs: this.tabs,
        currentIndex: this.currentIndex,
        onTabSelect: (index: number) => { this.onTabSelect(index) },
        navTopOffset: $navTopOffset,
        navBottomOffset: $navBottomOffset,
        navStartOffset: $navStartOffset,
        navEndOffset: $navEndOffset,
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
  }

  onBackPress(): boolean | void {
    if (this.currentIndex > 0) {
      return false
    }
    return this.homeControl.goBack()
  }

  aboutToDisappear(): void {
    AppStorage.delete("currentHomeControl")
  }
}
