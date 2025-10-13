import { preferences } from "@kit.ArkData"

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

  public getBookConfig(): string | undefined {
    if (this.preference.hasSync(AppPrefer.KEY_BOOK_X_CONFIG)) {
      return this.preference.getSync(AppPrefer.KEY_BOOK_X_CONFIG, '') as string
    }
    return undefined
  }

  public setBookConfig(config: string): void {
    this.preference.putSync(AppPrefer.KEY_BOOK_X_CONFIG, config)
    this.preference.flush()
  }

}