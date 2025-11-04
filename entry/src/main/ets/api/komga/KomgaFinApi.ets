import { ActuatorInfo, Auth, AuthType, UserDto } from "@ohpg/komga";
import { BookDto, Komga, LibraryDto } from "@ohpg/komga";
import { FinBookApi } from "../FinBookApi";
import { ActiveInfo, FinPage, FinPersonType, MD5, ServerType } from "@ohpg/fin-core";
import { FinItemType } from "@ohpg/fin-core";
import { FinPublicSystemInfo } from "@ohpg/fin-core";
import { FinItem, FinAuthResult } from "@ohpg/fin-core";
import { ClientInfo, DeviceInfo } from "@ohpg/network";
import uri from "@ohos.uri";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/11/2 12:41
 * @Version V1.0
 * @Description
 */
export class KomgaFinApi implements FinBookApi {

  private readonly context: Context

  private activeInfo?: ActiveInfo

  /**
   * Komga api
   */
  private komga: Komga

  private komgaHeader?: Record<string, string>

  private komgaTmp: Komga

  private readingBook?: BookDto

  constructor(context: Context, clientInfo: ClientInfo, deviceInfo: DeviceInfo) {
    this.context = context
    this.komga = new Komga(clientInfo, deviceInfo)
    this.komgaTmp = new Komga(clientInfo, deviceInfo)
  }

  private generateAuth(name?: string, psw?: string): string | undefined {
    if (!name || !psw) {
      throw new Error("Name or psw is null.")
    }
    let auth = new Auth(AuthType.Basic, name, psw)
    return auth.auth
  }

  /**
   * 通过服务器信息生成server id
   * @param info
   * @returns
   */
  private generateServerId(info: ActuatorInfo): string {
    let serverId = info.os.name + "-" + info.os.arch
    return MD5.digestSync(serverId)
  }

  getApiType(): ServerType {
    return ServerType.KOMGA
  }

  getAuth(): string {
    return this.komga.apiClient.getAuthorization()
  }

  updateAddress(address: string): void {
    this.komga.selectServer({address: address})
  }

  updateActiveInfo(activeInfo: ActiveInfo): void {
    this.activeInfo = activeInfo
    this.komga.selectServer({address: activeInfo.addressInfo.address})
    this.komga.selectUser({id: activeInfo.userInfo.userId, token: activeInfo.userInfo.accessToken})
    this.komgaHeader = {
      "Authorization": this.komga.apiClient.getAuthorization()
    }
  }

  public async getPublicSystemInfo(url: string, name?: string): Promise<FinPublicSystemInfo> {
    if (!name || name.length <= 0) {
      throw new Error("Server name is empty.")
    }
    return {Id: MD5.digestSync(name), ServerName: name, StartupWizardCompleted: true}
  }

  public async getSystemInfo(url?: string): Promise<FinPublicSystemInfo> {
    // 非管理员，无权限获取系统信息
    // 用获取用户信息来代替获取系统信息
    if (url) {
      this.komgaTmp.selectServer({address: url})
      this.komgaTmp.selectUser({id: this.activeInfo!.userInfo.userId, token: this.activeInfo!.userInfo.accessToken})
      await this.komgaTmp.getUserApi().getCurrentUser()
    }
    return {Id: this.activeInfo!.serverInfo.serverId, ServerName: this.activeInfo!.serverInfo.serverName}
  }

  public async authenticateUserByName(name: string, psw?: string): Promise<FinAuthResult> {
    let auth = this.generateAuth(name, psw)
    this.komgaTmp.selectServer({address: this.activeInfo!.addressInfo.address})
    this.komgaTmp.selectUser({token: auth})
    let serverInfo = await this.getSystemInfo()
    let authResult = await this.komga.getUserApi().getCurrentUser()
    return { ServerId: serverInfo.Id
    , UserName: authResult.email
    , UserId: authResult.id
    , AccessToken: auth}
  }

