import { bookParser, readerCore } from '@kit.ReaderKit';
import { image } from '@kit.ImageKit';

@Component
export struct CataView {

  @Consume bookHandler: bookParser.BookParserHandler

  @Consume bookSpine: bookParser.SpineItem

  @State bookInfo?: bookParser.BookInfo = undefined

  @State bookCover?: PixelMap = undefined

  @State bookCataList?: Array<bookParser.CatalogItem> = undefined

  @State cataIndex: number = 0

  aboutToAppear(): void {
    // info
    this.bookInfo = this.bookHandler.getBookInfo()
    // cata
    this.bookCataList = this.bookHandler.getCatalogList();
    // cata index
    let cata = this.bookCataList.findIndex(item => this.getResourceItemByCatalog(item)?.index ===
      this.bookSpine.index)
    if (cata) {
      this.cataIndex = cata
    }
    let buffer = this.bookHandler.getResourceContent(-1, this.bookInfo.bookCoverImage)
    let imageSource: image.ImageSource = image.createImageSource(buffer);
    this.bookCover = imageSource.createPixelMapSync();
    imageSource.release();
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
      Row() {
        Stack() {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontColor([$r('app.color.ohos_id_color_primary_light')])
            .width(18)
            .fontSize(18)
            .fontWeight(600)
            .renderingStrategy(SymbolRenderingStrategy.SINGLE)
            .effectStrategy(SymbolEffectStrategy.NONE)
        }
        .borderRadius('50%')
        .backgroundColor("#0d777777")
        .align(Alignment.Center)
        .width(40)
        .height(40)
        .margin({ top: 8, left: 16, right: 16 })
        .onClick(() => {
          // this.closeModal();
        })
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.End)

      Row() {
        Stack({ alignContent: Alignment.Top }) {
          Image(this.bookCover)
            .draggable(false)
            .width(42)
            .aspectRatio(3 / 4)
            .borderRadius(2)
            .zIndex(1)
            .alt($r('app.media.default_cover'))
            .backgroundColor($r('sys.color.ohos_id_color_background'))

          Image($r('app.media.default_spines'))
            .draggable(false)
            .aspectRatio(3 / 4)
            .width(42)
            .borderRadius(2)
            .zIndex(2)
            .position({ x: 0, y: 0 })

          Image($r('app.media.cover_shadow'))
            .draggable(false)
            .width(42)
            .opacity(0.7)
            .aspectRatio(3)
            .position({ x: 0, y: 42 / 3 / 4 - 42 / 9 })
            .zIndex(0)
        }
        .width(42)
        .shadow({ radius: 18, color: "#4D000000" })
        .borderRadius(2)
        .aspectRatio(3 / 4)
        .visibility(this.bookInfo ? Visibility.Visible : Visibility.None)

        Text(this.bookInfo?.bookTitle)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)
          .margin({ right: 12, left: 12 })
          .fontWeight(FontWeight.Bold)
          .flexShrink(1)
          .fontColor("#E6000000")
          .height(40)
          .visibility(this.bookInfo?.bookTitle ? Visibility.Visible : Visibility.None)
      }
      .padding({
        left: 16,
        right: 16
      })
      .width('60%')
      .margin({ bottom: 20 })
      .alignSelf(ItemAlign.Center)

      Column() {
        Row() {
          Text(`共${this.bookCataList!.length}章`)
            .fontSize(16)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
            .padding({ top: 8, bottom: 8 })
        }
        .width('100%')

        Divider().color('#ffc4c4c4')
      }
      .width('60%')
      .justifyContent(FlexAlign.Start)

      List({ initialIndex: this.cataIndex }) {
        ForEach(this.bookCataList, (item: bookParser.CatalogItem, index: number) => {
          ListItem() {

          }
        })
      }
      .scrollBar(BarState.Off)
      .width('60%')
      .height('100%')
    }
    .borderRadius({ topRight: 32, topLeft: 32 })
    .backgroundColor(Color.White)
    .width('100%')
  }

}

@Component
@Reusable
struct CataItemView {

  @Consume bookHandler: bookParser.BookParserHandler

  @StorageLink('bookCtrl') bookCtrl?: readerCore.ReaderComponentController = undefined

  @State cataItem?: bookParser.CatalogItem = undefined

  @Link cataIndex: number

  @State cataHighLight: boolean = true

  aboutToAppear(): void {

  }

  aboutToReuse(params: Record<string, ESObject>): void {
    this.cataItem = params["cataItem"]
  }

  build() {
    Column() {
      Row() {
        Row() {
          Text(' · ')
            .fontSize(14)
            .fontColor(this.cataHighLight ? $r('app.color.black_90_opacity') : $r('app.color.black_60_opacity'))
          Text(this.cataItem?.catalogName)
            .fontSize(14)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .padding({ top: 8, bottom: 8 })
            .maxLines(2)
            .layoutWeight(1)
            .fontColor(this.cataHighLight ? $r('app.color.black_90_opacity') : $r('app.color.black_60_opacity'))
            .fontWeight(this.cataHighLight ? 900 : 200)
        }
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Divider()
        .color('#ffc4c4c4')
    }
    .padding({
      left: this.cataItem?.catalogLevel ? this.cataItem.catalogLevel * 26 : 16,
      right: 16,
      top: 6,
      bottom: 6
    })
    .onClick(async () => {
      this.jumpToCatalogItem();
    })
  }

  private async jumpToCatalogItem() {
    let domPos = this.bookHandler.getDomPosByCatalogHref(this.cataItem?.href)
    let spineList = this.bookHandler.getSpineList()
    let spine = spineList.find((item) => item.href === this.cataItem?.href)
    this.bookCtrl?.startPlay(spine!.index, domPos)
  }

}

