import { BookItem } from "./BookItem"

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/7/19 18:37
 * @Version V1.0 文件夹元素
 * @Description
 */
export interface FolderItem {

  name: string

  /**
   * 别名
   */
  alias?: ResourceStr

  path: string

  items?: Array<BookItem>

}