import { StoreHelper } from "@ohpg/fin-core";
import { AppStoreHelper } from "./helper/AppStoreHelper";
import { BookHistoryTable } from "./table/BookHistoryTable";
import { relationalStore } from "@kit.ArkData";
import { BookHistory } from "../entity/BookHistory";
import { StorageInfoTable } from "./table/StorageInfoTable";
import { StorageInfo } from "../entity/StorageInfo";
import { ProtocolType } from "../enum/ProtocolType";
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

  /**
   * 查询存储
   * @returns
   */
  public async queryStorage(id: string): Promise<StorageInfo | undefined> {
    let store = await this.storeHelper.getWritableStore()
    let rdbPredicates = new relationalStore.RdbPredicates(StorageInfoTable.TABLE_NAME)
    rdbPredicates.equalTo(StorageInfoTable.ID, id)
    let resultSet = await store.query(rdbPredicates)
    if (resultSet.rowCount <= 0 || !resultSet.goToFirstRow()) {
      return undefined
    }
    let idIndex = resultSet.getColumnIndex(StorageInfoTable.ID)
    let typeIndex = resultSet.getColumnIndex(StorageInfoTable.TYPE)
    let nameIndex = resultSet.getColumnIndex(StorageInfoTable.NAME)
    let urlIndex = resultSet.getColumnIndex(StorageInfoTable.URL)
    let authIndex = resultSet.getColumnIndex(StorageInfoTable.AUTH_TYPE)
    let authNameIndex = resultSet.getColumnIndex(StorageInfoTable.AUTH_NAME)
    let authPswIndex = resultSet.getColumnIndex(StorageInfoTable.AUTH_PSW)
    let extraIndex = resultSet.getColumnIndex(StorageInfoTable.EXTRA)
    let timeIndex = resultSet.getColumnIndex(StorageInfoTable.TIME)
    let storageInfo: StorageInfo = {
      id: resultSet.getString(idIndex),
      type: resultSet.getString(typeIndex) as ProtocolType,
      name: resultSet.getString(nameIndex),
      url: resultSet.getString(urlIndex),
      authType: resultSet.getString(authIndex),
      authName: resultSet.getString(authNameIndex),
      authPsw: resultSet.getString(authPswIndex),
      time: resultSet.getLong(timeIndex),
    }
    let extra = resultSet.getString(extraIndex)
    if (extra && extra.length > 0) {
      try {
        storageInfo.extra = JSON.parse(extra)
      } catch (error) {
        if (BuildProfile.DEBUG) {
          console.error("AppDataStore: queryStorage, parse extra error: " + extra)
        }
      }
    }
    return storageInfo
  }

  /**
   * 查询所有存储
   * @returns
   */
  public async queryAllStorage(): Promise<Array<StorageInfo> | undefined> {
    let store = await this.storeHelper.getWritableStore()
    let rdbPredicates = new relationalStore.RdbPredicates(StorageInfoTable.TABLE_NAME)
    rdbPredicates.orderByAsc(StorageInfoTable.NAME)
    let resultSet = await store.query(rdbPredicates)
    if (resultSet.rowCount <= 0 || !resultSet.goToFirstRow()) {
      return undefined
    }
    let idIndex = resultSet.getColumnIndex(StorageInfoTable.ID)
    let typeIndex = resultSet.getColumnIndex(StorageInfoTable.TYPE)
    let nameIndex = resultSet.getColumnIndex(StorageInfoTable.NAME)
    let urlIndex = resultSet.getColumnIndex(StorageInfoTable.URL)
    let authIndex = resultSet.getColumnIndex(StorageInfoTable.AUTH_TYPE)
    let authNameIndex = resultSet.getColumnIndex(StorageInfoTable.AUTH_NAME)
    let authPswIndex = resultSet.getColumnIndex(StorageInfoTable.AUTH_PSW)
    let extraIndex = resultSet.getColumnIndex(StorageInfoTable.EXTRA)
    let timeIndex = resultSet.getColumnIndex(StorageInfoTable.TIME)
    let storageInfoArray: Array<StorageInfo> = new Array<StorageInfo>()
    do {
      let storageInfo: StorageInfo = {
        id: resultSet.getString(idIndex),
        type: resultSet.getString(typeIndex) as ProtocolType,
        name: resultSet.getString(nameIndex),
        url: resultSet.getString(urlIndex),
        authType: resultSet.getString(authIndex),
        authName: resultSet.getString(authNameIndex),
        authPsw: resultSet.getString(authPswIndex),
        time: resultSet.getLong(timeIndex),
      }
      let extra = resultSet.getString(extraIndex)
      if (extra && extra.length > 0) {
        try {
          storageInfo.extra = JSON.parse(extra)
        } catch (error) {
          if (BuildProfile.DEBUG) {
            console.error("AppDataStore: queryAllStorage, parse extra error: " + extra)
          }
        }
      }
      storageInfoArray.push(storageInfo)
    } while (resultSet.goToNextRow())
    return storageInfoArray
  }

  /**
   * 插入存储
   * @param entity
   * @returns
   */
  public async insertStorageInfo(entity: StorageInfo): Promise<void> {
    let store = await this.storeHelper.getWritableStore()
    let value: relationalStore.ValuesBucket = {}
    value[StorageInfoTable.ID] = entity.id
    value[StorageInfoTable.TYPE] = entity.type
    value[StorageInfoTable.NAME] = entity.name
    value[StorageInfoTable.URL] = entity.url
    value[StorageInfoTable.AUTH_TYPE] = entity.authType
    if (entity.authName) {
      value[StorageInfoTable.AUTH_NAME] = entity.authName
    }
    if (entity.authPsw) {
      value[StorageInfoTable.AUTH_PSW] = entity.authPsw
    }
    if (entity.extra) {
      value[StorageInfoTable.EXTRA] = JSON.stringify(entity.extra)
    }
    value[StorageInfoTable.TIME] = Date.now()
    let col = await store.insert(StorageInfoTable.TABLE_NAME
      , value, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
    if (BuildProfile.DEBUG) {
      console.log("AppDataStore insertStorageInfo col = " + col)
    }
  }

  /**
   * 删除存储
   * @param id
   * @returns
   */
  public async deleteStorageInfo(id: string): Promise<boolean> {
    let store = await this.storeHelper.getWritableStore()
    let predicates = new relationalStore.RdbPredicates(StorageInfoTable.TABLE_NAME)
    predicates.equalTo(StorageInfoTable.ID, id)
    let line = await store.delete(predicates)
    return line > 0
  }

  /**
   * 根据id查询电子书的阅读记录
   * @param id 电子书id
   * @returns
   */
  public async queryBookHistory(id: string): Promise<BookHistory | undefined> {
    let store = await this.storeHelper.getWritableStore()
    let rdbPredicates = new relationalStore.RdbPredicates(BookHistoryTable.TABLE_NAME)
    rdbPredicates.equalTo(BookHistoryTable.ID, id)
    let resultSet = await store.query(rdbPredicates)
    if (resultSet.rowCount <= 0 || !resultSet.goToFirstRow()) {
      return undefined
    }
    let idIndex = resultSet.getColumnIndex(BookHistoryTable.ID)
    let sourceIndex = resultSet.getColumnIndex(BookHistoryTable.SOURCE)
    let timeIndex = resultSet.getColumnIndex(BookHistoryTable.TIME)
    let pagesIndex = resultSet.getColumnIndex(BookHistoryTable.PAGES)
    let pageIndex = resultSet.getColumnIndex(BookHistoryTable.PAGE)
    let extraIndex = resultSet.getColumnIndex(BookHistoryTable.EXTRA)
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
          console.error("AppDataStore: queryBookHistory, parse extra error: " + JSON.stringify(error))
        }
      }
    }
    return bookHistory
  }

  public async queryAllBookHistory(ids: Array<string>): Promise<Array<BookHistory> | undefined> {
    let store = await this.storeHelper.getWritableStore()
    let rdbPredicates = new relationalStore.RdbPredicates(BookHistoryTable.TABLE_NAME)
    rdbPredicates.in(BookHistoryTable.ID, ids)
    let resultSet = await store.query(rdbPredicates)
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
            console.error("AppDataStore: queryAllBookHistory, parse extra error: " + JSON.stringify(error))
          }
        }
      }
      bookHistoryArray.push(bookHistory)
    } while (resultSet.goToNextRow())
    return bookHistoryArray
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

}