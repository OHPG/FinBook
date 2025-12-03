import fs from '@ohos.file.fs';
import { util } from "@kit.ArkTS";
import { MD5 } from "@ohpg/fin-core";
import { AppDir } from "../../../app/AppDir";
import { BookItem } from "../../../entity/BookItem";
import { StringUtil } from "../../../util/StringUtil";
import { FileUtil } from "../../../util/FileUtil";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/12/3 23:25
 * @Version V1.0
 * @Description
 */
export class LocalViewModel {

  private context: Context

  private appDir: AppDir

  constructor(context: Context) {
    this.context = context
    this.appDir = new AppDir(context)
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