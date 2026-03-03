import { LoadType } from "@ohpg/fin-core";
import { CategoryInfo } from "../../../entity/CategoryInfo";
import { ListViewModel } from "../../../lifecycle/ListViewModel";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/12/3 21:27
 * @Version V1.0
 * @Description
 */
export class OnlineViewModel extends ListViewModel {

  /**
   * @param type
   * @returns
   */
  async loadData(type?: LoadType): Promise<void> {
    let categoryArray = new Array<CategoryInfo>()
    let resumeItems = await this.repository.getResumeBooks()
    if (resumeItems && resumeItems.length > 0) {
      categoryArray.push({
        category: {
          id: "",
          name: "继续阅读"
        },
        items: resumeItems
      })
    }
    let newItems = await this.repository.getNewBooks()
    if (newItems && newItems.length > 0) {
      categoryArray.push({
        category: {
          id: "",
          name: "最近添加的书籍"
        },
        items: newItems
      })
    }
    let newSeries = await this.repository.getNewSeries()
    if (newSeries && newSeries.length > 0) {
      categoryArray.push({
        category: {
          id: "",
          name: "最近添加的系列"
        },
        items: newSeries
      })
    }
    let updateSeries = await this.repository.getUpdateSeries()
    if (updateSeries && updateSeries.length > 0) {
      categoryArray.push({
        category: {
          id: "",
          name: "最近更新的系列"
        },
        items: updateSeries
      })
    }
    this.dataSource.initData(categoryArray)
  }

}