import { LoadType } from "@ohpg/fin-core";
import { SimpleRepository } from "@ohpg/fin-framework";
import { AppViewModel } from "../../../lifecycle/AppViewModel";
import { MediaArgs } from "../../detail/MediaArgs";
import { FileUtil } from "../../../util/FileUtil";
import { FinBookRawSource } from "../../../entity/FinBookRawSource";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/7 12:56
 * @Version V1.0
 * @Description 在线阅读 ViewModel
 *
 * 下载逻辑已迁移到 DetailViewModel，本类只负责：
 *   1. 定位已下载的本地文件路径
 *   2. 读取书籍元数据（名称、阅读进度）
 *   3. 返回 FinBookRawSource 供 Reader 使用
 */
export class OnlineReaderViewModel extends AppViewModel implements SimpleRepository {

  private readonly args: MediaArgs

  constructor(context: Context, args: MediaArgs) {
    super(context)
    this.args = args
  }

  async loadData(type: LoadType): Promise<FinBookRawSource> {
    const activeInfo = this.repository.getActiveInfo()!
    const item = await this.repository.getBook(this.args.id)

    // 计算本地缓存路径（与 DetailViewModel.resolveLocalPath 保持一致）
    let suffix = ''
    if (item.path) {
      const index = item.path.lastIndexOf('.')
      if (index >= 0) {
        suffix = item.path.substring(index)
      }
    }
    const dirPath = this.context.filesDir + '/' + activeInfo.serverInfo.serverId
    const filePath = dirPath + '/' + item.id + suffix

    // 文件应已由详情页下载完毕，若意外缺失则抛出友好错误
    const exists = await FileUtil.isFileExists(filePath)
    if (!exists) {
      throw new Error('Book file not found, please return and re-download.')
    }

    const fileType = await FileUtil.getBookType(filePath)

    let progress = item.data?.playedPositionTicks ?? 0
    if (progress < 0) {
      progress = 0
    }

    return { id: item.id, name: item.name, progress, path: filePath, type: fileType }
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
