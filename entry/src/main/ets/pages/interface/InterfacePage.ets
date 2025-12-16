import { window } from '@kit.ArkUI'
import { WebTool } from '@ohpg/fin-core'
import { CommonConstants, ToolBar } from '@ohpg/fin-framework'
import { readerCore } from '@kit.ReaderKit'
import { Repository } from '../../data/Repository'
import { AppPrefer } from '../../prefer/AppPrefer'
import { BookOrientation } from '../../enum/BookOrientation'
import { groupAttributeModifier, itemDividerBuilder, windowAttributeModifier } from '../../style/Modifier'

@Entry
@Component
struct InterfacePage {

  private repository: Repository = AppStorage.get(Repository.REPOSITORY)!

  @StorageLink(AppPrefer.PREFER) appPrefer?: AppPrefer = undefined

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

  aboutToAppear(): void {
    this.bookOrientation = this.appPrefer!.getBookOrientation()
    this.bookConfig = this.appPrefer?.getBookConfig()
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
                this.appPrefer?.setBookOrientation(index)
              })
          }
          .width(CommonConstants.FULL_PERCENT)
          .height(60)
          .padding({
            left: CommonConstants.SPACE_16,
            right: CommonConstants.SPACE_16
          })
          itemDividerBuilder()
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