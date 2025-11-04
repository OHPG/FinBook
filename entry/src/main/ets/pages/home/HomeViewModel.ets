import { LoadType } from "@ohpg/fin-core";
import { CategoryInfo } from "../../entity/CategoryInfo";
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
   * @param type
   * @returns
   */
  async loadData(type?: LoadType): Promise<void> {
    let categoryArray = new Array<CategoryInfo>()
    let normalItems = await this.repository.getLibraryList()
    if (normalItems) {
      for (let item of normalItems) {
        let items = await this.repository.getBookList(item.id)
        if (items && items.length > 0) {
          categoryArray.push({
            category: item,
            items: items
          })
        }
      }
    }
    this.dataSource.initData(categoryArray)
  }

}