import { FinItem } from "@ohpg/fin-core";
import { FinApi } from "@ohpg/fin-framework";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/9/15 21:53
 * @Version V1.0
 * @Description
 */
export interface FinBookApi extends FinApi {

  /**
   * 获取认证信息
   * @returns
   */
  getAuth(): string

  /**
   * 查询书籍列表
   * @returns
   */
  getBookList(id?: string): Promise<Array<FinItem>>

  /**
   * 查询书籍信息
   * @param id
   * @returns
   */
  getBook(id: string): Promise<FinItem>

  /**
   * 获取文件信息
   * @param id
   * @returns
   */
  getBookUrl(id: string): Promise<string>

  /**
   * 搜索书籍
   * @param keyword
   * @returns
   */
  searchMedia(keyword: string): Promise<Array<FinItem>>

  /**
   * 开始阅读
   * @param id
   * @returns
   */
  onPlaybackStart(id: string): Promise<void>

  /**
   * 更新进度
   * @param id
   * @param position
   * @param playing
   * @returns
   */
  onPlaybackProgress(id: string, position: number, playing: boolean): Promise<void>

  /**
   * 停止阅读
   * @param id
   * @param position
   * @returns
   */
  onPlaybackStopped(id: string, position: number): Promise<void>

}