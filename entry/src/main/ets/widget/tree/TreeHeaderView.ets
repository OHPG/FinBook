import { FolderItem } from "../../entity/FolderItem"

@Reusable
@Component
export struct TreeHeaderView {

  @Require callback?: Callback<FolderItem>

  @Require @State folderItem?: FolderItem = undefined

  aboutToAppear(): void {

  }

  aboutToReuse(params: Record<string, object>): void {
    this.folderItem = params['folderItem'] as FolderItem
  }

  build() {
    Row() {
      Text((this.folderItem?.alias || this.folderItem?.name))
        .height(14)
      Text(" > ")
        .height(14)
    }
    .onClick(() => {
      this.callback?.(this.folderItem)
    })
  }

  aboutToRecycle(): void {

  }

  aboutToDisappear(): void {

  }

}