import { LoadType } from "@ohpg/fin-core";
import { SimpleRepository } from "@ohpg/fin-framework";
import { AppViewModel } from "../../lifecycle/AppViewModel";
import { MediaArgs } from "../detail/MediaArgs";
import { request } from "@kit.BasicServicesKit";
import { FileUtil } from "../../util/FileUtil";
import { FinBookRawSource } from "../../entity/FinBookRawSource";
import fs from '@ohos.file.fs';

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/7 12:56
 * @Version V1.0
 * @Description
 */
export class ReaderViewModel extends AppViewModel implements SimpleRepository {

  private readonly args: MediaArgs

  private downloadTask?: request.agent.Task

  constructor(context: Context, args: MediaArgs) {
    super(context)
    this.args = args
  }

  async loadData(type: LoadType): Promise<FinBookRawSource> {
    let item = await this.repository.getBook(this.args.id)
    let url = await this.repository.getBookUrl(item.id)
    let suffix: string = ''
    if (item.path) {
      let index = item.path.lastIndexOf('.')
      if (index >= 0) {
        suffix = item.path.substring(index)
      }
    }
    let filePath = this.context.filesDir + "/" + item.id + suffix;
    let exists = await fs.access(filePath, fs.AccessModeType.EXIST)
    if (!exists) {
      // download
      filePath = await this.download(url, filePath)
    }
    let pdf = await FileUtil.isPdf(filePath)
    
    let progress = 0
    if (item.data?.playedPositionTicks) {
      progress = item.data.playedPositionTicks
    }
    
    return {id: item.id, name: item.name, progress: progress, path: filePath, pdf: pdf}
  }

  private async download(url: string, path: string): Promise<string> {
    if (this.downloadTask) {
      await this.downloadTask.stop()
    }
    let tmpPath = path + ".tmp"
    let tmpExists = await fs.access(tmpPath, fs.AccessModeType.EXIST)
    if (tmpExists) {
      console.log("FinBook download clear tmp.")
      await fs.unlink(tmpPath)
    }
    this.downloadTask = await request.agent.create(this.context, {
      action: request.agent.Action.DOWNLOAD,
      url: url,
      mode: request.agent.Mode.FOREGROUND,
      headers: {
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate",
        "Accept-Language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7",
        "Authorization": this.repository.getAuth()
      },
      overwrite: true,
      saveas: tmpPath
    })
    let promise = new Promise<string>((resolve, reject) => {
      this.downloadTask?.on('response', (response) => {
        console.log("FinBook download response: " + JSON.stringify(response))
      })
      this.downloadTask!.on('completed', () => {
        console.log("FinBook download complete.")
        fs.renameSync(tmpPath, path)
        resolve(path)
      })
      this.downloadTask!.on('failed', (progress) => {
        console.log("FinBook download error: " + JSON.stringify(progress))
        reject(new Error("Download fail " + progress.state))
      })
    })
    this.downloadTask.start()
    return promise
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