import { bookParser } from '@kit.ReaderKit';
import { readerCore } from "@kit.ReaderKit";
import { ReadPageComponent } from "@kit.ReaderKit";
import { CommonConstants } from "../../common/CommonConstants";
import { AsyncCallback } from "@kit.BasicServicesKit";
import { display } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { XMenuView } from './menu/XMenuView';
import { XUtil } from './util/XUtil';

@Reusable
@Component
export struct XReaderView {

  @Require @Prop bookPath: string = '';

  @State bookLoading: boolean = false;

  @Consume immersiveMode: boolean

  @Consume menuVisible: boolean

  private bookCtrl: readerCore.ReaderComponentController = new readerCore.ReaderComponentController()

  private bookCtrlPrepared: boolean = false

  @Provide bookHandler?: bookParser.BookParserHandler = undefined

  @Provide bookSpine?: bookParser.SpineItem = undefined

  @State bookState: readerCore.PageState = readerCore.PageState.PAGE_WAITING

  @Provide @Watch('onSettingChange') bookSetting: readerCore.ReaderSetting = {
    fontName: '系统字体',
    fontPath: '',
    fontSize: 12,
    fontColor: '#000000',
    fontWeight: 400,
    lineHeight: 1,
    nightMode: false,
    themeColor: 'rgba(248, 249, 250, 1)',
    themeBgImg: '',
    flipMode: '0',
    scaledDensity: display.getDefaultDisplaySync().scaledDensity > 0 ? display.getDefaultDisplaySync().scaledDensity : 1,
    viewPortWidth: 0, // 视口宽度，需要根据设备实际情况获取
    viewPortHeight: 0, // 视口高度，需要根据设备实际情况获取
  }

  private callback: AsyncCallback<readerCore.ReaderComponentController> = (error, controller) => {
    console.log("xxx: error = " + JSON.stringify(error))
    // sh
  }

  aboutToAppear(): void {
    AppStorage.setOrCreate('bookCtrl', this.bookCtrl)
    this.bookCtrl.on('pageShow', (info) => {
      this.bookState = info.state
      if (info.state === readerCore.PageState.PAGE_ON_SHOW) {
        if (this.bookSpine?.index !== info.resourceIndex) {
          let spineList = this.bookHandler?.getSpineList()
          this.bookSpine = spineList?.find((spine) => spine.index === info.resourceIndex)
        }
      }
      console.log("xxx: onPageShow " + JSON.stringify(info))
    })
    this.bookCtrl.on('resourceRequest', (data: string): ArrayBuffer => {
      console.log("xxx: onResource " + data)
      if (data.length <= 0) return new ArrayBuffer(0);
      let buffer: ArrayBuffer | undefined = undefined
      if (XUtil.isFont(data)) {
        // TODO 选中的字体
        data = ''
      }
      buffer = XUtil.loadFileFromAssets(this.getUIContext().getHostContext()!, data)
      if (!buffer) {
        buffer = XUtil.loadFileFromPath(data)
      }
      return buffer
    })
    this.parseBook().then(() => {

    })
      .catch((error: Error) => {
        console.error("xxx: " + JSON.stringify(error))
      })
  }

  private async parseBook() {
    await this.bookCtrl.init(this.getUIContext().getHostContext()! as common.UIAbilityContext)
    this.bookCtrlPrepared = true
    this.onSettingChange()
    this.bookHandler = await bookParser.getDefaultHandler(this.bookPath)
    this.bookCtrl.registerBookParser(this.bookHandler)
    this.bookHandler.getCatalogList()
    this.bookCtrl.startPlay(0, "")
  }

  build() {
    Stack() {
      ReadPageComponent({controller: this.bookCtrl, readerCallback: (error, ctrl) => {}})
        .width(CommonConstants.FULL_PERCENT)
        .height(CommonConstants.FULL_PERCENT)
        .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
          this.bookSetting.viewPortWidth = this.getUIContext().vp2px(newValue.width! as number)
          this.bookSetting.viewPortHeight = this.getUIContext().vp2px(newValue.height! as number)
        })
        .onClick(() => {
          // 这里的逻辑有点问题
          this.immersiveMode = !this.immersiveMode
        })

      // loading

      // menu
      if (this.bookState === readerCore.PageState.PAGE_ON_SHOW) {
        XMenuView()
          .width(CommonConstants.FULL_PERCENT)
          .height(CommonConstants.FULL_PERCENT)
          .visibility(this.menuVisible ? Visibility.Visible : Visibility.Hidden)
      }
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

  private onSettingChange() {
    if (!this.bookCtrlPrepared) return
    if (this.bookSetting.viewPortWidth <= 0 || this.bookSetting.viewPortHeight <= 0) return
    this.bookCtrl.setPageConfig(this.bookSetting)
  }

  aboutToDisappear(): void {
    this.bookCtrl.off('pageShow')
    this.bookCtrl.off('resourceRequest')
    this.bookCtrl.releaseBook()
    AppStorage.delete('bookCtrl')
  }

}