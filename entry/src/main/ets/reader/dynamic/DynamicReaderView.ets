import { bookParser } from '@kit.ReaderKit';
import { readerCore } from "@kit.ReaderKit";
import { ReadPageComponent } from "@kit.ReaderKit";
import { CommonConstants } from "../../common/CommonConstants";
import { display } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { XMenuView } from './menu/XMenuView';
import { AppPrefer } from '../../prefer/AppPrefer';

@Reusable
@Component
export struct DynamicReaderView {

  private appPrefer: AppPrefer = AppStorage.get(AppPrefer.PREFER)!

  @Require @Prop bookPath: string = '';

  @State bookLoading: boolean = false;

  @Consume immersiveMode: boolean

  @Consume menuVisible: boolean

  @Consume readProgress: number

  private bookCtrl: readerCore.ReaderComponentController = new readerCore.ReaderComponentController()

  private bookCtrlPrepared: boolean = false

  @Provide bookHandler?: bookParser.BookParserHandler = undefined

  @Provide bookSpine?: bookParser.SpineItem = undefined

  @State bookState: readerCore.PageState = readerCore.PageState.PAGE_WAITING

  @Provide @Watch('onSettingChange') bookSetting: readerCore.ReaderSetting = {
    fontName: 'system',
    fontPath: '',
    fontSize: 16,
    fontColor: '#000000',
    fontWeight: 400,
    lineHeight: 1.4,
    nightMode: false,
    themeColor: 'rgba(248, 249, 250, 1)',
    themeBgImg: '',
    flipMode: '0',
    scaledDensity: display.getDefaultDisplaySync().scaledDensity > 0 ? display.getDefaultDisplaySync().scaledDensity : 1,
    viewPortWidth: 0, // 视口宽度，需要根据设备实际情况获取
    viewPortHeight: 0, // 视口高度，需要根据设备实际情况获取
  }

  private screenDensityCallBack?: Callback<number> = undefined;

  aboutToAppear(): void {
    this.restoreConfig()
    this.registerScreenDensityChange()
    AppStorage.setOrCreate('bookCtrl', this.bookCtrl)
    this.bookCtrl.on('pageShow', (info) => {
      if (info.state === readerCore.PageState.PAGE_ON_SHOW) {
        if (this.bookSpine?.index !== info.resourceIndex) {
          let spineList = this.bookHandler?.getSpineList()
          this.bookSpine = spineList?.find((spine) => spine.index === info.resourceIndex)
          if (this.bookSpine) {
            AppStorage.setOrCreate("boo_href", this.bookSpine.href)
          }
        }
      }
      this.readProgress = info.resourceIndex
      this.bookState = info.state
    })
    this.parseBook()
      .then(() => {
        this.bookCtrl.startPlay(this.readProgress, "")
      })
      .catch((error: Error) => {
        console.error("xxx: " + JSON.stringify(error))
      })
  }

  /**
   * 恢复之前的配置
   */
  private restoreConfig() {
    try {
      let config = this.appPrefer.getBookConfig()
      if (config && config.length > 0) {
        let setting: readerCore.ReaderSetting = JSON.parse(config)
        this.bookSetting.fontName = setting.fontName
        this.bookSetting.fontPath = setting.fontPath
        this.bookSetting.fontSize = setting.fontSize
        this.bookSetting.fontColor = setting.fontColor
        this.bookSetting.fontWeight = setting.fontWeight
        this.bookSetting.lineHeight = setting.lineHeight
        this.bookSetting.nightMode = setting.nightMode
        this.bookSetting.themeColor = setting.themeColor
        this.bookSetting.themeBgImg = setting.themeBgImg
        this.bookSetting.flipMode = setting.flipMode
      }
    } catch (e) {
      // ignore
    }
  }

  /**
   * 注册缩放文本缩放因子变化监听
   */
  registerScreenDensityChange() {
    this.screenDensityCallBack = (data: number) => {
      let displaySync = display.getDefaultDisplaySync();
      let scaledDensity = displaySync.scaledDensity;
      if (scaledDensity !== this.bookSetting.scaledDensity) {
        this.bookSetting.scaledDensity = scaledDensity
      }
    }
    display.on('change', this.screenDensityCallBack);
  }

  private async parseBook(): Promise<void> {
    await this.bookCtrl.init(this.getUIContext().getHostContext()! as common.UIAbilityContext)
    this.bookCtrlPrepared = true
    this.onSettingChange()
    this.bookHandler = await bookParser.getDefaultHandler(this.bookPath)
    this.bookCtrl.registerBookParser(this.bookHandler)

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
          this.immersiveMode = !this.immersiveMode
        })

      // loading

      // menu
      if (this.bookHandler) {
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
    this.saveSetting()
    this.bookCtrl.setPageConfig(this.bookSetting)
  }

  /**
    * 保存更改的配置
   */
  private saveSetting() {
    try {
      let config = JSON.stringify(this.bookSetting)
      this.appPrefer.setBookConfig(config)
    } catch (e) {
      // ignore
    }
  }

  aboutToDisappear(): void {
    display.off('change', this.screenDensityCallBack);
    this.bookCtrl.off('pageShow')
    this.bookCtrl.off('resourceRequest')
    this.bookCtrl.releaseBook()
    AppStorage.delete('bookCtrl')
    AppStorage.delete("boo_href")
    this.saveSetting()
  }

}