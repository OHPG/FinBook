import { AbilityConstant, AbilityStage, Configuration, ConfigurationConstant } from "@kit.AbilityKit";
import { ImageKnife } from "@ohos/imageknife";
import { AppConfig } from "../config/AppConfig";
import { Repository } from "../data/Repository";
import { AppPrefer } from "../prefer/AppPrefer";
import { imageCache } from "../reader/static/ImageCache";
import { AppDataStore } from "../store/AppDataStore";
import { AppThumb } from "../thumb/AppThumb";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/7 9:35
 * @Version V1.0
 * @Description
 */
export class App extends AbilityStage {

  onCreate(): void {
    // https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/arkts-light-dark-color-adaptation-V5#section1421172621111
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    AppStorage.setOrCreate(AppPrefer.PREFER, new AppPrefer(this.context.getApplicationContext()))
    AppStorage.setOrCreate(AppConfig.CONFIG, new AppConfig(this.context.getApplicationContext()))
    AppStorage.setOrCreate(AppThumb.THUMB, new AppThumb(this.context.getApplicationContext()))
    AppStorage.setOrCreate(AppDataStore.APP_DATA_STORE, new AppDataStore(this.context.getApplicationContext()))
    ImageKnife.getInstance().initFileCache(this.context, 1024, 128 * 1024 * 1024)
    AppStorage.setOrCreate(Repository.REPOSITORY, new Repository(this.context.getApplicationContext()))
  }

  onMemoryLevel(level: AbilityConstant.MemoryLevel): void {
    imageCache.onMemoryLevel(level)
  }

  onConfigurationUpdate(newConfig: Configuration): void {
  }

}