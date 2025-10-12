class NodeParams {
  param: ResourceStr = ""

  constructor(param: ResourceStr) {
    this.param = param;
  }
}

@Builder
function textBuilder(params: NodeParams) {
  Text(params.param)
    .fontSize($r('sys.float.Caption_L'))
    .clip(true)
    .textAlign(TextAlign.Center)
    .fontColor(Color.Black)
}

@Component
export struct FontSlider {
  @Prop pre: string = 'A';
  @Prop  suf: string = 'A';
  @Prop  min: number = 10;
  @Prop  max: number = 100;
  @Prop  step: number = 10;
  @Prop  value: number = 5;
  onSliderChange?: Callback<number>;

  build() {
    Row() {
      textBuilder(new NodeParams(this.pre))
      Slider({
        value: this.value,
        min: this.min,
        max: this.max,
        step: this.step,
        style: SliderStyle.InSet
      })
        .blockColor('#906c6a72')
        .trackColor('#593d3e3d')
        .selectedColor('#003d3e3d')
        .showSteps(true)
        .showTips(false)
        .trackThickness(36)
        .width('80%')
        .constraintSize({maxWidth: 360})
        .onChange(value => {
          this.onSliderChange?.(value)
        })
      textBuilder(new NodeParams(this.suf))
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
  }
}