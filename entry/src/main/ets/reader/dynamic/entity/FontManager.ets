import fs from '@ohos.file.fs'
import { fileUri, picker } from '@kit.CoreFileKit'
import { readerCore } from '@kit.ReaderKit'
import { AppPrefer } from '../../../prefer/AppPrefer'
import { FontInfo, FontType } from './FontInfo'
import { XUtil } from '../util/XUtil'

/**
 * 字体管理器
 *
 * 负责管理阅读器可用字体：
 * - 系统字体（无需文件）
 * - 用户导入字体（从设备选择拷贝到沙盒 filesDir/fonts 目录）
 *
 * 不使用任何元数据库，导入字体以沙盒 fonts 目录为唯一真实来源：
 * 列表即扫描该目录下的字体文件，名称取文件名（去后缀）。
 * 阅读器使用字体文件的绝对沙盒路径作为 fontPath。
 */
export class FontManager {

  public static readonly MANAGER = 'font_manager'

  /**
   * 系统默认字体 key
   */
  public static readonly KEY_SYSTEM = 'system'

  /**
   * 沙盒字体目录名
   */
  private static readonly FONTS_DIR = 'fonts'

  private readonly context: Context

  private readonly appPrefer: AppPrefer

  constructor(context: Context, appPrefer: AppPrefer) {
    this.context = context
    this.appPrefer = appPrefer
  }

  /**
   * 沙盒字体根目录
   */
  public getFontsDir(): string {
    return this.context.filesDir + '/' + FontManager.FONTS_DIR
  }

  /**
   * 根据字体文件名拼接沙盒绝对路径
   */
  public getFontPath(fileName: string): string {
    return this.getFontsDir() + '/' + fileName
  }

  /**
   * 系统字体
   */
  public getSystemFont(): FontInfo {
    return new FontInfo(FontManager.KEY_SYSTEM, this.getSystemFontName(), FontType.SYSTEM)
  }

  private getSystemFontName(): string {
    try {
      return this.context.resourceManager.getStringByNameSync('system_font')
    } catch (e) {
      return '系统字体'
    }
  }

  /**
   * 全部字体列表（系统字体 + 导入字体）
   */
  public getAllFonts(): FontInfo[] {
    let list: FontInfo[] = [this.getSystemFont()]
    list = list.concat(this.getImportedFonts())
    return list
  }

  /**
   * 扫描沙盒 fonts 目录，得到用户导入的字体列表。
   * 以目录内容为唯一来源，无需任何元数据存储。
   */
  public getImportedFonts(): FontInfo[] {
    let dir = this.getFontsDir()
    let result: FontInfo[] = []
    try {
      let stat = fs.statSync(dir)
      if (!stat.isDirectory()) {
        return result
      }
    } catch (e) {
      // 目录不存在
      return result
    }
    let files: string[] = []
    try {
      files = fs.listFileSync(dir)
    } catch (e) {
      return result
    }
    for (const name of files) {
      if (!XUtil.isFont(name)) {
        continue
      }
      result.push(new FontInfo(name, this.displayName(name), FontType.IMPORTED, '', name))
    }
    return result
  }

  /**
   * 当前正在使用的字体（根据阅读配置中的 fontPath 判断）
   */
  public getCurrentFont(): FontInfo {
    let config = this.appPrefer.getBookConfig()
    let fontPath = config ? config.fontPath : ''
    let matched = this.findByFontPath(fontPath)
    return matched ?? this.getSystemFont()
  }

  /**
   * 判断某字体是否为当前正在使用的字体
   */
  public isCurrentFont(font: FontInfo): boolean {
    let current = this.getCurrentFont()
    return current.key === font.key
  }

  /**
   * 将某字体设为当前使用字体，并持久化到阅读配置。
   * @returns 是否设置成功
   */
  public setCurrentFont(font: FontInfo): boolean {
    let config = this.appPrefer.getBookConfig() ?? FontManager.defaultReaderSetting()
    if (font.isSystem()) {
      config.fontName = FontManager.KEY_SYSTEM
      config.fontPath = ''
    } else {
      config.fontName = font.name
      config.fontPath = this.getFontPath(font.fileName)
    }
    this.appPrefer.setBookConfig(config)
    return true
  }

  private async fileExists(path: string): Promise<boolean> {
    try {
      return await fs.access(path, fs.AccessModeType.EXIST)
    } catch (e) {
      return false
    }
  }

  private async ensureFontsDir(): Promise<string> {
    let dir = this.getFontsDir()
    let exist = await this.fileExists(dir)
    if (!exist) {
      await fs.mkdir(dir)
    }
    return dir
  }

