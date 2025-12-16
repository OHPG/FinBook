import { MediaArgs } from "../pages/detail/MediaArgs";
import { SearchArgs } from "../pages/search/SearchArgs";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/9/27 9:33
 * @Version V1.0
 * @Description
 */
export class AppRouter {

  public static goToHome(context: UIContext) {
    context.getRouter().replaceUrl({url: 'pages/home/HomePage'})
  }

  public static goToGrid(context: UIContext, args: MediaArgs) {
    context.getRouter().pushUrl({url: 'pages/grid/GridPage', params: args})
  }

  public static goToDetail(context: UIContext, args: MediaArgs) {
    context.getRouter().pushUrl({url: 'pages/detail/DetailPage', params: args})
  }

  public static goToLocalSearch(context: UIContext, args: SearchArgs) {
    context.getRouter().pushUrl({url: 'pages/search/SearchPage', params: args})
  }

  public static goToOnlineSearch(context: UIContext, args: SearchArgs) {
    context.getRouter().pushUrl({url: 'pages/search/SearchPage', params: args})
  }

  public static goToLocalReader(context: UIContext, args: MediaArgs) {
    context.getRouter().pushUrl({url: "pages/read/local/LocalReaderPage", params: args})
  }

  public static goToOnlineReader(context: UIContext, args: MediaArgs) {
    context.getRouter().pushUrl({url: "pages/read/online/OnlineReaderPage", params: args})
  }

  public static goToInterface(context: UIContext) {
    context.getRouter().pushUrl({url: "pages/interface/InterfacePage"})
  }
}