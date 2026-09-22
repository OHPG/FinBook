import { bookParser } from '@kit.ReaderKit';
import { readerCore } from "@kit.ReaderKit";
import { ReadPageComponent } from "@kit.ReaderKit";
import { CommonConstants } from "../../common/CommonConstants";
import { display } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { XMenuView } from './menu/XMenuView';
import { AppPrefer } from '../../prefer/AppPrefer';
import { VolumeKeyHelper } from '../VolumeKeyHelper';
import { FontManager } from './entity/FontManager';
import { XUtil } from './util/XUtil';
import fs from '@ohos.file.fs';

@Reusable
@Component
export struct DynamicReaderView {

  private appPrefer: AppPrefer = AppStorage.get(AppPrefer.PREFER)!

  private fontManager: FontManager = AppStorage.get(FontManager.MANAGER)!

  @Require @Prop bookPath: string = '';

  @State bookLoading: boolean = false;

  @Consume immersiveMode: boolean

  @Consume menuVisible: boolean

  @Consume bookChapter: number

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

  private volumeKeyHelper = new VolumeKeyHelper()

  aboutToAppear(): void {
    this.restoreConfig()
    this.registerScreenDensityChange()
    this.registerVolumeKeyListener()
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
        this.bookCtrl.setPageConfig(this.bookSetting)
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
    let config = this.appPrefer.getBookConfig()
    if (config) {
      this.bookSetting.fontName = config.fontName
      this.bookSetting.fontPath = this.resolveFontPath(config.fontPath)
      this.bookSetting.fontSize = config.fontSize
      this.bookSetting.fontColor = config.fontColor
      this.bookSetting.fontWeight = config.fontWeight
      this.bookSetting.lineHeight = config.lineHeight
      this.bookSetting.nightMode = config.nightMode
      this.bookSetting.themeColor = config.themeColor
      this.bookSetting.themeBgImg = config.themeBgImg
      this.bookSetting.flipMode = config.flipMode
    }
  }

  /**
   * 校验/迁移已保存的字体路径。
   * 旧版本可能保存了打包在 rawfile 的相对路径（fonts/xxx.ttf），
   * 或指向已被删除的沙盒字体。此时字体文件已不存在，回退为系统字体，避免阅读器加载失败。
   */
  private resolveFontPath(fontPath?: string): string {
    if (!fontPath) {
      return ''
    }
    try {
      // 仅接受存在的沙盒绝对路径字体
      let exists = fs.accessSync(fontPath, fs.AccessModeType.EXIST)
      if (exists) {
        return fontPath
      }
    } catch (e) {
      // ignore
    }
    // 尝试通过文件名在沙盒字体目录中重新定位（系统预置字体不做沙盒重定位）
    let matched = this.fontManager.findByFontPath(fontPath)
    if (matched && !matched.isSystem() && !matched.isPreset() && matched.fileName) {
      let sandboxPath = this.fontManager.getFontPath(matched.fileName)
      try {
        if (fs.accessSync(sandboxPath, fs.AccessModeType.EXIST)) {
          return sandboxPath
        }
      } catch (e) {
        // ignore
      }
    }
    // 字体不可用，回退系统字体
    this.bookSetting.fontName = FontManager.KEY_SYSTEM
    return ''
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
    // 注册资源请求回调：内核加载自定义字体（沙箱导入 / 系统预置）时，
    // 会通过该回调向应用索要字体文件字节。未注册则字体路径不生效、回退系统默认字体。
    // 必须在首次 setPageConfig（onSettingChange）之前注册。
    this.bookCtrl.on('resourceRequest', this.resourceRequest)
    this.onSettingChange()
    this.bookHandler = await bookParser.getDefaultHandler(this.bookPath)
    this.bookChapter = this.bookHandler.getCatalogList().length
    this.bookCtrl.registerBookParser(this.bookHandler)
  }

  /**
   * 内核资源请求回调。
   * 当阅读器需要加载自定义字体文件时触发，回调仅传入字体文件名（非完整路径），
   * 需先经 FontManager 还原为真实绝对路径（沙箱导入 / 系统预置），再读取字节返回。
   * 仅处理字体文件请求，其余资源返回空以交由内核默认逻辑处理。
   */
  private resourceRequest: bookParser.CallbackRes<string, ArrayBuffer> = (filePath: string): ArrayBuffer => {
    if (!filePath || !XUtil.isFont(filePath)) {
      return new ArrayBuffer(0)
    }
    let realPath = this.fontManager.resolveFontFileByName(filePath)
    if (!realPath) {
      return new ArrayBuffer(0)
    }
    return XUtil.loadFileFromPath(realPath)
  }

  private registerVolumeKeyListener() {
    if (!this.appPrefer.getVolumeKeyPageTurn()) return
    this.volumeKeyHelper.register(
      this.getUIContext(),
      () => { this.bookCtrl.flipPage(false) },
      () => { this.bookCtrl.flipPage(true) }
    )
  }

  private unregisterVolumeKeyListener() {
    this.volumeKeyHelper.unregister()
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
    this.appPrefer.setBookConfig(this.bookSetting)
  }

  aboutToDisappear(): void {
    this.unregisterVolumeKeyListener()
    display.off('change', this.screenDensityCallBack);
    this.bookCtrl.off('pageShow')
    this.bookCtrl.off('resourceRequest')
    this.bookCtrl.releaseBook()
    AppStorage.delete('bookCtrl')
    AppStorage.delete("boo_href")
    this.saveSetting()
  }

}