import { window } from '@kit.ArkUI'
import { WebTool } from '@ohpg/fin-core'
import { FinPageSize } from '@ohpg/fin-core'
import { CommonConstants, ToolBar } from '@ohpg/fin-framework'
import { readerCore } from '@kit.ReaderKit'
import { AppConfig } from '../../config/AppConfig'
import { Repository } from '../../data/Repository'
import { AppPrefer } from '../../prefer/AppPrefer'
import { BookOrientation } from '../../enum/BookOrientation'
import { groupAttributeModifier, itemDividerBuilder, windowAttributeModifier } from '../../style/Modifier'

@Entry
@Component
struct InterfacePage {

  @StorageLink(AppConfig.CONFIG) appConfig?: AppConfig = undefined

  private appPrefer: AppPrefer = AppStorage.get(AppPrefer.PREFER)!

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @State bookOrientation: BookOrientation = 1

  @State bookConfig?: readerCore.ReaderSetting = undefined

  private orientationArray: Array<SelectOption> = [
    {
      value: $r('app.string.prefer_interface_orientation_land')
    },
    {
      value: $r('app.string.prefer_interface_orientation_prot')
    }
  ]

  private pageSizeArray: Array<FinPageSize> = [
    FinPageSize.Size_25,
    FinPageSize.Size_50,
    FinPageSize.Size_100
  ]

  private pageSizeSelectionArray: Array<SelectOption> = [
    {
      value: FinPageSize.Size_25.toString()
    },
    {
      value: FinPageSize.Size_50.toString()
    },
    {
      value: FinPageSize.Size_100.toString()
    }
  ]

  @State pageSizeIndex: number = 1

  aboutToAppear(): void {
    this.bookOrientation = this.appPrefer.getBookOrientation()
    let pageSize = this.appPrefer.getPageSize()
    this.pageSizeIndex = this.pageSizeArray.findIndex((value) => value === pageSize)
    this.bookConfig = this.appPrefer.getBookConfig()
  }

  @Builder
  preferItemBuilder(icon: Resource, title: ResourceStr, callback: Callback<void>) {
    Row({space: CommonConstants.SPACE_12}) {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([$r('sys.color.ohos_id_color_text_primary')])
      Text(title)
        .fontSize(18)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
      Blank()
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(60)
    .padding({
      left: CommonConstants.SPACE_16,
      right: CommonConstants.SPACE_16
    })
    .onClick(() => {
      callback()
    })
  }

  build() {
    Column({space: CommonConstants.SPACE_8}) {
      ToolBar({
        title: $r('app.string.prefer_interface'),
      })
      Scroll() {
        Column() {
          Row({space: CommonConstants.SPACE_8}) {
            SymbolGlyph($r('sys.symbol.pdf_doc'))
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_text_primary')])
            Text($r('app.string.prefer_interface_orientation'))
              .fontSize(18)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
            Blank()
            Select(this.orientationArray)
              .selected(this.bookOrientation)
              .value(this.orientationArray[this.bookOrientation].value)
              .onSelect((index) => {
                this.appPrefer.setBookOrientation(index)
              })
          }
          .width(CommonConstants.FULL_PERCENT)
          .height(60)
          .padding({
            left: CommonConstants.SPACE_16,
            right: CommonConstants.SPACE_16
          })

          itemDividerBuilder()

          Row({space: CommonConstants.SPACE_8}) {
            SymbolGlyph($r('sys.symbol.flipping_page_fill'))
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_text_primary')])
            Text($r('app.string.prefer_interface_page_size'))
              .fontSize(18)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
            Blank()
            Select(this.pageSizeSelectionArray)
              .selected(this.pageSizeIndex)
              .value(this.pageSizeSelectionArray[this.pageSizeIndex].value)
              .onSelect((index) => {
                this.pageSizeIndex = index
                let pageSize = this.pageSizeArray[index]
                this.appPrefer.setPageSize(pageSize)
                this.appConfig!.pageSize = pageSize
              })
          }
          .width(CommonConstants.FULL_PERCENT)
          .height(60)
          .padding({
            left: CommonConstants.SPACE_16,
            right: CommonConstants.SPACE_16
          })
        }
        .attributeModifier(groupAttributeModifier)
      }
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Fade)
      .width(CommonConstants.FULL_PERCENT)
      .height('auto')
      .layoutWeight(1)
    }
    .padding({
      bottom: px2vp(this.currentAvoidArea?.bottomRect.height)
    })
    .attributeModifier(windowAttributeModifier)
  }

  aboutToDisappear(): void {

  }

}