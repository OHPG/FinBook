import fs from '@ohos.file.fs';
/**
 * @Author ZhiMing.Wang
 * @Email wangzhiming@pwrd.com
 * @DateTime 2025/9/28 17:50
 * @Version V1.0
 * @Description: 
 */
export class FileUtil {

  /**
   * 判断文件是否是pdf
   * @param path
   * @returns
   */
  public static async isPdf(path: string): Promise<boolean> {
    let file = await fs.open(path)
    try {
      let buffer = new ArrayBuffer(4)
      let read = await fs.read(file.fd, buffer)
      if (read != 4) {
        throw new Error("Read file error.")
      }
      let bytes = new Uint8Array(buffer)
      return bytes[0] === 0x25 &&
        bytes[1] === 0x50 &&
        bytes[2] === 0x44 &&
        bytes[3] === 0x46;
    } finally {
      fs.close(file.fd)
    }
  }

  public static async mkdir(dir: string): Promise<void> {
    let exist = await fs.access(dir, fs.AccessModeType.EXIST)
    if (!exist) {
      await fs.mkdir(dir)
    }
  }

}