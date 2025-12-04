import { LoadType } from "@ohpg/fin-core";
import { SimpleRepository } from "@ohpg/fin-framework";
import { BookHistory } from "../../../entity/BookHistory";
import { FinBookRawSource } from "../../../entity/FinBookRawSource";
import { AppViewModel } from "../../../lifecycle/AppViewModel";
import { AppDataStore } from "../../../store/AppDataStore";
import { FileUtil } from "../../../util/FileUtil";
import { MediaArgs } from "../../detail/MediaArgs";

export class LocalReaderViewModel extends AppViewModel implements SimpleRepository {

  private readonly args: MediaArgs

  private readonly dataStore: AppDataStore

  constructor(context: Context, args: MediaArgs) {
    super(context)
    this.args = args
    this.dataStore = AppStorage.get(AppDataStore.APP_DATA_STORE)!
  }

  async loadData(type: LoadType): Promise<FinBookRawSource> {
    let bookHistory = await this.dataStore.queryBookHistory(this.args.id)
    let fileType = await FileUtil.getBookType(this.args.uri!)
    let source: FinBookRawSource = {id: this.args.id,
      name: this.args.name,
      progress: bookHistory ? bookHistory.page : 0,
      path: this.args.uri!,
      type: fileType}
    return source
  }

  public async startRead(): Promise<void> {

  }

  public async updateProgress(progress: number, chapter: number): Promise<void> {
    let bookHistory: BookHistory = {
      id: this.args.id,
      source: this.args.uri!,
      time: Date.now(),
      page: progress,
      pages: chapter,
    }
    return this.dataStore.insertBookHistory(bookHistory)
  }

  public async stopRead(progress: number): Promise<void> {
  }
}