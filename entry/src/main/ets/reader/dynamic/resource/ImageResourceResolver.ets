import { ImageManager } from '../entity/ImageManager'
import { ResourceResolver } from './ResourceResolver'

/**
 * 图片资源解析器。
 *
 * 承载主题背景图请求，交由 {@link ImageManager} 处理：
 * 内置背景图（rawfile 打包的黑 / 白两张预置图）与已注册的自定义背景图（沙箱路径）。
 */
export class ImageResourceResolver implements ResourceResolver {

  private readonly imageManager: ImageManager

  constructor(imageManager: ImageManager) {
    this.imageManager = imageManager
  }

  canHandle(key: string): boolean {
    return this.imageManager.canResolve(key)
  }

  resolve(key: string): ArrayBuffer | undefined {
    return this.imageManager.loadBackground(key)
  }

}
