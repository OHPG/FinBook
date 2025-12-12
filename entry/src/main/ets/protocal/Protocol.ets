import { FileInfo } from "./FileInfo"

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/9/5 17:37
 * @Version V1.0
 * @Description: 
 */
export interface Protocol {

  /**
   * 获取协议Header信息
   * @returns
   */
  getHeader(): Record<string, string> | undefined

  /**
   * 连接协议
   * @returns
   */
  connect(): Promise<void>

  /**
   * 列举文件列表
   * @param url
   * @returns
   */
  list(url: string): Promise<Array<FileInfo>>

  /**
   * 删除文件
   * @param url
   * @returns
   */
  delete(url: string, dir?: boolean): Promise<void>

  /**
   * 断开连接
   * @returns
   */
  disconnect(): Promise<void>

}