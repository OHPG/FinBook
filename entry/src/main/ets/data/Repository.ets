import { FinBookApi } from "../api/FinBookApi";
import { FinItem, FinPage } from "@ohpg/fin-core";
import { FinRepository } from "@ohpg/fin-framework";
import { FinBookApiFactory } from "../api/FinBookApiFactory";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/11/9 11:50
 * @Version V1.0
 * @Description Repository
 */
export class Repository extends FinRepository {

  constructor(context: Context) {
    super(context, new FinBookApiFactory(context))
  }

  protected requireApi(): FinBookApi {
    return super.requireApi() as FinBookApi
  }

  public getAuth(): string {
    return this.requireApi().getAuth()
  }

  public getLibraryList():Promise<Array<FinItem>> {
    return this.requireApi().getLibraryList()
  }

  public getBookList(id: string, page?: number): Promise<FinPage> {
    return this.requireApi().getBookList(id, page)
  }

  public getBook(id: string): Promise<FinItem> {
    return this.requireApi().getBook(id)
  }

  public getBookUrl(id: string): Promise<string> {
    return this.requireApi().getBookUrl(id)
  }

  public startRead(id: string): Promise<void> {
    return this.requireApi().onPlaybackStart(id)
  }

  public updateProgress(id: string, ticks: number): Promise<void> {
    return this.requireApi().onPlaybackProgress(id, ticks, true)
  }

  public stopRead(id: string, ticks: number): Promise<void> {
    return this.requireApi().onPlaybackStopped(id, ticks)
  }

}
