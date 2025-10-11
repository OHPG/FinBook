import { bookParser } from '@kit.ReaderKit';
import { readerCore } from "@kit.ReaderKit";
import { ReadPageComponent } from "@kit.ReaderKit";
import { CommonConstants } from "../../common/CommonConstants";
import { AsyncCallback } from "@kit.BasicServicesKit";
import { display } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { XUtil } from './util/XUtil';
import { XMenuView } from './menu/XMenuView';

@Reusable
@Component
export struct XReaderView {

  @Require @Prop bookPath: string = '';

  @State bookLoading: boolean = false;

  @State bookMenu: boolean = false

  private bookCtrl: readerCore.ReaderComponentController = new readerCore.ReaderComponentController()

  @Provide bookHandler?: bookParser.BookParserHandler = undefined

  @Provide bookSpine?: bookParser.SpineItem = undefined

  @Provide @Watch('onSettingChange') bookSetting: readerCore.ReaderSetting = {
    fontName: '系统字体',
    fontPath: '',
    fontSize: 18,
    fontColor: '#000000',
    fontWeight: 400,
    lineHeight: 1.9,
    nightMode: false,
    themeColor: 'rgba(248, 249, 250, 1)',
    themeBgImg: '',
    flipMode: '0',
    scaledDensity: display.getDefaultDisplaySync().scaledDensity > 0 ? display.getDefaultDisplaySync().scaledDensity :
      1,
    viewPortWidth: 370, // 视口宽度，需要根据设备实际情况获取
    viewPortHeight: 800, // 视口高度，需要根据设备实际情况获取
  }

  private callback: AsyncCallback<readerCore.ReaderComponentController> = (error, controller) => {
    console.log("xxx: error = " + JSON.stringify(error))
    // sh
  }

  aboutToAppear(): void {
    AppStorage.setOrCreate('bookCtrl', this.bookCtrl)
    this.bookCtrl.init(this.getUIContext().getHostContext()! as common.UIAbilityContext)
    // this.bookCtrl.on('pageShow', (info) => {
    //
    // })
    // this.bookCtrl.on('resourceRequest', (data: string): ArrayBuffer => {
    //   if (data.length <= 0) return new ArrayBuffer(0);
    //   let buffer: ArrayBuffer | undefined = undefined
    //   if (XUtil.isFont(data)) {
    //     // TODO 选中的字体
    //     data = ''
    //   }
    //   buffer = XUtil.loadFileFromAssets(this.getUIContext().getHostContext()!, data)
    //   if (!buffer) {
    //     buffer = XUtil.loadFileFromPath(data)
    //   }
    //   return buffer
    // })
    this.parseBook()
  }

  private async parseBook() {
    this.bookHandler = await bookParser.getDefaultHandler(this.bookPath)
    this.bookCtrl.registerBookParser(this.bookHandler)
    this.bookHandler.getCatalogList()
    this.bookCtrl.startPlay(0, "")
  }

  build() {
    Stack() {
      ReadPageComponent({controller: this.bookCtrl, readerCallback: (ctrl) => {  }})
        .width(CommonConstants.FULL_PERCENT)
        .height(CommonConstants.FULL_PERCENT)
        .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
          console.log("xxx: size = " + JSON.stringify(newValue))
          // this.bookSetting.viewPortWidth = newValue.width! as number
          // this.bookSetting.viewPortHeight = newValue.height! as number
        })
        .onClick(() => {
          this.bookMenu = true
        })

      // loading

      // menu
      if (this.bookHandler) {
        // XMenuView()
        //   .width(CommonConstants.FULL_PERCENT)
        //   .height(CommonConstants.FULL_PERCENT)
        //   .visibility(this.bookMenu ? Visibility.Visible : Visibility.Hidden)
      }

    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

  private onSettingChange() {
    this.bookCtrl.setPageConfig(this.bookSetting)
  }

  aboutToDisappear(): void {
    this.bookCtrl.off('pageShow')
    this.bookCtrl.off('resourceRequest')
    this.bookCtrl.releaseBook()
    AppStorage.delete('bookCtrl')
  }

}