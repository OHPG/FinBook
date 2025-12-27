import { BreakpointSystem, FinItem, FinItemType, FinPerson, FinPersonType } from "@ohpg/fin-core"
import { CommonConstants } from "../../common/CommonConstants"
import { DetailViewModel } from "./DetailViewModel"
import { MediaArgs } from "./MediaArgs"
import { AppRouter } from "../../router/AppRouter"
import { CoverImage } from "../../widget/cover/CoverImage"

@Component
export struct DetailOperate {

  @LocalStorageLink("viewModel") viewModel?: DetailViewModel = undefined

  @Require @Prop item?: FinItem = undefined

  @State collecting: boolean = false

  @State collected?: boolean = false

  @State finishing: boolean = false

  @State finished?: boolean = false

  aboutToAppear(): void {
    this.finished = this.item?.data?.played
    this.collected = this.item?.data?.isFavorite
  }

  build() {
    Row({space: CommonConstants.SPACE_8}) {
      Button({type: ButtonType.Capsule}) {
        SymbolGlyph($r('sys.symbol.book_pages_fill_1'))
          .fontColor([$r('sys.color.font_on_primary')])
          .fontSize($r('sys.float.Title_S'))
      }
      .id('episode_play')
      .width(80)
      .height(36)
      .onClick(() => {
        this.playOrNot()
      })

      Blank()
      //
      // Button({type: ButtonType.Circle}) {
      //   if (this.finishing) {
      //     SymbolGlyph($r('sys.symbol.loading'))
      //       .fontSize($r('sys.float.Title_M'))
      //   } else {
      //     SymbolGlyph($r('sys.symbol.checkmark'))
      //       .fontColor([this.finished ? Color.Red : Color.Gray])
      //       .fontSize($r('sys.float.Title_M'))
      //   }
      // }
      // .id('episode_finish')
      // .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
      // .enabled(!this.finishing)
      // .padding(CommonConstants.SPACE_4)
      // .onClick(() => {
      //   this.finishOrNot()
      // })
      //
      // Button({type: ButtonType.Circle}) {
      //   if (this.collecting) {
      //     SymbolGlyph($r('sys.symbol.loading'))
      //       .fontSize($r('sys.float.Title_M'))
      //   } else {
      //     SymbolGlyph(this.collected ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
      //       .fontColor([this.collected ? Color.Red : Color.Gray])
      //       .fontSize($r('sys.float.Title_M'))
      //   }
      // }
      // .id('episode_collect')
      // .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
      // .enabled(!this.collecting)
      // .padding(CommonConstants.SPACE_4)
      // .onClick(() => {
      //   this.collectOrNot()
      // })
    }
  }

  private playOrNot() {
    let args: MediaArgs = {
      id: this.item!.id!,
      name: this.item!.name!
    }
    AppRouter.goToOnlineReader(this.getUIContext(), args)
  }

  private finishOrNot() {
    this.finishing = true
    this.viewModel?.finishOrNot()
      .then((finished) => {
        this.finishing = false
        this.finished = finished
      })
      .catch((error: Error) => {
        this.finishing = false
      })
  }

  private collectOrNot() {
    this.collecting = true
    this.viewModel?.favouriteOrNot()
      .then((collected) => {
        this.collecting = false
        this.collected = collected
      })
      .catch((error: Error) => {
        this.collecting = false
      })
  }

  aboutToDisappear(): void {

  }

}

@Component
export struct DetailHeader {

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT) currentWidthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM

  @StorageProp(BreakpointSystem.CURRENT_HEIGHT_BREAKPOINT) currentHeightBreakpoint: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM

  @Prop item: FinItem

  @State collecting: boolean = false

  @State collected: boolean = false

  @State finishing: boolean = false

  @State finished: boolean = false

  aboutToAppear(): void {
  }

  build() {
    Column({space: CommonConstants.SPACE_12}) {
      Stack() {
        CoverImage({ image: this.item?.image, imageBlur: 15 })
          .width(CommonConstants.FULL_PERCENT)
          .height(CommonConstants.FULL_PERCENT)

        Row()
          .backgroundColor(0x64000000)
          .width(CommonConstants.FULL_PERCENT)
          .height(CommonConstants.FULL_PERCENT)

        CoverImage({ image: this.item?.image })
          .aspectRatio(0.67)
          .height(CommonConstants.FULL_PERCENT)
      }
        .width(CommonConstants.FULL_PERCENT)
        .aspectRatio(this.currentWidthBreakpoint <= WidthBreakpoint.WIDTH_SM ? 1.5 : 3)

      Column({space: CommonConstants.SPACE_12}) {

        Text(this.item.name)
          .fontSize($r('sys.float.Title_M'))

        if (this.item.productionYear) {
          Text(this.item.productionYear)
        }

        if (this.item.type === FinItemType.Book) {
          DetailOperate({
            item: this.item
          })
        }

        Row({space: CommonConstants.SPACE_8}) {
          Text("作者")
          Text(this.item.person?.filter((people) => {
            return people.type === FinPersonType.Author
          })?.map((people) => {
            return people.name
          }).join(","))
        }

        Text(this.item.overview)

      }
      .padding({
        left: CommonConstants.SPACE_16,
        right: CommonConstants.SPACE_16
      })
      .width(CommonConstants.FULL_PERCENT)
      .alignItems(HorizontalAlign.Start)
    }
    .width(CommonConstants.FULL_PERCENT)
  }

  aboutToDisappear(): void {

  }

}