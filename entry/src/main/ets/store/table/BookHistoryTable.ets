export class BookHistoryTable {

  /**
   * book history
   */
  static readonly TABLE_NAME = "book_history"

  /**
   * id
   */
  static readonly ID = "id"

  /**
   * file uri or path or url
   */
  static readonly SOURCE = "source"

  /**
   * time
   */
  static readonly TIME = "time"

  /**
   * page count
   */
  static readonly PAGES = "pages"

  /**
   * page index
   */
  static readonly PAGE = "page"

  /**
   * 附加数据
   */
  static readonly EXTRA = "extra"

  /**
   * book history table sql
   */
  static readonly CREATE_SQL = `CREATE TABLE IF NOT EXISTS ${BookHistoryTable.TABLE_NAME} (
    ${BookHistoryTable.ID} CHAR(32) PRIMARY KEY NOT NULL,
    ${BookHistoryTable.SOURCE} VARCHAR(255) NOT NULL,
    ${BookHistoryTable.TIME} INTEGER NOT NULL,
    ${BookHistoryTable.PAGES} INTEGER NOT NULL,
    ${BookHistoryTable.PAGE} INTEGER NOT NULL,
    ${BookHistoryTable.EXTRA} VARCHAR
  )`

}