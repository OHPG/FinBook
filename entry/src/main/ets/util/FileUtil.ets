import fs from '@ohos.file.fs';
import { MD5 } from '@ohpg/fin-core';
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
      if (bytes[0] === 0x25 && bytes[1] === 0x50 && bytes[2] === 0x44 && bytes[3] === 0x46) {
        type = BookType.PDF
      } else if (bytes[0] === 0x50 && bytes[1] === 0x4B) {
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
        type = BookType.OTHER
      }
      return type
    } catch (e) {
      throw e as Error
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

  public static mkdirSync(dir: string) {
    try {
      fs.statSync(dir)
    } catch (e) {
      try {
        fs.mkdirSync(dir)
      } catch (e) {
      }
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

  public static async rmFile(path: string): Promise<void> {
    await fs.unlink(path)
  }

  /**
   * 本地阅读沙盒拷贝目录名
   * 与在线缓存目录分开，方便独立清理
   */
  private static readonly LOCAL_COPY_DIR = "local_copy"

  /**
   * 获取本地阅读沙盒拷贝根目录
   * @param context 上下文
   * @returns 沙盒拷贝根目录路径
   */
  public static getLocalCopyDir(context: Context): string {
    return context.filesDir + "/" + FileUtil.LOCAL_COPY_DIR
  }

  /**
   * 根据文件路径和大小生成唯一标识
   * @param filePath 原始文件路径
   * @param fileSize 文件大小
   * @returns 唯一标识字符串
   */
  private static generateCopyKey(filePath: string, fileSize: number): string {
    return MD5.digestSync(filePath + "|" + fileSize)
  }

  /**
   * 获取文件后缀名
   * @param path 文件路径
   * @returns 后缀名（含点号），如 ".epub"
   */
  private static getFileSuffix(path: string): string {
    let index = path.lastIndexOf(".")
    if (index >= 0) {
      return path.substring(index)
    }
    return ""
  }

  /**
   * 将本地文件拷贝到沙盒目录
   * 使用文件路径+大小作为唯一标识，如果沙盒中已存在则直接返回沙盒路径
   * @param context 上下文
   * @param srcPath 源文件路径
   * @returns 沙盒中的文件路径
   */
  public static async copyToSandbox(context: Context, srcPath: string): Promise<string> {
    let stat = await fs.stat(srcPath)
    let key = FileUtil.generateCopyKey(srcPath, stat.size)
    let suffix = FileUtil.getFileSuffix(srcPath)
    let copyDir = FileUtil.getLocalCopyDir(context)
    await FileUtil.mkdir(copyDir)
    let destPath = copyDir + "/" + key + suffix
    let exists = await FileUtil.isFileExists(destPath)
    if (exists) {
      return destPath
    }
    await fs.copyFile(srcPath, destPath)
    return destPath
  }

  /**
   * 清理所有本地阅读沙盒拷贝文件
   * @param context 上下文
   */
  public static async clearLocalCopyFiles(context: Context): Promise<void> {
    let copyDir = FileUtil.getLocalCopyDir(context)
    let exists = await FileUtil.isFileExists(copyDir)
    if (exists) {
      await FileUtil.rmdir(copyDir)
    }
  }
}