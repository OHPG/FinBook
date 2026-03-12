import { preferences } from "@kit.ArkData"
import { BookOrientation } from "../enum/BookOrientation"
import { readerCore } from "@kit.ReaderKit"
import { FinPageSize } from "@ohpg/fin-core"
import { FinSortBy, FinSortOrder } from "@ohpg/fin-core"

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/11/9 18:36
 * @Version V1.0
 * @Description
 */
export class AppPrefer {

  public static readonly PREFER = "prefer"

  private static readonly KEY_PRIVACY_GRANT = "privacy_grant"

  private static readonly KEY_BOOK_X_CONFIG = "book_x_config"

  private static readonly KEY_BOOK_ORIENTATION = "book_orientation"

  private static readonly KEY_LIST_SORT_DIR = "list_sort_dir"

  private static readonly KEY_LIST_SORT_BY = "list_sort_by"

  private static readonly KEY_LIST_SORT_ORDER = "list_sort_order"

  private static readonly KEY_BOOK_PAGE_SIZE = "book_page_size"

  private static readonly KEY_HOME_TAB_INDEX = "home_tab_index"

  private readonly preference: preferences.Preferences

  constructor(context: Context) {
    this.preference = preferences.getPreferencesSync(context, { name: "app_prefer" } )
  }

  public isPrivacyGrant(): boolean {
    if (this.preference.hasSync(AppPrefer.KEY_PRIVACY_GRANT)) {
      return this.preference.getSync(AppPrefer.KEY_PRIVACY_GRANT, false) as boolean
    }
    return false
  }

  public setPrivacyGrant(): void {
    this.preference.putSync(AppPrefer.KEY_PRIVACY_GRANT, true)
    this.preference.flush()
  }

  public getBookConfig(): readerCore.ReaderSetting | undefined {
    if (this.preference.hasSync(AppPrefer.KEY_BOOK_X_CONFIG)) {
      let json = this.preference.getSync(AppPrefer.KEY_BOOK_X_CONFIG, undefined)
      if (json) {
        try {
          return JSON.parse(json as string) as readerCore.ReaderSetting
        } catch (e) {
          this.preference.deleteSync(AppPrefer.KEY_BOOK_X_CONFIG)
        }
      }
    }
    return undefined
  }

  public setBookConfig(config: readerCore.ReaderSetting): void {
    try {
      let json = JSON.stringify(config)
      this.preference.putSync(AppPrefer.KEY_BOOK_X_CONFIG, json)
      this.preference.flush()
    } catch (e) {
      // ignore
    }
  }

  /**
   * pdf方向
   * @returns
   */
  public getBookOrientation(): BookOrientation {
    if (this.preference.hasSync(AppPrefer.KEY_BOOK_ORIENTATION)) {
      return this.preference.getSync(AppPrefer.KEY_BOOK_ORIENTATION, BookOrientation.LAND) as number
    }
    return BookOrientation.LAND
  }

  /**
   * 设置pdf方向
   * @param orientation
   */
  public setBookOrientation(orientation: BookOrientation) {
    this.preference.putSync(AppPrefer.KEY_BOOK_ORIENTATION, orientation)
    this.preference.flush()
  }

  public getPageSize(): FinPageSize {
    if (this.preference.hasSync(AppPrefer.KEY_BOOK_PAGE_SIZE)) {
      return this.preference.getSync(AppPrefer.KEY_BOOK_PAGE_SIZE, FinPageSize.Size_50) as FinPageSize
    }
    return FinPageSize.Size_50
  }

  public setPageSize(pageSize: FinPageSize) {
    this.preference.putSync(AppPrefer.KEY_BOOK_PAGE_SIZE, pageSize)
    this.preference.flush()
  }

  public getSortDir(): boolean {
    if (this.preference.hasSync(AppPrefer.KEY_LIST_SORT_DIR)) {
      return this.preference.getSync(AppPrefer.KEY_LIST_SORT_DIR, true) as boolean
    }
    return true
  }

  public setSortDir(sortDir: boolean) {
    this.preference.putSync(AppPrefer.KEY_LIST_SORT_DIR, sortDir)
    this.preference.flushSync()
  }

  public getSortOrder(): FinSortOrder {
    if (this.preference.hasSync(AppPrefer.KEY_LIST_SORT_ORDER)) {
      return this.preference.getSync(AppPrefer.KEY_LIST_SORT_ORDER, FinSortOrder.Ascending) as FinSortOrder
    }
    return FinSortOrder.Ascending
  }

  public setSortOrder(sortOrder: FinSortOrder) {
    this.preference.putSync(AppPrefer.KEY_LIST_SORT_ORDER, sortOrder)
    this.preference.flush()
  }

  public getSortBy(): FinSortBy {
    if (this.preference.hasSync(AppPrefer.KEY_LIST_SORT_BY)) {
      return this.preference.getSync(AppPrefer.KEY_LIST_SORT_BY, FinSortBy.Name) as FinSortBy
    }
    return FinSortBy.Name
  }

  public setSortBy(sortBy: FinSortBy) {
    this.preference.putSync(AppPrefer.KEY_LIST_SORT_BY, sortBy)
    this.preference.flush()
  }

  public getHomeTabIndex(): number {
    return this.preference.getSync(AppPrefer.KEY_HOME_TAB_INDEX, 0) as number
  }

  public setHomeTabIndex(index: number) {
    this.preference.putSync(AppPrefer.KEY_HOME_TAB_INDEX, index)
    this.preference.flush()
  }

}