import { util } from "@kit.ArkTS"
import { LoadType, MD5 } from "@ohpg/fin-core"
import { BookItem } from "../../entity/BookItem"
import { AppDataStore } from "../../store/AppDataStore"
import { AppThumb } from "../../thumb/AppThumb"
import { StringUtil } from "../../util/StringUtil"
import { ListViewModel } from "../../lifecycle/ListViewModel"

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2026/3/5 21:15
 * @Version V1.0
 * @Description
 */
export class HistoryViewModel extends ListViewModel {

  private readonly thumb: AppThumb

  private readonly dataStore: AppDataStore

  constructor(context: Context) {
    super(context)
    this.thumb = AppStorage.get(AppThumb.THUMB)!
    this.dataStore = AppStorage.get(AppDataStore.APP_DATA_STORE)!
  }

  public async loadData(type: LoadType): Promise<void> {
    let historyArray = await this.dataStore.queryBookHistory()
    if (!historyArray || historyArray.length <= 0) return undefined
    let bookArray = new Array<BookItem>()
    for (const history of historyArray) {
      bookArray.push({
        id: history.id,
        key: util.generateRandomUUID(true),
        name: StringUtil.extractFileName(history.source) || "",
        uri: history.source,
        thumb: await this.thumb.keyToThumb(history.id),
        date: StringUtil.formatTimestamp(history.time / 1000),
        history: history
      })
    }
    this.dataSource.pushDataArray(bookArray)
  }

  public async deleteData(book: BookItem): Promise<void> {
    await this.dataStore.deleteBookHistoryById(book.id)
    let bookArray: Array<BookItem> = this.dataSource.getDataAll() as ESObject
    let index = bookArray.findIndex((item) => item.id === book.id)
    if (index >= 0) {
      this.dataSource.deleteData(index)
    }
  }

}