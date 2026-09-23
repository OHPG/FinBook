import fs from '@ohos.file.fs'
import { XUtil } from '../util/XUtil'

/**
 * 图片资源管理器
 *
 * 对称于 {@link FontManager}，统一管理阅读器主题背景图等图片资源：
 * - 内置背景图：随应用打包在 rawfile 下（如黑 / 白两张预置图），
 *   内核 resourceRequest 回调按文件名索要字节，经 resourceManager 从 rawfile 读取。
 * - 自定义背景图：用户导入到沙箱目录（filesDir/images）的图片，
 *   以“文件名 -> 沙箱绝对路径”注册，经 fs 读取。
 *
 * 内核回调传入的是形如 "white_sky_first.jpg" 的文件名（非完整路径），
 * 因此这里以“文件名”为 key 做精确匹配。
 */
export class ImageManager {

  public static readonly MANAGER = 'image_manager'

  /**
   * 沙箱自定义图片目录名
   */
  private static readonly IMAGES_DIR = 'images'

  /**
   * 内置背景图白名单（rawfile 下的文件名）。
   * 仅黑 / 白两张预置背景图；新增内置背景图在此登记即可。
   */
  private static readonly BUILTIN_BACKGROUNDS: string[] = [
    'white_sky_first.jpg',
    'dark_sky_first.jpg'
  ]

  private readonly context: Context

  /**
   * 自定义背景图注册表：文件名 -> 沙箱绝对路径。
   * 供后续自定义背景图功能在导入 / 恢复时登记，登记后内核回调即可命中。
   */
  private readonly customBackgrounds: Map<string, string> = new Map()

  constructor(context: Context) {
    this.context = context
  }

  /**
   * 沙箱自定义图片根目录
   */
  public getImagesDir(): string {
    return this.context.filesDir + '/' + ImageManager.IMAGES_DIR
  }

  /**
   * 根据图片文件名拼接沙箱绝对路径
   */
  public getImagePath(fileName: string): string {
    return this.getImagesDir() + '/' + fileName
  }

  /**
   * 是否为内置背景图（rawfile 打包，仅黑 / 白两张预置图）。
   */
  public isBuiltinBackground(fileName: string): boolean {
    let name = XUtil.fileName(fileName)
    return ImageManager.BUILTIN_BACKGROUNDS.indexOf(name) >= 0
  }

  /**
   * 是否为已注册的自定义背景图。
   */
  public isCustomBackground(fileName: string): boolean {
    return this.customBackgrounds.has(XUtil.fileName(fileName))
  }

  /**
   * 是否能作为背景图资源被本管理器接管（内置或已注册的自定义图）。
   */
  public canResolve(fileName: string): boolean {
    return this.isBuiltinBackground(fileName) || this.isCustomBackground(fileName)
  }

  /**
   * 注册一张自定义背景图。
   * @param fileName 文件名（内核回调将以此名索要）
   * @param absPath 沙箱绝对路径
   */
  public registerCustomBackground(fileName: string, absPath: string): void {
    let name = XUtil.fileName(fileName)
    if (!name || !absPath) {
      return
    }
    this.customBackgrounds.set(name, absPath)
  }

  /**
   * 注销一张自定义背景图。
   */
  public unregisterCustomBackground(fileName: string): void {
    this.customBackgrounds.delete(XUtil.fileName(fileName))
  }

  /**
   * 读取背景图字节。
   * 内置图经 resourceManager 从 rawfile 读取；自定义图经 fs 从沙箱绝对路径读取。
   * @returns 命中并成功读取时返回字节；未命中或失败返回 undefined。
   */
  public loadBackground(fileName: string): ArrayBuffer | undefined {
    let name = XUtil.fileName(fileName)
    if (this.isBuiltinBackground(name)) {
      return XUtil.loadFileFromAssets(this.context, name)
    }
    let customPath = this.customBackgrounds.get(name)
    if (customPath) {
      let buffer = XUtil.loadFileFromPath(customPath)
      return buffer.byteLength > 0 ? buffer : undefined
    }
    return undefined
  }

}
