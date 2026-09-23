/**
 * 阅读器内核资源解析器。
 *
 * 阅读器内核在需要外部资源（自定义字体、主题背景图等）时，会通过
 * ReaderComponentController 的 resourceRequest 回调按“文件名 / key”向应用索要字节。
 * 每一类资源实现一个 ResourceResolver，自行封装“能否处理”与“如何还原并读取字节”，
 * 由 {@link ReaderResourceManager} 以责任链方式派发，命中即返回。
 *
 * 之所以用责任链而非扁平的 name→path 表：不同资源的匹配规则差异很大
 * （字体需忽略扩展名做模糊基名匹配并跨目录扫描，背景图按精确名匹配且区分
 * rawfile / 沙箱两种读取方式），责任链能把各自的特殊逻辑收敛在对应 resolver 内。
 */
export interface ResourceResolver {

  /**
   * 是否能处理该资源请求。
   * @param key 内核回调传入的资源标识（通常为文件名，可能带内核固定拼接的后缀）
   */
  canHandle(key: string): boolean

  /**
   * 解析并读取资源字节。
   * @param key 内核回调传入的资源标识
   * @returns 命中并成功读取时返回字节；无法解析 / 读取失败返回 undefined，交由后续 resolver 处理
   */
  resolve(key: string): ArrayBuffer | undefined

}
