import { FinPage, LoadType } from "@ohpg/fin-core"
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

  private lastPage?: FinPage

  constructor(context: Context, args: MediaArgs) {
    super(context)
    this.args = args
  }

  hasMore(): boolean {
    return this.lastPage?.more ? true : false
  }

  /**
   * @param type
   * @returns
   */
  async loadData(type?: LoadType): Promise<void> {
    if (type !== "More") {
      this.lastPage = undefined
    }
    let page = await this.repository.getBookList(this.args.id
      , this.lastPage ? this.lastPage.cur + 1 : 0)
    if (type === "More") {
      this.dataSource.pushDataArray(page.items)
    } else {
      this.dataSource.initData(page.items)
    }
    this.lastPage = page
  }

}