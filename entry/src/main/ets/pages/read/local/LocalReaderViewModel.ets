import { LoadType } from "@ohpg/fin-core";
import { SimpleRepository } from "@ohpg/fin-framework";
import { BookHistory } from "../../../entity/BookHistory";
import { FinBookRawSource } from "../../../entity/FinBookRawSource";
import { AppEvent } from "../../../event/AppEvent";
import { AppViewModel } from "../../../lifecycle/AppViewModel";
import { AppDataStore } from "../../../store/AppDataStore";
import { FileUtil } from "../../../util/FileUtil";
import { TypeUtil } from "../../../util/TypeUtil";
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
    let bookHistory = await this.dataStore.queryBookHistoryById(this.args.id)
    let readPath = this.args.uri!
    // epub、mobi、azw、azw3 需要拷贝到沙盒后再阅读
    // 系统阅读器会在目标目录产生临时文件
    if (TypeUtil.needSandboxCopy(this.args.name)) {
      readPath = await FileUtil.copyToSandbox(this.context, readPath)
    }
    let fileType = await FileUtil.getBookType(readPath)
    let source: FinBookRawSource = {id: this.args.id,
      name: this.args.name,
      progress: bookHistory ? bookHistory.page : 0,
      path: readPath,
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
    this.context.eventHub.emit(AppEvent.EVENT_MEDIA_INFO_HISTORY_CHANGED, bookHistory)
    return this.dataStore.insertBookHistory(bookHistory)
  }

  public async stopRead(progress: number): Promise<void> {
  }
}