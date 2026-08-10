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

  /**
   * 获取下载缓存目录（在线书籍下载到本地的目录）
   * 下载文件存放在 filesDir 下以 serverId 命名的子目录中
   * @param context 上下文
   * @returns filesDir 路径
   */
  public static getDownloadCacheDir(context: Context): string {
    return context.filesDir
  }

  /**
   * 计算目录的总大小（递归）
   * @param dirPath 目录路径
   * @returns 目录总字节数
   */
  public static async getDirectorySize(dirPath: string): Promise<number> {
    let exists = await FileUtil.isFileExists(dirPath)
    if (!exists) {
      return 0
    }
    let totalSize = 0
    let files: string[] = fs.listFileSync(dirPath)
    for (const name of files) {
      let fullPath = dirPath + '/' + name
      let stat = fs.statSync(fullPath)
      if (stat.isDirectory()) {
        totalSize += await FileUtil.getDirectorySize(fullPath)
      } else {
        totalSize += stat.size
      }
    }
    return totalSize
  }

  /**
   * 获取本地阅读缓存大小
   * @param context 上下文
   * @returns 字节数
   */
  public static async getLocalCopyCacheSize(context: Context): Promise<number> {
    let copyDir = FileUtil.getLocalCopyDir(context)
    return await FileUtil.getDirectorySize(copyDir)
  }

  /**
   * 获取下载缓存大小（排除 local_copy 目录）
   * @param context 上下文
   * @returns 字节数
   */
  public static async getDownloadCacheSize(context: Context): Promise<number> {
    let filesDir = context.filesDir
    let exists = await FileUtil.isFileExists(filesDir)
    if (!exists) {
      return 0
    }
    let totalSize = 0
    let files: string[] = fs.listFileSync(filesDir)
    for (const name of files) {
      // 排除 local_copy 目录，它由阅读缓存管理
      if (name === FileUtil.LOCAL_COPY_DIR) {
        continue
      }
      let fullPath = filesDir + '/' + name
      let stat = fs.statSync(fullPath)
      if (stat.isDirectory()) {
        totalSize += await FileUtil.getDirectorySize(fullPath)
      } else {
        totalSize += stat.size
      }
    }
    return totalSize
  }

  /**
   * 清理所有下载缓存文件（排除 local_copy 目录）
   * @param context 上下文
   */
  public static async clearDownloadCacheFiles(context: Context): Promise<void> {
    let filesDir = context.filesDir
    let exists = await FileUtil.isFileExists(filesDir)
    if (!exists) {
      return
    }
    let files: string[] = fs.listFileSync(filesDir)
    for (const name of files) {
      // 排除 local_copy 目录
      if (name === FileUtil.LOCAL_COPY_DIR) {
        continue
      }
      let fullPath = filesDir + '/' + name
      let stat = fs.statSync(fullPath)
      if (stat.isDirectory()) {
        await FileUtil.rmdir(fullPath)
      } else {
        await fs.unlink(fullPath)
      }
    }
  }

  /**
   * 将字节数格式化为可读的文件大小字符串
   * @param bytes 字节数
   * @returns 格式化后的字符串，如 "1.2 MB"
   */
  public static formatFileSize(bytes: number): string {
    if (bytes <= 0) {
      return "0 B"
    }
    const units: string[] = ["B", "KB", "MB", "GB"]
    let unitIndex = 0
    let size = bytes as number
    while (size >= 1024 && unitIndex < units.length - 1) {
      size = size / 1024
      unitIndex++
    }
    if (unitIndex === 0) {
      return `${size} B`
    }
    // 保留一位小数
    return `${(Math.round(size * 10) / 10).toFixed(1)} ${units[unitIndex]}`
  }
}