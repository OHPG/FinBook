import { window } from '@kit.ArkUI'
import { CommonConstants, ToolBar } from '@ohpg/fin-framework'
import { FileUtil } from '../../util/FileUtil'
import { PreferItem } from '../../widget/item/PreferItem'
import { groupAttributeModifier, itemDividerBuilder, windowAttributeModifier } from '../../style/Modifier'

@Entry
@Component
struct CachePage {

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @State localCopyCacheSize: string = ''

  @State downloadCacheSize: string = ''

  aboutToAppear(): void {
    this.refreshCacheSizes()
  }

  private refreshCacheSizes() {
    const context = this.getUIContext().getHostContext()!
    FileUtil.getLocalCopyCacheSize(context).then((size) => {
      this.localCopyCacheSize = FileUtil.formatFileSize(size)
    })
    FileUtil.getDownloadCacheSize(context).then((size) => {
      this.downloadCacheSize = FileUtil.formatFileSize(size)
    })
  }

  private showClearLocalCopyDialog() {
    this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.prefer_clear_local_copy_confirm_title'),
      message: $r('app.string.prefer_clear_local_copy_confirm_msg'),
      buttons: [
        { text: $r('app.string.prefer_clear_local_copy_cancel'), color: $r('sys.color.ohos_id_color_text_secondary') },
        { text: $r('app.string.prefer_clear_local_copy_confirm'), color: $r('sys.color.ohos_id_color_warning') }
      ]
    }).then((result) => {
      if (result.index === 1) {
        FileUtil.clearLocalCopyFiles(this.getUIContext().getHostContext()!).then(() => {
          this.getUIContext().getPromptAction().showToast({ message: $r('app.string.prefer_clear_local_copy_success') })
          this.refreshCacheSizes()
        })
      }
    })
  }

  private showClearDownloadCacheDialog() {
    this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.prefer_clear_local_copy_confirm_title'),
      message: $r('app.string.prefer_clear_download_cache_confirm_msg'),
      buttons: [
        { text: $r('app.string.prefer_clear_local_copy_cancel'), color: $r('sys.color.ohos_id_color_text_secondary') },
        { text: $r('app.string.prefer_clear_local_copy_confirm'), color: $r('sys.color.ohos_id_color_warning') }
      ]
    }).then((result) => {
      if (result.index === 1) {
        FileUtil.clearDownloadCacheFiles(this.getUIContext().getHostContext()!).then(() => {
          this.getUIContext().getPromptAction().showToast({ message: $r('app.string.prefer_clear_download_cache_success') })
          this.refreshCacheSizes()
        })
      }
    })
  }

  build() {
    Column({ space: CommonConstants.SPACE_8 }) {
      ToolBar({
        title: $r('app.string.prefer_cache_management'),
      })

      Scroll() {
        Column() {
          // 清理阅读缓存
          PreferItem({
            icon: $r('sys.symbol.trash'),
            title: $r('app.string.prefer_clear_local_copy'),
            tips: this.localCopyCacheSize,
            callback: () => {
              this.showClearLocalCopyDialog()
            }
          })

          itemDividerBuilder()

          // 清理下载缓存
          PreferItem({
            icon: $r('sys.symbol.arrow_down_circle'),
            title: $r('app.string.prefer_clear_download_cache'),
            tips: this.downloadCacheSize,
            callback: () => {
              this.showClearDownloadCacheDialog()
            }
          })
        }
        .attributeModifier(groupAttributeModifier)
      }
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Fade)
      .width(CommonConstants.FULL_PERCENT)
      .height('auto')
      .layoutWeight(1)
    }
    .padding({
      bottom: this.currentAvoidArea?.bottomRect.height
    })
    .attributeModifier(windowAttributeModifier)
  }
}
