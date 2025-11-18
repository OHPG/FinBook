import { LoadType } from "@ohpg/fin-core";
import { SimpleRepository } from "@ohpg/fin-framework";
import { AppViewModel } from "../../lifecycle/AppViewModel";
import { MediaArgs } from "../detail/MediaArgs";
import { FileUtil } from "../../util/FileUtil";
import { FinBookRawSource } from "../../entity/FinBookRawSource";
import { AppDownload } from "../../down/AppDownload";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/7 12:56
 * @Version V1.0
 * @Description
 */
export class ReaderViewModel extends AppViewModel implements SimpleRepository {

  private readonly args: MediaArgs

  private readonly down: AppDownload

  constructor(context: Context, args: MediaArgs) {
    super(context)
    this.args = args
    this.down = new AppDownload(context)
  }

  async loadData(type: LoadType): Promise<FinBookRawSource> {
    let activeInfo = this.repository.getActiveInfo()!
    let item = await this.repository.getBook(this.args.id)
    let url = await this.repository.getBookUrl(item.id)
    let suffix: string = ''
    if (item.path) {
      let index = item.path.lastIndexOf('.')
      if (index >= 0) {
        suffix = item.path.substring(index)
      }
    }
    // 目标路径
    let dirPath = this.context.filesDir + "/" + activeInfo.serverInfo.serverId
    // 创建文件夹（如果不存在的话）
    await FileUtil.mkdir(dirPath)
    // 文件路径
    let filePath = dirPath + "/" + item.id + suffix;
    // 判断文件是否存在
    let exists = await FileUtil.isFileExists(filePath)
    if (!exists) {
      // 下载文件
      filePath = await this.down.download(url, filePath, this.repository.getAuth())
    }
    let fileType = await FileUtil.getBookType(filePath)

    let progress = 0
    if (item.data?.playedPositionTicks) {
      progress = item.data.playedPositionTicks
    }
    if (progress < 0) {
      progress = 0
    }
    
    return {id: item.id, name: item.name, progress: progress, path: filePath, type: fileType}
  }

  public startRead(): Promise<void> {
    return this.repository.startRead(this.args.id)
  }

  public updateProgress(progress: number): Promise<void> {
    return this.repository.updateProgress(this.args.id, progress)
  }

  public stopRead(progress: number): Promise<void> {
    return this.repository.stopRead(this.args.id, progress)
  }

}