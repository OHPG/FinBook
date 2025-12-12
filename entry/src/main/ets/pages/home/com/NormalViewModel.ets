import { BookItem } from "../../../entity/BookItem";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/12/12 20:59
 * @Version V1.0
 * @Description:
 */
export abstract class NormalViewModel {

  abstract loadByPath(path: string): Promise<Array<BookItem>>

  abstract removeData(path: string, dir?: boolean): Promise<void>

  abstract release(): Promise<void>

}