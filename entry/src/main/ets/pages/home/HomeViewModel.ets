import { LoadType } from "@ohpg/fin-core";
import { ListViewModel } from "../../lifecycle/ListViewModel";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/7 11:28
 * @Version V1.0
 * @Description
 */
export class HomeViewModel extends ListViewModel {

  /**
   * TODO 分页
   * @param type
   * @returns
   */
  async loadData(type?: LoadType): Promise<void> {
    let books = await this.repository.getBookList()
    this.dataSource.initData(books)
  }

}