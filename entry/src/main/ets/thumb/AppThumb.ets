import { MD5 } from "@ohpg/fin-core"
import { FileUtil } from "../util/FileUtil"
import { ImageUtil } from "../util/ImageUtil"
import { ThumbTask } from "./ThumbTask"
import { BookTool } from "../util/BookTool";
import { image } from "@kit.ImageKit";
import fs from '@ohos.file.fs';

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/12/3 23:51
 * @Version V1.0
 * @Description
 */
export class AppThumb {

  public static readonly THUMB = "thumb"

  private readonly context: Context

  private readonly callbackMap = new Map<string, Callback<string> | undefined>()

  private readonly ignoreSet = new Set<string>()

  private readonly thumbDir: string

  private readonly thumbQueue = new Array<ThumbTask>()

  private generatorBusy: boolean = false

  constructor(context: Context) {
    this.context = context
    this.thumbDir = context.cacheDir + "/thumb"
    FileUtil.mkdirSync(this.thumbDir)
  }

  /**
   * 获取资源缩略图
   * @param uri 资源路径
   * @returns
   */
  public async uriToThumb(uri: string): Promise<string | undefined> {
    let id = MD5.digestSync(uri)
    return this.keyToThumb(id)
  }

  /**
   * 获取资源缩略图
   * @param id 资源id
   * @returns
   */
  public async keyToThumb(id: string): Promise<string | undefined> {
    try {
      let path = this.thumbDir + "/" + id
      let stat = fs.statSync(path)
      if (stat.size > 0) {
        return path
      }
    } catch (e) {

    }
    return undefined
  }

  /**
   * 添加任务
   * @param uri 资源路径
   * @param callback
   * @returns 任务id，用来取消
   */
  public load(uri: string, callback?: Callback<string>, header?: Record<string, string>): string | undefined {
    // 如果在忽略名单里，直接返回
    if (this.ignoreSet.has(uri)) return undefined

    // 判断文件类型，目前只支持mp4和mkv
    let index = uri.lastIndexOf(".")
    if (index <= 0 || index >= uri.length) return undefined
    let suffix = uri.substring(index + 1).toLowerCase()

    let id = MD5.digestSync(uri)
    this.callbackMap.set(id, callback)
    let pre = this.thumbQueue.find((value) => value.id === id)
    if (!pre) {
      this.thumbQueue.push({id: id, uri: uri})
      this.trigger()
    }
    return id
  }

  /**
   * 取消任务
   * @param id 任务id
   */
  public cancel(id: string) {
    let index = this.thumbQueue.findIndex((value) => value.id === id)
    if (index >= 0) {
      this.thumbQueue.splice(index, 1)
    }
    this.callbackMap.delete(id)
  }

  private trigger() {
    if (this.generatorBusy || this.thumbQueue.length <= 0) return
    let task = this.thumbQueue[this.thumbQueue.length - 1]
    this.thumbQueue.splice(this.thumbQueue.length - 1)
    this.generateThumb(task)
  }

  private async generateThumb(task: ThumbTask): Promise<void> {
    this.generatorBusy = true
    try {
      let img = await BookTool.extractCover(task.uri)
      if (img) {
        let size = img.getImageInfoSync().size
        if (Math.min(size.width, size.height) > 480) {
          // 缩小
          let scaleX = 480 / size.width
          let scaleY = 480 / size.height
          let scale = Math.max(scaleX, scaleY)
          await img.scale(scale, scale, image.AntiAliasingLevel.MEDIUM)
        }

        // 保存
        let path = this.thumbDir + "/" + task.id
        await ImageUtil.packImage(img, path)

        // 回调
        let callback = this.callbackMap.get(task.id)
        if (callback) {
          callback(path)
          this.callbackMap.delete(task.id)
        }
      } else {
        // 保存出错的资源uri，避免多次尝试
        this.ignoreSet.add(task.uri)
      }
    } catch (e) {
      // 保存出错的资源uri，避免多次尝试
      this.ignoreSet.add(task.uri)
    }
    this.generatorBusy = false
    this.trigger()
  }


}