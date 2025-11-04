import { BlurTransformation, HeaderOptions, ImageKnifeComponent } from "@ohos/imageknife"
import { FinImage } from "@ohpg/fin-core"

@Reusable
@Component
export struct CoverImage {

  @State image?: FinImage = undefined

  @State imageBorderRadius: number = 0

  @State imageBlur: number = 0

  private imageHeaderOptions?: Array<HeaderOptions> = undefined

  aboutToAppear(): void {
    this.updateHeader()
  }

  aboutToReuse(params: Record<string, Object | null | undefined>): void {
    this.image = params["image"] as FinImage
    this.updateHeader()
  }

  private updateHeader() {
    this.imageHeaderOptions = undefined
    if (!(this.image?.header)) return
    let header = this.image.header
    let options = new Array<HeaderOptions>()
    Object.keys(header)
      .forEach((key) => {
        options.push({
          key: key,
          value: header[key]
        })
      })
    this.imageHeaderOptions = options
  }

  build() {
    ImageKnifeComponent({
      imageKnifeOption: {
        loadSrc:this.image?.primary,
        headerOption: this.imageHeaderOptions,
        placeholderSrc: $r("app.media.alt"),
        errorholderSrc: $r("app.media.alt"),
        transformation: this.imageBlur > 0 ? new BlurTransformation(this.imageBlur) : undefined,
        objectFit: ImageFit.Cover,
        border: {
          radius: this.imageBorderRadius
        }
      }
    })
  }

}