/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/8/7 22:14
 * @Version V1.0
 * @Description
 */
export interface FileInfo {

  name: string;

  href: string;

  contentType?: string;

  contentLength?: number;

  createTime?: string

  modifyTime?: string

  etag?: string

  isFolder?: boolean;

}