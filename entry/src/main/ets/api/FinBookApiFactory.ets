import { JellyfinFinApi } from "./jellyfin/JellyfinFinApi";
import { ApiFactory, CoreApi, ServerType } from "@ohpg/fin-core";
import { KomgaFinApi } from "./komga/KomgaFinApi";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/9/27 20:04
 * @Version V1.0
 * @Description
 */
export class FinBookApiFactory extends ApiFactory {

  constructor(context: Context) {
    super(context, "FinBook")
  }

  protected onCreateApi<T extends CoreApi>(serverType: ServerType): T {
    if (serverType === ServerType.JELLYFIN) {
      return new JellyfinFinApi(this.context, this.clientInfo, this.deviceInfo) as ESObject as T
    } else if (serverType === ServerType.KOMGA) {
      return new KomgaFinApi(this.context, this.clientInfo, this.deviceInfo) as ESObject as T
    }
    throw new Error(serverType + " not implemented.");
  }

}