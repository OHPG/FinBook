export interface BookHistory {

  /**
   * id
   */
  id: string

  /**
   * 文件路径或者url
   */
  source: string

  /**
   * 时间戳
   */
  time: number

  /**
   * 总页数
   */
  pages: number

  /**
   * 当前进度
   */
  page: number

  /**
   * 附加（给epub等做辅助）
   */
  extra?: Record<string, string | number | boolean>

}