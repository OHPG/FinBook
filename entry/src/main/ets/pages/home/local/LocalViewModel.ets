import fs from '@ohos.file.fs';
import { util } from "@kit.ArkTS";
import { MD5 } from "@ohpg/fin-core";
import { AppDir } from "../../../app/AppDir";
import { BookItem } from "../../../entity/BookItem";
import { StringUtil } from "../../../util/StringUtil";
import { FileUtil } from "../../../util/FileUtil";
import { AppThumb } from '../../../thumb/AppThumb';
import { TypeUtil } from '../../../util/TypeUtil';
import { delay } from '../../../comp/Time';
import { AppDataStore } from '../../../store/AppDataStore';
import { NormalViewModel } from '../com/NormalViewModel';

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/12/3 23:25
 * @Version V1.0
 * @Description
 */
export class LocalViewModel extends NormalViewModel{

  private context: Context

  private appDir: AppDir

  private readonly thumb: AppThumb

  private readonly dataStore: AppDataStore

  constructor(context: Context) {
    super()
    this.context = context
    this.appDir = new AppDir(context)
    this.thumb = AppStorage.get(AppThumb.THUMB)!
    this.dataStore = AppStorage.get(AppDataStore.APP_DATA_STORE)!
  }

  public async loadByPath(path: string): Promise<Array<BookItem>> {
    let start = Date.now()
    let itemArr = await this.loadData(path)

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
    filterItemArr.sort((left, right) => {
      // 比较 dir 属性，文件夹优先
      if (left.dir && !right.dir) {
        return -1; // a 是文件夹，b 不是
      }
      if (!left.dir && right.dir) {
        return 1; // a 不是文件夹，b 是
      }
      // 如果 dir 相同，则按名称排序
      return left.name.toLowerCase().localeCompare(right.name.toLowerCase());
    });

    // 查询视频信息
    for (const item of filterItemArr) {
      if (!item.dir) {
        item.thumb = await this.thumb.keyToThumb(item.id)
      }
    }

    // 查询历史
    if (filterItemArr.length > 0 && itemIdArr.length > 0) {
      let historyArr = await this.dataStore.queryAllBookHistory(itemIdArr)
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

  public async loadData(path: string): Promise<Array<BookItem>> {
    let rootDir = await this.appDir.acquireRootUri(this.context)
    // 注，传入的路径已经带“/”了
    let uri = rootDir+ path
    let fileArr = fs.listFileSync(uri)
    let itemArr = new Array<BookItem>()

    for (const name of fileArr) {
      let fileUri = uri + "/" + name
      let stat = fs.statSync(fileUri)

      let isDir = false
      if (stat.isFile()) {
        // file
      } else if (stat.isDirectory()){
        // folder
        isDir = true
      } else {
        // ignore
        continue
      }
      let id = MD5.digestSync(fileUri)
      let item: BookItem = {
        id: id,
        key: util.generateRandomUUID(true),
        name: name,
        uri: fileUri,
        dir: isDir,
        date: StringUtil.formatTimestamp(stat.ctime),
        size: StringUtil.formatFileSize(stat.size)
      }
      itemArr.push(item)
    }

    return itemArr
  }

  async removeData(path: string, dir?: boolean): Promise<void> {
    if (dir) {
      await FileUtil.rmdir(path)
    } else {
      await FileUtil.rmFile(path)
    }
  }

  async release(): Promise<void> {

  }

}