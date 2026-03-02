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
    let resumeItems = await this.repository.getResumeItems()
    let newItems = await this.repository.getNewItems()
    let newSeries = await this.repository.getNewSeries()
    let updateSeries = await this.repository.getUpdateSeries()
    this.dataSource.initData(categoryArray)
  }

}