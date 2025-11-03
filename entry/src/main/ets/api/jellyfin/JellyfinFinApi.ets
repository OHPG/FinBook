import { ActiveInfo, FinAuthResult, FinItem, FinItemType,
  FinPerson,
  FinPersonType,
  FinPublicSystemInfo, ServerType } from "@ohpg/fin-core";
import { BaseItemDto, BaseItemKind, BaseItemPerson,
  CollectionType,
  ImageType,
  ItemSortBy,
  Jellyfin,
  SortOrder} from "@ohpg/jellyfin";
import { ClientInfo, DeviceInfo } from "@ohpg/network";
import { FinBookApi } from "../FinBookApi";
import { uri } from "@kit.ArkTS";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/7/6 13:49
 * @Version V1.0
 * @Description jellyfin api
 */
export class JellyfinFinApi implements FinBookApi {

  private readonly context: Context


  private activeInfo?: ActiveInfo

  /**
   * Jellyfin api tmp
   */
  private jellyfin: Jellyfin

  private bookLibraryArray?: Array<BaseItemDto>

  private bookLibrary?: BaseItemDto

  constructor(context: Context, clientInfo: ClientInfo, deviceInfo: DeviceInfo) {
    this.context = context
    this.jellyfin = new Jellyfin(clientInfo, deviceInfo)
  }

  private buildImage(dto: BaseItemDto, type: ImageType): string {
    let imageUri = new uri.URI(this.activeInfo!.addressInfo.address)
    imageUri = imageUri.addEncodedSegment(`items/${dto.Id!}/Images/${type}`)
    return imageUri.toString()
  }

  private buildPersonImage(person: BaseItemPerson, type: ImageType): string {
    let imageUri = new uri.URI(this.activeInfo!.addressInfo.address)
    imageUri = imageUri.addEncodedSegment(`items/${person.Id!}/Images/${type}`)
    return imageUri.toString()
  }

  private itemToFinItem(item: BaseItemDto): FinItem {
    let finItem: FinItem = {
      id: item.Id!,
      name: item.Name!,
      path: item.Path!,
      type: item.Type! as ESObject as FinItemType,
      originalTitle: item.OriginalTitle!,
      overview: item.Overview!,
      runtimeTicks: item.RunTimeTicks!,
      image: {
        primary: this.buildImage(item, ImageType.Primary),
        backdrop: this.buildImage(item, ImageType.Backdrop)
      },
      data: {
        rating: item.UserData?.Rating!,
        playPercentage: item.UserData?.PlayedPercentage!,
        unplayedItemCount: item.UserData?.UnplayedItemCount!,
        playedPositionTicks: item.UserData?.PlaybackPositionTicks
          ? item.UserData?.PlaybackPositionTicks / 10000
          : undefined,
        playCount: item.UserData?.PlayCount!,
        isFavorite: item.UserData?.IsFavorite,
        likes: item.UserData?.Likes!,
        lastPlayDate: item.UserData?.LastPlayedDate!,
        played: item.UserData?.Played
      }
    }

    // people
    if (item.People) {
      let finPerson = new Array<FinPerson>()
      item.People?.forEach((person) => {
        finPerson.push({
          id: person.Id!,
          name: person.Name!,
          role: person.Role!,
          type: person.Type as ESObject as FinPersonType,
          image: {
            primary: this.buildPersonImage(person, ImageType.Primary)
          }
        })
      })
      finItem.person = finPerson
    }
    return finItem
  }

  getApiType(): ServerType {
    return ServerType.JELLYFIN
  }

  public getAuth(): string {
    return this.jellyfin.apiClient.getAuthorization()
  }

  updateAddress(address: string): void {
    this.jellyfin.selectServer({address: address})
    this.bookLibrary = undefined
  }

  updateActiveInfo(activeInfo: ActiveInfo): void {
    this.activeInfo = activeInfo
    this.bookLibrary = undefined
    this.jellyfin.selectServer({address: activeInfo.addressInfo.address})
    this.jellyfin.selectUser({id: activeInfo.userInfo.userId, token: activeInfo.userInfo.accessToken})
  }

  public async getPublicSystemInfo(url: string): Promise<FinPublicSystemInfo> {
    this.jellyfin.selectServer({address: url})
    let info = await this.jellyfin.getSystemApi().getPublicSystemInfo()
    return {Id: info.Id, ServerName: info.ServerName, Version: info.Version, StartupWizardCompleted: info.StartupWizardCompleted}
  }

