import { MediaArgs } from "./MediaArgs";
import { FinItem, LoadType, ServerType } from "@ohpg/fin-core";
import { SimpleRepository } from "@ohpg/fin-framework";
import { AppViewModel } from "../../lifecycle/AppViewModel";
import { AppDownload } from "../../down/AppDownload";
import { DownloadState } from "../../down/DownloadState";
import { FileUtil } from "../../util/FileUtil";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/23 22:44
 * @Version V1.0
 * @Description 详情
 */
export class DetailViewModel extends AppViewModel implements SimpleRepository {

  protected readonly args: MediaArgs

  private readonly down: AppDownload = new AppDownload(this.context)

  /** UI 层通过 @ObjectLink 绑定此对象，响应下载进度变化 */
  readonly downloadState: DownloadState = new DownloadState()

  constructor(context: Context, args: MediaArgs) {
    super(context)
    this.args = args
  }

  /**
   * 当前服务端是否支持收藏功能
   */
  get supportFavorite(): boolean {
    const serverType = this.repository.getActiveInfo()?.serverInfo.serverType
    return serverType === ServerType.JELLYFIN || serverType === ServerType.EMBY
  }

  async loadData(type: LoadType): Promise<Object> {
    let book = await this.repository.getBook(this.args.id)
    console.info("DetailViewModel: loadData id = " + this.args.id
      + ", isFavorite = " + book.data?.isFavorite
      + ", played = " + book.data?.played)
    return book
  }

  /**
   * 计算在线书籍的本地缓存路径
   * 与 OnlineReaderViewModel 保持一致的路径规则：
   *   filesDir / serverId / itemId + suffix
   */
  private async resolveLocalPath(item: FinItem): Promise<string> {
    const activeInfo = this.repository.getActiveInfo()!
    let suffix = ''
    if (item.path) {
      const index = item.path.lastIndexOf('.')
      if (index >= 0) {
        suffix = item.path.substring(index)
      }
    }
    const dirPath = this.context.filesDir + '/' + activeInfo.serverInfo.serverId
    await FileUtil.mkdir(dirPath)
    return dirPath + '/' + item.id + suffix
  }

  /**
   * 检查书籍是否已缓存到本地
   * @returns 本地文件路径（已缓存），或 null（未缓存）
   */
  async getCachedFilePath(item: FinItem): Promise<string | null> {
    const filePath = await this.resolveLocalPath(item)
    const exists = await FileUtil.isFileExists(filePath)
    return exists ? filePath : null
  }

  /**
   * 下载书籍到本地缓存目录，通过 downloadState 实时上报进度
   * @returns 下载完成后的本地文件路径
   */
  async downloadBook(item: FinItem): Promise<string> {
    const filePath = await this.resolveLocalPath(item)
    const url = await this.repository.getBookUrl(item.id)
    const auth = this.repository.getAuth()

    this.downloadState.start()
    try {
      await this.down.download(url, filePath, auth, (processed, total) => {
        this.downloadState.update(processed, total)
      })
      return filePath
    } finally {
      this.downloadState.finish()
    }
  }

  async finishOrNot(finish?: boolean): Promise<boolean> {
    if (finish) {
      await this.repository.markUnplayedItem(this.args.id)
      return false
    } else {
      await this.repository.markPlayedItem(this.args.id)
      return true
    }
  }

  async favouriteOrNot(favorite?: boolean): Promise<boolean> {
    if (favorite) {
      await this.repository.unmarkFavoriteItem(this.args.id)
      return false
    } else {
      await this.repository.markFavoriteItem(this.args.id)
      return true
    }
  }

}
