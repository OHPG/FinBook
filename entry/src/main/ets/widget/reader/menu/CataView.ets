import { image } from '@kit.ImageKit';
import { bookParser, readerCore } from '@kit.ReaderKit';
import LazyDataSource from '../../../common/LazyDataSource';
import { CommonConstants } from '../../../common/CommonConstants';

@Component
export struct CataView {

  @Consume bookHandler: bookParser.BookParserHandler

  @Consume @Watch('onSpineChange') bookSpine?: bookParser.SpineItem

  @State bookInfo?: bookParser.BookInfo = undefined

  @State bookCover?: PixelMap = undefined

  @State bookCataList?: Array<bookParser.CatalogItem> = undefined

  @Provide cataIndex: number = 0

  private cataDataSource: LazyDataSource<bookParser.CatalogItem> = new LazyDataSource();

  private cataScroller = new Scroller()

  aboutToAppear(): void {
    // info
    this.bookInfo = this.bookHandler.getBookInfo()
    // cata
    this.bookCataList = this.bookHandler.getCatalogList();
    this.cataDataSource.pushArrayData(this.bookCataList)
    // cover
    let buffer = this.bookHandler.getResourceContent(-1, this.bookInfo.bookCoverImage)
    let imageSource: image.ImageSource = image.createImageSource(buffer);
    this.bookCover = imageSource.createPixelMapSync();
    imageSource.release();
    this.onSpineChange()
  }

  private onSpineChange() {
    // cata index
    let cata = this.bookCataList?.findIndex(item => this.getResourceItemByCatalog(item)?.index === this.bookSpine?.index)
    if (cata && cata >= 0) {
      this.cataIndex = cata
      this.cataScroller.scrollToIndex(cata, false, ScrollAlign.CENTER)
    }
  }

  /**
   * 获取书籍目录对应的资源条目
   * @param catalogItem 目录条目
   */
  getResourceItemByCatalog(catalogItem: bookParser.CatalogItem): bookParser.SpineItem | undefined {
    let resourceFile = catalogItem.resourceFile || '';
    let spineList: bookParser.SpineItem[] = this.bookHandler.getSpineList()
    // 查找目录对应的资源条目
    let resourceItemArr = spineList.filter(item => item.href === resourceFile);
    if (resourceItemArr.length > 0) {
      let resourceItem = resourceItemArr[0];
      return resourceItem;
    } else if (spineList.length > 0) {
      // 如果查找不到，则默认返回第1个资源条目
      return spineList[0];
    } else {
      // 如果没有资源条目，则返回默认值
      return undefined
    }
  }

  build() {
    Column() {
      Row({space: CommonConstants.SPACE_12}) {
        Stack({ alignContent: Alignment.Top }) {
          Image(this.bookCover)
            .draggable(false)
            .width('100%')
            .height('100%')
            .borderRadius(2)
            .alt($r('app.media.default_cover'))
            .backgroundColor($r('sys.color.ohos_id_color_background'))

          Image($r('app.media.default_spines'))
            .draggable(false)
            .width('100%')
            .height('100%')
            .borderRadius(2)

          Image($r('app.media.cover_shadow'))
            .draggable(false)
            .width('100%')
            .height('100%')
            .opacity(0.7)
            .aspectRatio(3)
            .position({ x: 0, y: 90 / 3 / 4 - 90 / 9 })
        }
        .width(90)
        .height(120)
        .shadow({ radius: 18, color: "#4D000000" })
        .borderRadius(2)
        .visibility(this.bookInfo ? Visibility.Visible : Visibility.None)

        Column() {
          Text(this.bookInfo?.bookTitle)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(1)
            .margin({ right: 12, left: 12 })
            .fontWeight(FontWeight.Bold)
            .flexShrink(1)
            .fontColor("#E6000000")
            .height(40)

          Text(`共${this.bookCataList?.length}章`)
            .fontSize(16)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
            .padding({ top: 8, bottom: 8 })
        }
        .width('auto')
        .height(120)
      }
      .width('100%')
      .padding(CommonConstants.SPACE_16)
      .alignSelf(ItemAlign.Center)

      // 章节列表
      List({ initialIndex: this.cataIndex, scroller: this.cataScroller }) {
        LazyForEach(this.cataDataSource, (item: bookParser.CatalogItem, index: number) => {
          ListItem() {
            CataItemView({cataItem: item, itemIndex: index})
          }
        })
      }
      .divider({color: "#ffc4c4c4", strokeWidth: 1, startMargin: CommonConstants.SPACE_16, endMargin: CommonConstants.SPACE_16})
      .scrollBar(BarState.Auto)
      .width('100%')
      .height('auto')
      .layoutWeight(1)
    }
    .backgroundColor($r('sys.color.background_primary'))
    .borderRadius({ topRight: CommonConstants.CORNER_16, topLeft: CommonConstants.CORNER_16 })
    .width('100%')
    .height('80%')
  }
}

@Reusable
@Component
struct CataItemView {

  @StorageLink('bookCtrl') bookCtrl?: readerCore.ReaderComponentController = undefined

  @Consume bookHandler: bookParser.BookParserHandler

  @Consume menuVisible: boolean

  @Consume cataIndex: number

  @State cataItem?: bookParser.CatalogItem = undefined

  @State itemIndex: number = 0

  aboutToAppear(): void {

  }

  aboutToReuse(params: Record<string, ESObject>): void {
    this.cataItem = params["cataItem"]
    this.itemIndex = params["itemIndex"]
  }

  build() {
    Row() {
      Text(' · ')
        .fontSize(14)
        .fontColor(this.itemIndex > this.cataIndex ? $r('app.color.black_90_opacity') : $r('app.color.black_60_opacity'))

      Text(this.cataItem?.catalogName)
        .fontSize(14)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ top: 8, bottom: 8 })
        .maxLines(2)
        .layoutWeight(1)
        .fontColor(this.itemIndex > this.cataIndex ? $r('app.color.black_90_opacity') : $r('app.color.black_60_opacity'))
        .fontWeight(this.itemIndex > this.cataIndex ? 900 : 200)
    }
    .width('100%')
    .height(48)
    .padding({
      left: this.cataItem?.catalogLevel ? this.cataItem.catalogLevel * CommonConstants.SPACE_16 : CommonConstants.SPACE_16,
      right: CommonConstants.SPACE_16,
    })
    .onClick(() => {
      this.jumpToCatalogItem();
    })
  }

  private async jumpToCatalogItem() {
    let domPos = this.bookHandler.getDomPosByCatalogHref(this.cataItem?.href)
    let spineList = this.bookHandler.getSpineList()
    let spine = spineList.find((item) => item.href === this.cataItem?.href)
    this.bookCtrl?.startPlay(spine!.index, domPos)
    this.menuVisible = false
  }

}