  /**
   * 从设备导入字体文件到沙盒
   * @returns 导入的字体信息；用户取消或选择非字体文件时返回 undefined
   */
  public async importFont(): Promise<FontInfo | undefined> {
    // 拉起系统文件管理器，仅筛选字体文件
    // 注意：fileSuffixFilters 使用不带点的纯后缀（与 select() 的过滤匹配保持一致）
    let options = new picker.DocumentSelectOptions()
    options.maxSelectNumber = 1
    options.fileSuffixFilters = ['ttf', 'otf', 'ttc']
    let documentPicker = new picker.DocumentViewPicker()
    let selectResult: string[] = await documentPicker.select(options)
    if (!selectResult || selectResult.length === 0) {
      return undefined
    }
    let srcUri = selectResult[0]
    // 从 uri 中提取文件名（去掉可能存在的 query 部分）
    let rawName = this.getFileName(new fileUri.FileUri(srcUri).name || this.getFileName(srcUri))
    let queryIndex = rawName.indexOf('?')
    if (queryIndex >= 0) {
      rawName = rawName.substring(0, queryIndex)
    }
    if (!XUtil.isFont(rawName)) {
      throw new Error('Not a font file.')
    }
    let dir = await this.ensureFontsDir()
    let fileName = rawName
    let destPath = dir + '/' + fileName
    // 若已存在同名文件，追加时间戳避免覆盖
    if (await this.fileExists(destPath)) {
      let dotIndex = fileName.lastIndexOf('.')
      let base = dotIndex >= 0 ? fileName.substring(0, dotIndex) : fileName
      let suffix = dotIndex >= 0 ? fileName.substring(dotIndex) : ''
      fileName = `${base}_${Date.now()}${suffix}`
      destPath = dir + '/' + fileName
    }
    // picker 返回的是虚拟 uri（非真实文件系统路径），fs.copyFile 不支持直接传 uri 字符串作为源，
    // 必须先 fs.open 该 uri 拿到 fd，再用 fd 进行拷贝，这是官方推荐的沙盒外文件读取方式。
    let srcFile = await fs.open(srcUri, fs.OpenMode.READ_ONLY)
    try {
      await fs.copyFile(srcFile.fd, destPath)
    } finally {
      await fs.close(srcFile.fd)
    }
    return new FontInfo(fileName, this.displayName(fileName), FontType.IMPORTED, '', fileName)
  }

  /**
   * 删除字体（删除沙盒文件）
   * 系统字体和正在使用的字体不允许删除。
   * @returns 是否删除成功
   */
  public async deleteFont(font: FontInfo): Promise<boolean> {
    if (font.isSystem()) {
      return false
    }
    if (this.isCurrentFont(font)) {
      return false
    }
    if (font.fileName) {
      let path = this.getFontPath(font.fileName)
      if (await this.fileExists(path)) {
        await fs.unlink(path)
      }
    }
    return true
  }

  /**
   * 清理所有导入的字体（保留系统字体，且跳过当前正在使用的字体）
   */
  public async clearAllFonts(): Promise<void> {
    let current = this.getCurrentFont()
    // 当前使用字体对应的沙盒文件名，需保留
    let keepFileName = current.isSystem() ? '' : current.fileName
    let dir = this.getFontsDir()
    if (await this.fileExists(dir)) {
      let files = fs.listFileSync(dir)
      for (const name of files) {
        if (keepFileName && name === keepFileName) {
          continue
        }
        try {
          await fs.unlink(dir + '/' + name)
        } catch (e) {
          // ignore
        }
      }
    }
  }

  /**
   * 计算字体目录占用大小（字节）
   */
  public async getFontsSize(): Promise<number> {
    let dir = this.getFontsDir()
    if (!(await this.fileExists(dir))) {
      return 0
    }
    let total = 0
    let files = fs.listFileSync(dir)
    for (const name of files) {
      try {
        let stat = fs.statSync(dir + '/' + name)
        if (!stat.isDirectory()) {
          total += stat.size
        }
      } catch (e) {
        // ignore
      }
    }
    return total
  }

  /**
   * 根据字体的持久化 fontPath 找到对应字体信息（用于回显选中态）
   * 兼容旧版本保存的 rawfile 相对路径（fonts/xxx.ttf）。
   */
  public findByFontPath(fontPath: string): FontInfo | undefined {
    if (!fontPath) {
      return this.getSystemFont()
    }
    let all = this.getAllFonts()
    for (const font of all) {
      if (font.isSystem()) {
        continue
      }
      if (fontPath === this.getFontPath(font.fileName)) {
        return font
      }
      // 兼容旧的 rawfile 相对路径写法
      if (font.fileName && fontPath.endsWith(font.fileName)) {
        return font
      }
    }
    return undefined
  }

  private getFileName(path: string): string {
    let index = path.lastIndexOf('/')
    if (index >= 0) {
      return path.substring(index + 1)
    }
    return path
  }

  /**
   * 文件名转展示名（去掉扩展名）
   */
  private displayName(fileName: string): string {
    let name = this.getFileName(fileName)
    let dotIndex = name.lastIndexOf('.')
    if (dotIndex > 0) {
      return name.substring(0, dotIndex)
    }
    return name
  }

  /**
   * 构造一份默认阅读配置。
   * 仅用于用户尚未进入过阅读器、但先在字体管理页设置字体的场景。
   * scaledDensity / viewPort 等运行时字段会在阅读器打开时被实际值覆盖。
   */
  private static defaultReaderSetting(): readerCore.ReaderSetting {
    return {
      fontName: FontManager.KEY_SYSTEM,
      fontPath: '',
      fontSize: 16,
      fontColor: '#000000',
      fontWeight: 400,
      lineHeight: 1.4,
      nightMode: false,
      themeColor: 'rgba(248, 249, 250, 1)',
      themeBgImg: '',
      flipMode: '0',
      scaledDensity: 1,
      viewPortWidth: 0,
      viewPortHeight: 0
    }
  }

}
