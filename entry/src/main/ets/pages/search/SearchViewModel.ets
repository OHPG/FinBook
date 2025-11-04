import { LoadType } from "@ohpg/fin-core";
import { ListViewModel } from "../../lifecycle/ListViewModel";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/11/28 21:14
 * @Version V1.0
 * @Description
 */
export class SearchViewModel extends ListViewModel {

  private readonly word: string

  constructor(context: Context, word: string) {
    super(context)
    this.word = word
  }

  async loadData(type: LoadType): Promise<void> {
    let page = await this.repository.search(this.word)
    this.dataSource.initData(page.items)
  }

}