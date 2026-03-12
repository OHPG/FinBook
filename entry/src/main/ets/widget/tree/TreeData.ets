import intl from '@ohos.intl';
import i18n from "@ohos.i18n"
import { delay } from "../../comp/Time"
import { BookItem } from "../../entity/BookItem"
import { AppDataStore } from "../../store/AppDataStore"
import { AppThumb } from "../../thumb/AppThumb"
import { TypeUtil } from "../../util/TypeUtil"
import { AppConfig } from '../../config/AppConfig';
import { FinSortBy, FinSortOrder } from '@ohpg/fin-core';

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2026/3/5 22:41
 * @Version V1.0
 * @Description
 */
export abstract class TreeData {

  protected readonly context: Context

  private readonly config: AppConfig

  private readonly thumb: AppThumb

  private readonly dataStore: AppDataStore

  private readonly collator: intl.Collator

  constructor(context: Context) {
    this.context = context
    this.config = AppStorage.get(AppConfig.CONFIG)!
    this.thumb = AppStorage.get(AppThumb.THUMB)!
    this.dataStore = AppStorage.get(AppDataStore.APP_DATA_STORE)!
    let systemLanguage = i18n.System.getSystemLanguage();
    let options: intl.CollatorOptions = {
      usage: "sort",
      numeric: true
    };
    this.collator = new intl.Collator(systemLanguage, options);
  }

  /**
   * 加载数据
   * @param item
   * @returns
   */
  async loadData(item?: BookItem): Promise<Array<BookItem>> {
    let start = Date.now()
    let itemArr = await this.onLoadData(item)

    let itemIdArr = new Array<string>()

    // 过滤
    let filterItemArr = itemArr.filter((item) => {
      if (item.dir) {
        return true
      } else {
        if (TypeUtil.isBook(item.name)) {
          itemIdArr.push(item.id)
          return true
        } else {
          return false
        }
      }
    })

    // 排序
    this.sortData(filterItemArr)

    // 查询视频信息
    for (const item of filterItemArr) {
      if (!item.dir) {
        item.thumb = await this.thumb.keyToThumb(item.id)
      }
    }

    // 查询历史
    if (filterItemArr.length > 0 && itemIdArr.length > 0) {
      let historyArr = await this.dataStore.queryBookHistoryByIds(itemIdArr)
      historyArr?.forEach((history) => {
        let item = filterItemArr.find((item) => item.id == history.id)
        if (item) {
          item.history = history
        }
      })
    }

    // 由于查询数据耗时过小，会触发UI的bug（刷新状态不会重置），因此手动延迟一下。
    let cost = Date.now() - start
    if (cost < 20) {
      await delay(20 - cost)
    }

    return filterItemArr
  }

  protected abstract onLoadData(item?: BookItem): Promise<Array<BookItem>>

  /**
   * 数据排序
   * @param itemArray
   */
  public sortData(itemArray?: Array<BookItem>) {
    itemArray?.sort((left, right) => {
      if (this.config.sortDir) {
        // 比较 dir 属性，文件夹优先
        if (left.dir && !right.dir) {
          return -1; // a 是文件夹，b 不是
        }
        if (!left.dir && right.dir) {
          return 1; // a 不是文件夹，b 是
        }
      }
      let sort: number = 0
      if (this.config.sortBy === FinSortBy.DateCreated && left.date && right.date) {
        // 按时间排序
        sort = left.date.localeCompare(right.date);
      } else {
        // 如果 dir 相同，则按名称排序
        sort = this.collator.compare(left.name, right.name)
      }
      return this.config.sortOrder === FinSortOrder.Ascending ? sort : -sort
    });
  }

  /**
   * 删除数据
   * @param item
   * @returns
   */
  public async removeData(item: BookItem): Promise<void> {
    await this.onRemoveData(item)
  }

  protected abstract onRemoveData(item: BookItem): Promise<void>

  abstract release(): Promise<void>
}