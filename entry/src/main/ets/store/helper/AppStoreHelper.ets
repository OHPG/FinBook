import { StoreHelper } from "@ohpg/fin-core"
import { relationalStore } from "@kit.ArkData"
import { BookHistoryTable } from "../table/BookHistoryTable"
import { StorageInfoTable } from "../table/StorageInfoTable"
import BuildProfile from "BuildProfile"

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/12/4 20:08
 * @Version V1.0
 * @Description
 */
export class AppStoreHelper extends StoreHelper {

  constructor(context: Context) {
    super(context, 2, {
        name: "fin_book.db",
        securityLevel: relationalStore.SecurityLevel.S1,
        encrypt: !BuildProfile.DEBUG
      })
  }

  protected async onCreate(store: relationalStore.RdbStore): Promise<void> {
    try {
      await store.executeSql(BookHistoryTable.CREATE_SQL)
    } catch (e) {
      console.error("AppStoreHelper " + JSON.stringify(e))
    }
  }

  protected async onUpgrade(store: relationalStore.RdbStore, oldVersion: number, newVersion: number): Promise<void> {
    switch (oldVersion) {
      case 1:
        await store.executeSql(StorageInfoTable.CREATE_SQL)
    }
  }

}