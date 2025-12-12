export class StorageInfoTable {

  /**
   * storage info
   */
  static readonly TABLE_NAME = "storage_info"

  /**
   * id
   */
  static readonly ID = "id"

  /**
   * type(dav,smb)
   */
  static readonly TYPE = "type"

  /**
   * name
   */
  static readonly NAME = "name"

  /**
   * url
   */
  static readonly URL = "url"

  /**
   * 认证方式
   */
  static readonly AUTH_TYPE = "auth_type"

  /**
   * 认证名称
   */
  static readonly AUTH_NAME = "auth_name"

  /**
   * 认证密码
   */
  static readonly AUTH_PSW = "auth_psw"

  /**
   * extra
   */
  static readonly EXTRA = "extra"

  /**
   * time
   */
  static readonly TIME = "time"

  /**
   * video info table sql
   */
  static readonly CREATE_SQL = `CREATE TABLE IF NOT EXISTS ${StorageInfoTable.TABLE_NAME} (
    ${StorageInfoTable.ID} CHAR(32) PRIMARY KEY NOT NULL,
    ${StorageInfoTable.TYPE} VARCHAR(8) NOT NULL,
    ${StorageInfoTable.NAME} VARCHAR NOT NULL,
    ${StorageInfoTable.URL} VARCHAR NOT NULL,
    ${StorageInfoTable.AUTH_TYPE} VARCHAR NOT NULL,
    ${StorageInfoTable.AUTH_NAME} VARCHAR,
    ${StorageInfoTable.AUTH_PSW} VARCHAR,
    ${StorageInfoTable.EXTRA} VARCHAR,
    ${StorageInfoTable.TIME} INTEGER NOT NULL
  )`
}