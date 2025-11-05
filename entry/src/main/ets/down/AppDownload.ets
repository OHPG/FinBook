import request from "@ohos.request"
import fs from '@ohos.file.fs';
import BuildProfile from 'BuildProfile';

export class AppDownload {

  private readonly context: Context

  private downloadTask?: request.agent.Task

  constructor(context: Context) {
    this.context = context
  }

  public async download(url: string, path: string, auth: string): Promise<string> {
    if (this.downloadTask) {
      try {
        await this.downloadTask.stop()
      } catch (e) {
      }
      this.downloadTask = undefined
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
        "Authorization": auth
      },
      overwrite: true,
      saveas: tmpPath
    })
    let promise = new Promise<string>((resolve, reject) => {
      this.downloadTask?.on('response', (response) => {
        if (BuildProfile.DEBUG) {
          console.log("FinBook download response: " + JSON.stringify(response))
        }
      })
      this.downloadTask!.on('completed', () => {
        if (BuildProfile.DEBUG) {
          console.log("FinBook download complete.")
        }
        fs.renameSync(tmpPath, path)
        resolve(path)
      })
      this.downloadTask!.on('failed', (progress) => {
        if (BuildProfile.DEBUG) {
          console.error("FinBook download error: " + JSON.stringify(progress))
        }
        reject(new Error("Download fail " + progress.state))
      })
    })
    this.downloadTask.start()
    return promise
  }

}