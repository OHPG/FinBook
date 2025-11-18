import { BookType } from "../enum/BookType"

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/9/29 11:00
 * @Version V1.0
 * @Description: 
 */
export interface FinBookRawSource {

  id: string

  progress: number

  name: string

  path: string

  type: BookType

}