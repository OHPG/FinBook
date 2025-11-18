import { CacheRef } from "@ohpg/fin-core"

export interface ImageLoader {

  load(file: string): Promise<number>

  get(index: number): Promise<CacheRef<PixelMap>>

  release(): Promise<void>
}