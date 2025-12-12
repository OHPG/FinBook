import { ProtocolType } from "../enum/ProtocolType"

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/10/14 22:26
 * @Version V1.0
 * @Description
 */
export interface StorageInfo {

  /**
   * id
   */
  id: string

  /**
   * 类型（dav，smb）
   */
  type: ProtocolType

  /**
   * 名称
   */
  name: string

  /**
   * url
   */
  url: string

  /**
   * 认证类型
   */
  authType: string

  /**
   * 认证用户名
   */
  authName?: string

  /**
   * 认证密码
   */
  authPsw?: string

  /**
   * 附加数据
   */
  extra?: Record<string, string | number | boolean>

  /**
   * 创建时间戳
   */
  time: number

}