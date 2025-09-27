import { MediaArgs } from "./MediaArgs";
import { LoadType } from "@ohpg/fin-core";
import { SimpleRepository } from "@ohpg/fin-framework";
import { AppViewModel } from "../../lifecycle/AppViewModel";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/23 22:44
 * @Version V1.0
 * @Description 详情
 */
export class DetailViewModel extends AppViewModel implements SimpleRepository {

  protected readonly args: MediaArgs

  constructor(context: Context, args: MediaArgs) {
    super(context)
    this.args = args
  }

  async loadData(type: LoadType): Promise<Object> {
    return await this.repository.getBook(this.args.id)
  }

  async finishOrNot(finish?: boolean): Promise<boolean> {
    if (finish) {
      await this.repository.markUnplayedItem(this.args.id)
      return false
    } else {
      await this.repository.markPlayedItem(this.args.id)
      return true
    }
  }

  async favouriteOrNot(favorite?: boolean): Promise<boolean> {
    if (favorite) {
      await this.repository.unmarkFavoriteItem(this.args.id)
      return false
    } else {
      await this.repository.markFavoriteItem(this.args.id)
      return true
    }
  }

}