  private buildBookImage(dto: BookDto): string {
    let imageUri = new uri.URI(this.activeInfo!.addressInfo.address)
    imageUri = imageUri.addEncodedSegment(`api/v1/books/${dto.id!}/thumbnail`)
    return imageUri.toString()
  }

  private libraryToFinItem(library: LibraryDto): FinItem {
    let item: FinItem = {
      id: library.id,
      name: library.name,
      type: FinItemType.Folder,
      path: library.root
    }
    return item
  }

  private bookToFinItem(book: BookDto): FinItem {
    let item: FinItem = {
      id: book.id,
      name: book.name,
      type: FinItemType.Book,
      originalTitle: book.name,
      overview: book.metadata?.summary,
      path: book.url,
      person: [],
      image: {
        primary: this.buildBookImage(book),
        header: this.komgaHeader
      }
    }
    book.metadata.authors?.forEach((author) => {
      item.person?.push({
        id: "",
        name: author.name,
        role: author.role,
        type: FinPersonType.Author
      })
    })
    if (book?.media?.mediaProfile === "PDF") {
      if (book.readProgress) {
        item.data = {
          playedPositionTicks: book.readProgress.page,
          played: book.readProgress.completed
        }
      }
    } else {
      // Epub not support
    }
    return item
  }

  public async getLibraryList(): Promise<Array<FinItem>> {
    let result = await this.komga.getLibraryApi().getLibraries()
    let finLibraryArray = new Array<FinItem>()
    result?.forEach((item) => {
      finLibraryArray.push(this.libraryToFinItem(item))
    })
    return finLibraryArray
  }

  public async search(keyword: string): Promise<FinPage> {
    let finItems = new Array<FinItem>()
    let result = await this.komga.getItemsApi().search(keyword)
    result.content?.forEach((item) => {
      finItems.push(this.bookToFinItem(item))
    })
    return {items: finItems, cur: 0, more: false }
  }

  public async getBookList(id: string, page?: number): Promise<FinPage> {
    let finItems = new Array<FinItem>()
    let result = await this.komga.getItemsApi().getBooks(id, page)
    result.content?.forEach((item) => {
      finItems.push(this.bookToFinItem(item))
    })
    let cur: number = result.pageable ? result.pageable.pageNumber : 0
    let more: boolean = cur < result.totalPages - 1
    return {items: finItems, cur: cur, more: more }
  }

  public async getBook(id: string): Promise<FinItem> {
    let item = await this.komga.getItemsApi().getBook(id)
    return this.bookToFinItem(item)
  }

  public async getBookUrl(id: string): Promise<string> {
    let url = await this.komga.getItemsApi().getFile(id)
    return url
  }

  public searchMedia(keyword: string): Promise<Array<FinItem>> {
    return Promise.resolve([])
  }

  async markFavoriteItem(id: string): Promise<void> {
  }

  async unmarkFavoriteItem(id: string): Promise<void> {
  }

  async markPlayedItem(id: string): Promise<void> {
    await this.komga.getItemsApi().markBookRead(id)
  }

  async markUnplayedItem(id: string): Promise<void> {
    await this.komga.getItemsApi().markBookUnread(id)
  }

  async onPlaybackStart(id: string): Promise<void> {
    this.readingBook = await this.komga.getItemsApi().getBook(id)
  }

  async onPlaybackProgress(id: string, position: number, playing: boolean): Promise<void> {
    let mediaProfile = this.readingBook?.media?.mediaProfile
    if (mediaProfile === "PDF") {
      await this.komga.getItemsApi().markBookReadProgress(id, position)
    } else if (mediaProfile === "EPUB") {
      // let href = AppStorage.get<string>("boo_href")
      // if (href) {
      //   await this.komga.getItemsApi().markBookProgression(id, href, position)
      // } else {
      //   // ignore
      // }
    } else {
      // not support.
    }
  }

  async onPlaybackStopped(id: string, position: number): Promise<void> {
    this.readingBook = undefined
  }

  public async release(): Promise<void> {
    this.komga.apiClient.release()
    this.komgaTmp.apiClient.release()
  }

}
