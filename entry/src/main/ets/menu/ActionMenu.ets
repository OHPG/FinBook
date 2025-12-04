import { Pair } from "../comp/Pair"
import { MenuType } from "../enum/MenuType"

@Builder
export function actionMenuMediaItem(obj: object, callback?: Callback<Pair<MenuType, object>>) {

  Text($r('app.string.menu_delete'))
    .fontSize(16)
    .fontColor(Color.White)
    .backgroundColor(Color.Red)
    .borderRadius(16)
    .textAlign(TextAlign.Center)
    .width(100)
    .height('100%')
    .onClick(() => {
      callback?.({first: MenuType.DELETE, second: obj})
    })

}