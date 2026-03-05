import { StoreHelper } from "@ohpg/fin-core";
import { AppStoreHelper } from "./helper/AppStoreHelper";
import { BookHistoryTable } from "./table/BookHistoryTable";
import { relationalStore } from "@kit.ArkData";
import { BookHistory } from "../entity/BookHistory";
import BuildProfile from "BuildProfile";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/12/4 20:38
 * @Version V1.0
 * @Description:
 */
export class AppDataStore {

  public static readonly APP_DATA_STORE = "app_data_store"

  private readonly context: Context

  private readonly storeHelper: StoreHelper

  constructor(context: Context) {
    this.context = context
    this.storeHelper = new AppStoreHelper(context)
  }

  private static convertBookHistory(resultSet: relationalStore.ResultSet): Array<BookHistory> | undefined {
    try {
      if (resultSet.rowCount <= 0 || !resultSet.goToFirstRow()) {
        return undefined
      }
      let idIndex = resultSet.getColumnIndex(BookHistoryTable.ID)
      let sourceIndex = resultSet.getColumnIndex(BookHistoryTable.SOURCE)
      let timeIndex = resultSet.getColumnIndex(BookHistoryTable.TIME)
      let pagesIndex = resultSet.getColumnIndex(BookHistoryTable.PAGES)
      let pageIndex = resultSet.getColumnIndex(BookHistoryTable.PAGE)
      let extraIndex = resultSet.getColumnIndex(BookHistoryTable.EXTRA)
      let bookHistoryArray: Array<BookHistory> = new Array<BookHistory>()
      do {
        let bookHistory: BookHistory = {
          id: resultSet.getString(idIndex),
          source: resultSet.getString(sourceIndex),
          time: resultSet.getLong(timeIndex),
          pages: resultSet.getLong(pagesIndex),
          page: resultSet.getLong(pageIndex)
        }
        let extra = resultSet.getString(extraIndex)
        if (extra && extra.length > 0) {
          try {
            bookHistory.extra = JSON.parse(extra)
          } catch (error) {
            if (BuildProfile.DEBUG) {
              console.error("AppDataStore: convertBookHistory, parse extra error: " + JSON.stringify(error))
            }
          }
        }
        bookHistoryArray.push(bookHistory)
      } while (resultSet.goToNextRow())
      return bookHistoryArray
    } finally {
      resultSet.close()
    }
  }

  /**
   * 查询电子书的阅读记录
   * @returns
   */
  public async queryBookHistory(): Promise<Array<BookHistory> | undefined> {
    let store = await this.storeHelper.getWritableStore()
    let rdbPredicates = new relationalStore.RdbPredicates(BookHistoryTable.TABLE_NAME)
    rdbPredicates.orderByDesc(BookHistoryTable.TIME)
    let resultSet = await store.query(rdbPredicates)
    return AppDataStore.convertBookHistory(resultSet)
  }

  /**
   * 根据id查询电子书的阅读记录
   * @param id 电子书id
   * @returns
   */
  public async queryBookHistoryById(id: string): Promise<BookHistory | undefined> {
    let store = await this.storeHelper.getWritableStore()
    let rdbPredicates = new relationalStore.RdbPredicates(BookHistoryTable.TABLE_NAME)
    rdbPredicates.equalTo(BookHistoryTable.ID, id)
    let resultSet = await store.query(rdbPredicates)
    let bookHistoryArray = AppDataStore.convertBookHistory(resultSet)
    return bookHistoryArray && bookHistoryArray.length > 0 ? bookHistoryArray[0] : undefined
  }

  public async queryBookHistoryByIds(ids: Array<string>): Promise<Array<BookHistory> | undefined> {
    let store = await this.storeHelper.getWritableStore()
    let rdbPredicates = new relationalStore.RdbPredicates(BookHistoryTable.TABLE_NAME)
    rdbPredicates.in(BookHistoryTable.ID, ids)
    let resultSet = await store.query(rdbPredicates)
    return AppDataStore.convertBookHistory(resultSet)
  }

  /**
   * 插入电子书记录
   * @param entity
   * @returns
   */
  public async insertBookHistory(entity: BookHistory): Promise<void> {
    let store = await this.storeHelper.getWritableStore()
    let value: relationalStore.ValuesBucket = {}
    value[BookHistoryTable.ID] = entity.id
    value[BookHistoryTable.SOURCE] = entity.source
    value[BookHistoryTable.TIME] = entity.time
    value[BookHistoryTable.PAGES] = entity.pages
    value[BookHistoryTable.PAGE] = entity.page
    if (entity.extra) {
      value[BookHistoryTable.EXTRA] = JSON.stringify(entity.extra)
    }
    let col = await store.insert(BookHistoryTable.TABLE_NAME
      , value, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
    if (BuildProfile.DEBUG) {
      console.log("AppDataStore insertBookHistory col = " + col)
    }
  }

  public async deleteBookHistoryById(id: string): Promise<void> {
    let store = await this.storeHelper.getWritableStore()
    let predicates = new relationalStore.RdbPredicates(BookHistoryTable.TABLE_NAME)
    predicates.equalTo(BookHistoryTable.ID, id)
    let col = await store.delete(predicates)
    if (BuildProfile.DEBUG) {
      console.log("AppDataStore deleteBookHistory col = " + col)
    }
  }
}