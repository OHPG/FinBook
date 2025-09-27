import { pdfService } from '@kit.PDFKit';
import { image } from '@kit.ImageKit';
import { PullToRefresh } from './PullToRefresh/PullToRefresh'
import LoadingDialog from './Loading/loadingView'

class BasicDataSource implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private originDataArray: StringData[] = [];

  public totalCount(): number {
    return 0;
  }

  public getData(index: number): StringData {
    return this.originDataArray[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      console.info('add listener');
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      console.info('remove listener');
      this.listeners.splice(pos, 1);
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    })
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index);
    })
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataChange(index);
    })
  }

  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataDelete(index);
    })
  }

  notifyDataMove(from: number, to: number): void {
    this.listeners.forEach(listener => {
      listener.onDataMove(from, to);
    })
  }
}

class MyDataSource extends BasicDataSource {
  private dataArray: StringData[] = [];

  public dataReload(): void {
    this.dataArray = []; // 清空数组
    this.notifyDataReload(); // 通知数据已重新加载
  }

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): StringData {
    return this.dataArray[index];
  }

  public addData(index: number, data: StringData): void {
    this.dataArray.splice(index, 0, data);
    this.notifyDataAdd(index);
  }

  public pushData(data: StringData): void {
    this.dataArray.push(data);
    this.notifyDataAdd(this.dataArray.length - 1);
    console.log('this.dataArray',this.dataArray.length)
  }

  public deleteData(index: number): void {
    this.dataArray.splice(index, 0);
    this.notifyDataDelete(index);
  }
}

class StringData {
  imgSrc: image.PixelMap;

  constructor(imgSrc: image.PixelMap) {
    this.imgSrc = imgSrc;
  }
}

@Component
export struct PDFView {
  @State data: MyDataSource = new MyDataSource();
  @State totalPage: number = 0;
  @State pageIndex: number = 0;
  @State scrollerPageIndex: number = 0;
  @State currentPdfIndex: number = 0;
  @State pagesPerLoadOn: number = 0

  @Prop pdfPath: string = '';
  header?: Record<string, string> = undefined
  @Prop pagesPerLoad: number = 0
  pdfInit: (totalPage: number,pagesPerLoad: number) => void  = () => {};
  onReachEnd: (totalPage: number) => void  = () => {};
  onScrollIndex: (pageIndex: number) => void  = () => {};

  private document: pdfService.PdfDocument = new pdfService.PdfDocument()
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    LoadingDialog.showLoading('加载中...')
    this.openFile(this.pdfPath);
  }

  // 释放PDF文档
  aboutToDisappear() {
    this.document.releaseDocument()
  }

  getSubstringAfterLastSlash(str: string): string | undefined {
    const parts = str.split('/'); // 使用 / 来分割字符串
    return parts.pop(); // 返回分割后的数组中的最后一个元素
  }

  openFile(filePath: string){
    // 加载PDF
    let loadResult: pdfService.ParseResult = this.document.loadDocument(filePath, '');

    if (loadResult === 0) {
      // 总页数
      this.totalPage = this.document.getPageCount();

      // 如果PDF页数大于10页，就做分页
      if(this.totalPage > 10 && !this.pagesPerLoad){
        this.pagesPerLoadOn = 10;
      }

      // 如果有传入分页，就做分页
      if(this.pagesPerLoad && this.pagesPerLoad < this.totalPage){
        this.pagesPerLoadOn = this.pagesPerLoad;
      }

      this.pdfInit(this.totalPage,this.pagesPerLoadOn)

      this.loadPages(0);
    }
  }

  // 加载页面的递归函数
  async loadPages(startIndex: number) {
    let endIndex: number = this.totalPage;
    if(this.pagesPerLoadOn){
      endIndex = startIndex + this.pagesPerLoadOn;
    }
    for (let index = startIndex; index < endIndex && index < this.totalPage; index++) {
      let page = await this.document.getPage(index);
      let _pixelMaps = await page.getPagePixelMap();
      await this.data.pushData(new StringData(_pixelMaps))
    }

    LoadingDialog.hide()
    this.pageIndex = this.data.totalCount()
  }

  build() {
    Column() {
      Row() {
        PullToRefresh({
          data: $data,
          scroller: this.scroller,
          customList: () => {
            this.getListView();
          },
          onLoadMore: () => {
            return new Promise<string>((resolve, reject) => {
              if (this.pageIndex != this.totalPage) {
                this.loadPages(this.pageIndex)
                resolve('');
              } else {
                reject('');
              }
            });
          },
          customLoad: null,
          customRefresh: null,
        })
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  private getListView() {
    List({ scroller: this.scroller }) {
      LazyForEach(this.data, (item: StringData, index: number) => {
        ListItem() {
          Image(item.imgSrc)
            .width('100%')
        }
      }, (item: StringData, index: number) => index.toString())
    }
    .cachedCount(3)
    .onScrollIndex((firstIndex: number, lastIndex: number, centerIndex: number) => {
      this.scrollerPageIndex = centerIndex + 1
      this.onScrollIndex(lastIndex + 1)
    })
    .backgroundColor('#ddd')
    .divider({ strokeWidth: 1, color: 0x222222 })
    .edgeEffect(EdgeEffect.None) // 必须设置列表为滑动到边缘无效果
  }
}