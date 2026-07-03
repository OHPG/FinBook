import { inputConsumer, KeyEvent as InputKeyEvent } from '@kit.InputKit';
import { KeyCode } from '@kit.InputKit';
import { UIContext } from '@kit.ArkUI';

export class VolumeKeyHelper {
  private volumeUpCallback?: (event: InputKeyEvent) => void
  private volumeDownCallback?: (event: InputKeyEvent) => void

  /**
   * 注册音量键翻页
   * @param uiContext   用于显示 toast
   * @param onPrevPage  上一页回调（音量+）
   * @param onNextPage  下一页回调（音量-）
   * @returns true 注册成功，false 设备不支持
   */
  register(uiContext: UIContext, onPrevPage: () => void, onNextPage: () => void): boolean {
    let volumeUpCb = (event: InputKeyEvent) => {
      onPrevPage()
    }
    let volumeDownCb = (event: InputKeyEvent) => {
      onNextPage()
    }
    try {
      inputConsumer.on('keyPressed', {
        key: KeyCode.KEYCODE_VOLUME_UP,
        action: 1,
        isRepeat: false
      }, volumeUpCb)
      inputConsumer.on('keyPressed', {
        key: KeyCode.KEYCODE_VOLUME_DOWN,
        action: 1,
        isRepeat: false
      }, volumeDownCb)
      this.volumeUpCallback = volumeUpCb
      this.volumeDownCallback = volumeDownCb
      return true
    } catch (e) {
      uiContext.getPromptAction().showToast({ message: $r('app.string.read_volume_key_not_supported') })
      return false
    }
  }

  /**
   * 注销音量键翻页
   */
  unregister(): void {
    if (this.volumeUpCallback) {
      inputConsumer.off('keyPressed', this.volumeUpCallback)
      this.volumeUpCallback = undefined
    }
    if (this.volumeDownCallback) {
      inputConsumer.off('keyPressed', this.volumeDownCallback)
      this.volumeDownCallback = undefined
    }
  }
}
