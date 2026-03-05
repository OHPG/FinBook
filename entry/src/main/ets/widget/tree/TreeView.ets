import { window } from "@kit.ArkUI"
import { CommonConstants } from "../../common/CommonConstants"
import { BookItem } from "../../entity/BookItem"
import { FolderItem } from "../../entity/FolderItem"
import { TreeControl } from "./TreeControl"
import { TreeData } from "./TreeData"
import { AppRouter } from "../../router/AppRouter"
import { TreeHeaderView } from "./TreeHeaderView"
import { TreeBodyView } from "./TreeBodyView"
import LazyDataSource from "../../common/LazyDataSource"
import { MediaArgs } from "../../pages/detail/MediaArgs"

@Component
export struct TreeView {

  @Require control: TreeControl

  @Require readonly mediaData: TreeData

  @Provide emptyOrErrorResource: ResourceStr | undefined = $r('app.string.global_content_empty_simple')

  @State mediaDataIndex: number = 0

  folderCallback?: Callback<FolderItem>

  @StorageProp('currentAvoidArea') avoidArea?: window.AvoidArea = undefined

  private folderDataSource = new LazyDataSource<FolderItem>()

  @State folderDataArray: Array<FolderItem> = new Array<FolderItem>()

  private rootFolder: FolderItem = {
    name: "根目录"
  }

  private currentFolder: FolderItem = this.rootFolder

  private readonly folderItemCallback: Callback<FolderItem> = (item) => {
    this.backwardFolder(item)
  }

  private readonly mediaItemCallback: Callback<BookItem> = (item) => {
    if (item.dir) {
      this.forwardFolder(item)
    } else {
      this.play(item)
    }
  }

  aboutToAppear(): void {
    this.control.callback = (): boolean => {
      if (this.canBackward()) {
        // 缺省回退最后一个
        let lastIndex = this.folderDataSource.totalCount() - 2
        let item = this.folderDataSource.getData(lastIndex)
        this.backwardFolder(item)
        return true
      }
      return false
    }
    this.forwardFolder()
  }

  private canBackward(): boolean {
    return this.folderDataSource.getDataList().length > 1
  }

  private backwardFolder(item: FolderItem) {
    if (this.currentFolder === item) {
      return
    }

    let dataList = this.folderDataSource.getDataList()
    let index = dataList.indexOf(item)
    if (index < 0) {
      return
    }
    for (let i = dataList.length - 1; i > index; i--) {
      this.folderDataSource.deleteData(i)
    }
    this.currentFolder = item
    this.folderDataArray.splice(index + 1)
    this.mediaDataIndex = this.folderDataArray.length - 1
    this.folderCallback?.(this.currentFolder)
  }

  private forwardFolder(item?: BookItem) {
    if (!this.currentFolder) {
      return
    }
    let newFolder: FolderItem
    if (item) {
      newFolder = {
        name: item.name,
        alias: item.alias,
        item: item
      }
    } else {
      newFolder = this.rootFolder
    }
    this.folderDataSource.pushData(newFolder)
    this.folderDataArray.push(newFolder)
    this.mediaDataIndex = this.folderDataArray.length - 1
    this.currentFolder = newFolder
    this.folderCallback?.(newFolder)
  }


  build() {
    Column() {

      // 目录结构
      List() {
        LazyForEach(this.folderDataSource, (item: FolderItem) => {
          ListItem() {
            TreeHeaderView({folderItem: item, callback: this.folderItemCallback})
          }
        })
      }
      .padding({
        left: CommonConstants.SPACE_16,
        right: CommonConstants.SPACE_16
      })
      .scrollBar(BarState.Off)
      .listDirection(Axis.Horizontal)
      .width(CommonConstants.FULL_PERCENT)
      .height(24)

      // 媒体列表
      Stack() {
        Swiper() {
          ForEach(this.folderDataArray, (info: FolderItem) => {
            TreeBodyView({ mediaItemCallback: this.mediaItemCallback, mediaData: this.mediaData, info: info })
          }, (item: FolderItem, index: number) => index.toString())
        }
        .index(this.mediaDataIndex)
        // 取消边缘效果
        .effectMode(EdgeEffect.None)
        // 切换页面动画时长
        .duration(0)
        // 禁用手势滑动
        .disableSwipe(true)
        // 隐藏指示器
        .indicator(false)
        // 禁用循环
        .loop(false)
        .width("100%")
        .height("100%")
      }
      .width(CommonConstants.FULL_PERCENT)
      .layoutWeight(1)
    }
  }

  play(item: BookItem) {
    let playerArgs: MediaArgs = {
      id: item.id,
      name: item.name,
      uri: item.uri
    }
    AppRouter.goToLocalReader(this.getUIContext(), playerArgs)
  }

  aboutToDisappear(): void {
    this.mediaData?.release()
  }

}