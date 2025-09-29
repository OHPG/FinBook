import { LoadType } from "@ohpg/fin-core"
import { ListViewModel } from "../../lifecycle/ListViewModel"
import { MediaArgs } from "../detail/MediaArgs"

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/9/29 11:45
 * @Version V1.0
 * @Description: 
 */
export class GridViewModel extends ListViewModel {

  private readonly args: MediaArgs

  constructor(context: Context, args: MediaArgs) {
    super(context)
    this.args = args
  }

  /**
   * TODO 分页
   * @param type
   * @returns
   */
  async loadData(type?: LoadType): Promise<void> {
    let books = await this.repository.getBookList(this.args.id)
    this.dataSource.initData(books)
  }

}