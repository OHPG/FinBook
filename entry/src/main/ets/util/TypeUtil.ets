export class TypeUtil {

  private static readonly BOOK_SUFFIX = [
    /**
     * txt
     */
    "txt",

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

}