  public async getSystemInfo(url?: string): Promise<FinPublicSystemInfo> {
    if (url) {
      this.jellyfin.selectServer({address: url})
    }
    let info = await this.jellyfin.getSystemApi().getSystemInfo()
    return {Id: info.Id, ServerName: info.ServerName, Version: info.Version, StartupWizardCompleted: info.StartupWizardCompleted}
  }

  public async authenticateUserByName(name: string, psw?: string | undefined): Promise<FinAuthResult> {
    let authResult = await this.jellyfin.getUserApi().authenticateUserByName({Username: name, Pw: psw})
    return { ServerId: authResult.ServerId
    , UserName: authResult.User?.Name
    , UserId: authResult.User?.Id
    , AccessToken: authResult.AccessToken}
  }

  private async assertCurrentBookLibrary(): Promise<BaseItemDto> {
    if (!this.bookLibrary) {
      let result = await this.jellyfin.getUserViewsApi().getUserViews({
        userId: this.activeInfo!.userInfo.userId,
        presetViews: [CollectionType.Books]
      })
      this.bookLibraryArray = result.Items?.filter((item) => item.CollectionType === CollectionType.Books)
      this.bookLibrary = this.bookLibraryArray?.[0]
    }
    if (!this.bookLibrary) {
      throw new Error("No book library found.")
    }
    return this.bookLibrary
  }

  public async getBookList(id?: string): Promise<Array<FinItem>> {
    let library = await this.assertCurrentBookLibrary()
    let finItems = new Array<FinItem>()
    let result = await this.jellyfin.getItemsApi().getItems({
      parentId: id ? id : library.Id,
      includeItemTypes: [BaseItemKind.Book, BaseItemKind.Folder],
      recursive: false,
      sortBy: [ItemSortBy.Name],
      sortOrder: [SortOrder.Ascending]
    })
    let filterItems = result.Items?.filter((item) => item.Type === BaseItemKind.Book || BaseItemKind.Folder)
    filterItems?.forEach((item) => {
      finItems.push(this.itemToFinItem(item))
    })
    return finItems
  }

  public async getBook(id: string): Promise<FinItem> {
    let item = await  this.jellyfin.getUserLibraryApi().getItem({
      userId: this.activeInfo!.userInfo.userId,
      itemId: id
    })
    return this.itemToFinItem(item)
  }

  public async getBookUrl(id: string): Promise<string> {
    let url = await this.jellyfin.getLibraryApi().getFile({
      itemId: id,
    })
    return url
  }

  public searchMedia(keyword: string): Promise<Array<FinItem>> {
    return Promise.resolve([])
  }

  async markFavoriteItem(id: string): Promise<void> {
    await this.jellyfin.getUserLibraryApi().markFavoriteItem({
      itemId: id,
      userId: this.activeInfo!.userInfo.userId
    })
  }

  async unmarkFavoriteItem(id: string): Promise<void> {
    await this.jellyfin.getUserLibraryApi().unmarkFavoriteItem({
      itemId: id,
      userId: this.activeInfo!.userInfo.userId
    })
  }

  async markPlayedItem(id: string): Promise<void> {
    await this.jellyfin.getPlayStateApi().markPlayedItem({
      itemId: id,
      userId: this.activeInfo!.userInfo.userId
    })
  }

  async markUnplayedItem(id: string): Promise<void> {
    await this.jellyfin.getPlayStateApi().markUnplayedItem({
      itemId: id,
      userId: this.activeInfo!.userInfo.userId
    })
  }

  async onPlaybackStart(id: string): Promise<void> {
    await this.jellyfin.getPlayStateApi().onPlaybackStart({itemId: id})
  }

  async onPlaybackProgress(id: string, position: number, playing: boolean): Promise<void> {
    await this.jellyfin.getPlayStateApi().onPlaybackProgress({itemId: id, positionTicks: position * 10000, isPaused: !playing})
  }

  async onPlaybackStopped(id: string, position: number): Promise<void> {
    await this.jellyfin.getPlayStateApi().onPlaybackStopped({itemId: id, positionTicks: position * 10000})
  }

  public async release(): Promise<void> {
    this.jellyfin.apiClient.release()
  }

}