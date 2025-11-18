import fs from '@ohos.file.fs';
import { BookType } from '../enum/BookType';

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
  public static async getBookType(path: string): Promise<BookType> {
    let file = await fs.open(path)
    try {
      let buffer = new ArrayBuffer(4)
      let read = await fs.read(file.fd, buffer)
      if (read != 4) {
        throw new Error("Read file error.")
      }
      let bytes = new Uint8Array(buffer)
      let type: BookType | undefined
      // 如何实现准确判断压缩文件类型
      // https://developer.huawei.com/consumer/cn/doc/architecture-guides/kids-v1_2-ts_12-0000002442710557
      if (bytes[0] === 0x25 && bytes[1] === 0x50 && bytes[2] === 0x44 && bytes[3] === 0x46) {
        type = BookType.PDF
      } else if (bytes[0] === 0x50 && bytes[1] === 0x4B && bytes[2] === 0x03 && bytes[3] === 0x04) {
        // zip azw3 epub
        let index = path.lastIndexOf(".")
        if (index) {
          let suffix = path.substring(index + 1).toLowerCase()
          if (suffix === "epub" || suffix === "azw3") {
            type = BookType.OTHER
          } else if (suffix === "zip" || suffix === 'cbz') {
            type = BookType.ARCHIVE
          } else {
            // Unsupport
          }
        }
      } else if (bytes[0] === 0x52 && bytes[1] === 0x61 && bytes[2] === 0x72 && bytes[3] === 0x21) {
        // rar or cbr
        throw new Error("CBR not support.")
      } else if (bytes[0] === 0x4D && bytes[1] === 0x4F && bytes[2] === 0x42 && bytes[3] === 0x49) {
        // mobi or azw
        type = BookType.OTHER
      }
      if (!type) {
        throw new Error("Unsupported file type")
      }
      return type
    } finally {
      fs.close(file.fd)
    }
  }

  public static async isFileExists(path: string): Promise<boolean> {
    try {
      let exists = await fs.access(path, fs.AccessModeType.EXIST)
      return exists
    } catch (e) {
      return false
    }
  }

  public static async mkdir(dir: string): Promise<void> {
    let exist = await fs.access(dir, fs.AccessModeType.EXIST)
    if (!exist) {
      await fs.mkdir(dir)
    }
  }

  public static async rmdir(dir: string): Promise<void> {
    // 判断目录是否存在
    if (!(await fs.access(dir))) return;
    // 获取目录下所有子项
    let files: string[] = fs.listFileSync(dir);
    for (const name of files) {
      let fullPath = dir + '/' + name;
      let stat = fs.statSync(fullPath);
      if (stat.isDirectory()) {
        // 递归删除子目录
        await FileUtil.rmdir(fullPath);
      } else {
        // 删除文件
        await fs.unlink(fullPath);
      }
    }
    // 删除当前空目录
    await fs.rmdir(dir);
  }

}