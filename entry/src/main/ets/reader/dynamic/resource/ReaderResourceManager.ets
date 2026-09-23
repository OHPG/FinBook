import { ResourceResolver } from './ResourceResolver'

/**
 * 阅读器资源管理器（责任链）。
 *
 * 作为内核 resourceRequest 回调的统一入口：按注册顺序遍历各 {@link ResourceResolver}，
 * 第一个 canHandle 且 resolve 出字节的 resolver 命中即返回；全部未命中时返回空 ArrayBuffer，
 * 交由内核默认逻辑处理（与内核“返回空表示不接管”的约定一致）。
 *
 * 扩展新资源类型时，只需实现一个 ResourceResolver 并 register，无需改动内核回调本身。
 */
export class ReaderResourceManager {

  private readonly resolvers: ResourceResolver[] = []

  /**
   * 注册一个资源解析器。先注册者优先级更高。
   */
  public register(resolver: ResourceResolver): ReaderResourceManager {
    this.resolvers.push(resolver)
    return this
  }

  /**
   * 内核资源请求统一入口。
   * @param key 内核回调传入的资源标识
   * @returns 命中的资源字节；未命中返回空 ArrayBuffer
   */
  public request(key: string): ArrayBuffer {
    if (!key) {
      return new ArrayBuffer(0)
    }
    for (const resolver of this.resolvers) {
      if (!resolver.canHandle(key)) {
        continue
      }
      let buffer = resolver.resolve(key)
      if (buffer && buffer.byteLength > 0) {
        return buffer
      }
    }
    return new ArrayBuffer(0)
  }

}
