/**
 * 字体信息
 *
 * 字体分为三类：
 * 1. 系统内置字体（system）：无需下载，fontPath 为空，直接使用系统默认字体。
 * 2. 内置可下载字体（builtin）：应用预置了标题和下载地址，但字体文件不打包进包体，
 *    需要用户手动下载到沙盒后才能使用，以此减小安装包体积。
 * 3. 用户导入字体（imported）：用户从设备中选择的本地字体文件，拷贝到沙盒。
 */
export enum FontType {
  /**
   * 系统字体
   */
  SYSTEM = 'system',

  /**
   * 内置可下载字体
   */
  BUILTIN = 'builtin',

  /**
   * 用户导入字体
   */
  IMPORTED = 'imported'
}

export class FontInfo {

  /**
   * 唯一标识（系统/内置字体使用固定 key，导入字体使用文件名或 md5）
   */
  key: string

  /**
   * 展示名称
   */
  name: string

  /**
   * 字体类型
   */
  type: FontType

  /**
   * 下载地址（仅内置可下载字体有值）
   */
  url: string

  /**
   * 沙盒中的字体文件名（system 为空）
   * 完整路径由 FontManager 根据字体根目录拼接得到，避免持久化绝对路径。
   */
  fileName: string

  constructor(key: string, name: string, type: FontType, url: string = '', fileName: string = '') {
    this.key = key
    this.name = name
    this.type = type
    this.url = url
    this.fileName = fileName
  }

  public isSystem(): boolean {
    return this.type === FontType.SYSTEM
  }

}
