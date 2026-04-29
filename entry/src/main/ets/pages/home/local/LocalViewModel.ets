import fs from '@ohos.file.fs';
import { util } from "@kit.ArkTS";
import { MD5 } from "@ohpg/fin-core";
import { AppDir } from "../../../app/AppDir";
import { BookItem } from "../../../entity/BookItem";
import { StringUtil } from "../../../util/StringUtil";
import { FileUtil } from "../../../util/FileUtil";
import { TreeData } from '../../../widget/tree/TreeData';

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/12/3 23:25
 * @Version V1.0
 * @Description
 */
export class LocalViewModel extends TreeData {

  private appDir: AppDir

  constructor(context: Context) {
    super(context);
    this.appDir = new AppDir(context)
  }

  protected async onLoadData(item?: BookItem): Promise<Array<BookItem>> {
    let uri: string
    if (item?.uri) {
      uri = item.uri
    } else {
      uri = await this.appDir.acquireRootUri(this.context)
    }
    let fileArr = await fs.listFile(uri)
    let itemArr = new Array<BookItem>()

    for (const name of fileArr) {
      let fileUri = uri + "/" + name
      let stat = await fs.stat(fileUri)

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

  protected async onRemoveData(item: BookItem): Promise<void> {
    if (item.dir) {
      await FileUtil.rmdir(item.uri)
    } else {
      await FileUtil.rmFile(item.uri)
    }
  }

  async release(): Promise<void> {

  }

}