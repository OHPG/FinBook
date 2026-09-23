import { FontManager } from '../entity/FontManager'
import { XUtil } from '../util/XUtil'
import { ResourceResolver } from './ResourceResolver'

/**
 * 字体资源解析器。
 *
 * 内核回调只传字体名（如 NotoSansCJK-Regular.ttf，扩展名被内核固定拼接为 .ttf，
 * 未必与真实文件一致），交由 {@link FontManager} 按基名忽略扩展名做匹配，
 * 在沙箱导入目录 / 系统预置目录中还原为真实绝对路径后读取字节。
 */
export class FontResourceResolver implements ResourceResolver {

  private readonly fontManager: FontManager

  constructor(fontManager: FontManager) {
    this.fontManager = fontManager
  }

  canHandle(key: string): boolean {
    return XUtil.isFont(key)
  }

  resolve(key: string): ArrayBuffer | undefined {
    let realPath = this.fontManager.resolveFontFileByName(key)
    if (!realPath) {
      return undefined
    }
    let buffer = XUtil.loadFileFromPath(realPath)
    return buffer.byteLength > 0 ? buffer : undefined
  }

}
