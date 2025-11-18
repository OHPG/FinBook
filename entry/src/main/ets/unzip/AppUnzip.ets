import { zlib } from "@kit.BasicServicesKit"
import { FileUtil } from "../util/FileUtil"

export class AppUnzip {

  private readonly context: Context

  constructor(context: Context) {
    this.context = context
  }

  public async unzip(file: string, dir: string): Promise<string> {
    let options: zlib.Options = {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION,
        memLevel: zlib.MemLevel.MEM_LEVEL_DEFAULT,
        strategy: zlib.CompressStrategy.COMPRESS_STRATEGY_DEFAULT_STRATEGY
      }
    try {
      if (!(await FileUtil.isFileExists(dir))) {
        await FileUtil.mkdir(dir)
      }
      await zlib.decompressFile(file, dir, options)
      return dir
    } catch (e) {
      await FileUtil.rmdir(dir)
      throw e as Error
    }
  }

}