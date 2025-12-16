import { preferences } from "@kit.ArkData"
import { BookOrientation } from "../enum/BookOrientation"
import { readerCore } from "@kit.ReaderKit"

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/11/9 18:36
 * @Version V1.0
 * @Description
 */
export class AppPrefer {

  public static readonly PREFER = "prefer"

  private static readonly KEY_PRIVACY_GRANT = "privacy_grant"

  private static readonly KEY_BOOK_X_CONFIG = "book_x_config"

  private static readonly KEY_BOOK_ORIENTATION = "book_orientation"

  private readonly preference: preferences.Preferences

  constructor(context: Context) {
    this.preference = preferences.getPreferencesSync(context, { name: "app_prefer" } )
  }

  public isPrivacyGrant(): boolean {
    if (this.preference.hasSync(AppPrefer.KEY_PRIVACY_GRANT)) {
      return this.preference.getSync(AppPrefer.KEY_PRIVACY_GRANT, false) as boolean
    }
    return false
  }

  public setPrivacyGrant(): void {
    this.preference.putSync(AppPrefer.KEY_PRIVACY_GRANT, true)
    this.preference.flush()
  }

  public getBookConfig(): readerCore.ReaderSetting | undefined {
    if (this.preference.hasSync(AppPrefer.KEY_BOOK_X_CONFIG)) {
      let json = this.preference.getSync(AppPrefer.KEY_BOOK_X_CONFIG, undefined)
      if (json) {
        try {
          return JSON.parse(json as string) as readerCore.ReaderSetting
        } catch (e) {
          this.preference.deleteSync(AppPrefer.KEY_BOOK_X_CONFIG)
        }
      }
    }
    return undefined
  }

  public setBookConfig(config: readerCore.ReaderSetting): void {
    try {
      let json = JSON.stringify(config)
      this.preference.putSync(AppPrefer.KEY_BOOK_X_CONFIG, json)
      this.preference.flush()
    } catch (e) {
      // ignore
    }
  }

  /**
   * pdf方向
   * @returns
   */
  public getBookOrientation(): BookOrientation {
    if (this.preference.hasSync(AppPrefer.KEY_BOOK_ORIENTATION)) {
      return this.preference.getSync(AppPrefer.KEY_BOOK_ORIENTATION, BookOrientation.LAND) as number
    }
    return BookOrientation.LAND
  }

  /**
   * 设置pdf方向
   * @param orientation
   */
  public setBookOrientation(orientation: BookOrientation) {
    this.preference.putSync(AppPrefer.KEY_BOOK_ORIENTATION, orientation)
    this.preference.flush()
  }

}