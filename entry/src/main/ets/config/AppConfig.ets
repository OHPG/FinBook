import { FinPageSize, FinSortBy, FinSortOrder } from "@ohpg/fin-core";
import { AppPrefer } from "../prefer/AppPrefer";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2026/3/10 22:32
 * @Version V1.0
 * @Description
 */
export class AppConfig {

  public static readonly CONFIG = "config"

  private readonly context: Context

  sortBy: FinSortBy = FinSortBy.Name

  sortOrder: FinSortOrder = FinSortOrder.Ascending

  pageSize: FinPageSize = FinPageSize.Size_50

  constructor(context: Context) {
    this.context = context
    let prefer: AppPrefer = AppStorage.get(AppPrefer.PREFER)!
    this.pageSize = prefer.getPageSize()
  }

}