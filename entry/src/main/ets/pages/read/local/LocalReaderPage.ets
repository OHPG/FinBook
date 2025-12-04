import { MediaArgs } from '../../detail/MediaArgs'
import { router, window } from '@kit.ArkUI'
import { LocalReaderViewModel } from './LocalReaderViewModel'
import { StaticReaderView } from '../../../reader/static/StaticReaderView'
import { DynamicReaderView } from '../../../reader/dynamic/DynamicReaderView'
import { CommonConstants, ScrollRefreshView } from '@ohpg/fin-framework'
import { ToolBar } from '@ohpg/fin-framework'
import { FinBookRawSource } from '../../../entity/FinBookRawSource'
import { BookType } from '../../../enum/BookType'
import { common } from '@kit.AbilityKit'

@Entry
@Component
struct LocalReaderPage {
  private args: MediaArgs = router.getParams() as MediaArgs

  private viewModel = new LocalReaderViewModel(getContext(), this.args)

  private immersiveModeTimer?: number = undefined

  @StorageProp("currentAvoidArea") avoidArea?: window.AvoidArea = undefined

  @Provide bookTitle: string = this.args.name

  /**
   * 是否是沉浸式
   */
  @Provide @Watch("onImmersiveModeChange") immersiveMode: boolean = false

  /**
   * 菜单是否可用
   */
  @State menuEnable: boolean = false

  /**
   * 菜单是否可见
   */
  @Provide @Watch("onMenuChanged") menuVisible: boolean = false

  /**
   * 书籍章节数
   */
  @Provide @Watch('onChapterChange') bookChapter: number = 0

  /**
   * 阅读进度
   */
  @Provide @Watch('onProgressChange') readProgress: number = 0

  aboutToAppear(): void {
    this.viewModel.startRead()
  }

  @Builder
  staticView(path: string, type: BookType) {
    StaticReaderView({
      bookPath: path,
      bookType: type
    })
  }

  @Builder
  dynamicView(path: string) {
    DynamicReaderView({
      bookPath: path
    })
  }

  build() {
    Stack({alignContent: Alignment.Top}) {
      ScrollRefreshView({
        refreshEnable: false,
        source: this.viewModel,
        itemLayout: (source: FinBookRawSource) => {
          if (this.judgementType(source)) {
            this.staticView(source.path, source.type)
          } else {
            this.dynamicView(source.path)
          }
        }
      })
        .width(CommonConstants.FULL_PERCENT)
        .height(CommonConstants.FULL_PERCENT)

      Row() {
        ToolBar({title: this.args.name}) {
          SymbolGlyph($r('sys.symbol.slider_horizontal_2'))
            .fontSize($r('sys.float.Title_L'))
            .fontColor([$r('sys.color.font_primary')])
            .visibility(this.menuEnable ? Visibility.Visible : Visibility.Hidden)
            .onClick(() => {
              this.menuVisible = true
            })
        }
      }
      .backgroundColor($r('sys.color.background_primary'))
      .visibility(this.immersiveMode ? Visibility.Hidden : Visibility.Visible)
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

  private judgementType(source: FinBookRawSource): boolean {
    this.readProgress = source.progress
    this.bookTitle = source.name
    this.menuEnable = source.type === BookType.OTHER
    this.addImmersiveModeTimer()
    return source.type !== BookType.OTHER ? true : false
  }

  private clearImmersiveModeTimer() {
    if (this.immersiveModeTimer === undefined) return
    clearTimeout(this.immersiveModeTimer)
    this.immersiveModeTimer = undefined
  }

  private addImmersiveModeTimer() {
    if (this.immersiveModeTimer !== undefined) return
    this.immersiveModeTimer = setTimeout(() => {
      this.immersiveMode = true
      this.immersiveModeTimer = undefined
    }, 3000)
  }

  private onMenuChanged() {
    if (this.menuVisible) {
      this.clearImmersiveModeTimer()
    } else {
      this.addImmersiveModeTimer()
    }
  }

  private onChapterChange() {
    this.viewModel.updateProgress(this.readProgress, this.bookChapter)
  }

  private onProgressChange() {
    this.viewModel.updateProgress(this.readProgress, this.bookChapter)
  }

  private async onImmersiveModeChange() {
    try {
      let window = (this.getUIContext().getHostContext() as common.UIAbilityContext).windowStage.getMainWindowSync()
      if (this.immersiveMode) {
        this.clearImmersiveModeTimer()
        await window.setWindowSystemBarEnable([])
      } else {
        await window.setWindowSystemBarEnable(['status', 'navigation'])
        if (!this.menuVisible) {
          this.addImmersiveModeTimer()
        } else {
          // 监听
        }
      }
    } catch (e) {

    }
  }

  onBackPress(): boolean | void {
    if (this.menuVisible) {
      this.menuVisible = false
      return true
    }
    return false
  }

  aboutToDisappear(): void {
    this.immersiveMode = false
    this.viewModel.stopRead(this.readProgress)
  }

}