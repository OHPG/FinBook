import { RefLruCache } from "@ohpg/fin-core";
import { AbilityConstant } from "@kit.AbilityKit";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/9/28 14:50
 * @Version V1.0
 * @Description: 
 */
export class ImageCache extends RefLruCache<number, PixelMap> {

  constructor() {
    super(128 * 1024 * 1024)
  }

  onMemoryLevel(level: AbilityConstant.MemoryLevel) {
    let maxSize: number
    switch (level) {
      case AbilityConstant.MemoryLevel.MEMORY_LEVEL_MODERATE:
        maxSize = this.maxSize / 2
        break;
      case AbilityConstant.MemoryLevel.MEMORY_LEVEL_LOW:
        maxSize = this.maxSize / 4
        break;
      case AbilityConstant.MemoryLevel.MEMORY_LEVEL_CRITICAL:
        maxSize = 0
        break;
      default:
        maxSize = this.maxSize
        break;
    }
    this.trimToSize(maxSize)
  }
}

export const imageCache = new ImageCache()