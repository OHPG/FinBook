export class TypeUtil {

  private static readonly BOOK_SUFFIX = [

    /**
     * txt
     */
    "txt", "text",

    /**
     * cbz
     */
    "cbz", "zip",

    /**
     * pdf
     */
    "pdf",

    /**
     * epub
     */
    "epub",

    /**
     * mobi
     */
    "mobi",

    /**
     * azw
     */
    "azw",

    /**
     * azw3
     */
    "azw3",
  ]

  /**
   * 系统阅读器会在目标目录产生临时文件的格式
   * 需要先拷贝到沙盒再阅读
   */
  private static readonly SANDBOX_COPY_SUFFIX = ["epub", "mobi", "azw", "azw3"]

  /**
   * https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/reader-introduction#section734449121014
   * @param name
   * @returns
   */
  public static isBook(name: string): boolean {
    if (!name || name.length <= 0) {
      return false
    }
    let index = name.lastIndexOf(".")
    if (index < 0 || index + 1 >= name.length) {
      return false
    }
    let suffix = name.substring(index + 1).toLowerCase()
    return TypeUtil.BOOK_SUFFIX.includes(suffix)
  }

  /**
   * 判断文件是否需要拷贝到沙盒后再阅读
   * epub、mobi、azw、azw3 格式的文件，系统阅读器会在目标目录产生临时文件
   * @param name 文件名
   * @returns 是否需要沙盒拷贝
   */
  public static needSandboxCopy(name: string): boolean {
    if (!name || name.length <= 0) {
      return false
    }
    let index = name.lastIndexOf(".")
    if (index < 0 || index + 1 >= name.length) {
      return false
    }
    let suffix = name.substring(index + 1).toLowerCase()
    return TypeUtil.SANDBOX_COPY_SUFFIX.includes(suffix)
  }

}