export class StringUtil {

  public static formatFileSize(bytes: number): string {
    if (bytes <= 0) {
      return "0B"
    }

    const units = ['B', 'KB', 'MB', 'GB'];
    let index = 0;

    // 将字节数转换为更高的单位
    let size = bytes;
    while (size >= 1024 && index < units.length - 1) {
      size /= 1024;
      index++;
    }

    // 保留两位小数并返回格式化字符串
    return `${size.toFixed(2)} ${units[index]}`;
  }

  /**
   * 格式化事件
   * @param timestamp 时间戳（秒）
   * @returns
   */
  public static formatTimestamp(timestamp: number): string {
    // 创建一个 Date 对象
    const date = new Date(timestamp * 1000);

    // 获取各个时间部分
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0'); // 月份从0开始
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');

    // 格式化为字符串
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
  }

  public static extractFileName(path: string): string | undefined {
    // 找到最后一个斜杠的位置
    const lastSlashIndex = path.lastIndexOf('/');
    if (lastSlashIndex === -1) return undefined;

    // 截取最后一个斜杠后面的内容
    let fileNameWithParams = path.substring(lastSlashIndex + 1);

    // 去掉查询参数（如果有的话）
    const questionMarkIndex = fileNameWithParams.indexOf('?');
    if (questionMarkIndex !== -1) {
      fileNameWithParams = fileNameWithParams.substring(0, questionMarkIndex);
    }

    // URL 解码
    const decodedFileName = decodeURIComponent(fileNameWithParams);
    return decodedFileName;
  }

}