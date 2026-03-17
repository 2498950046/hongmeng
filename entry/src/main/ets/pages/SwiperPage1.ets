//全局自定义构建函数
@Builder
function GlobalSwiperBuilder(messages: string[]) {
  Swiper() {
    ForEach(messages, (value: string) => {
      Text(value)
        .width('100%')
        .height('100%')
        .fontSize(30)
        .textAlign(TextAlign.Center)
        .fontWeight(500)
        .backgroundColor('#f1f3f5')
    }, (item: string) => item)
  }
  .autoPlay(true)
  .interval(2000)
  .loop(true)
  .width('90%')
  .height('50%')
  .indicator(
    Indicator.digit()
      .fontColor(Color.Gray)
      .selectedFontColor(Color.Blue)
      .digitFont({ size: 20 })
  )
}


@Entry
@Component
struct SwiperPage1 {
  @State message: string[] = ['Java', 'JavaScript', 'Python', 'GO', 'ArkTS'];

  // 私有自定义构建函数
  @Builder
  MySwiperBuilder() {
    Swiper() {
      ForEach(this.message, (value: string) => {
        Text(value)
          .width('100%')
          .height('100%')
          .fontSize(30)
          .textAlign(TextAlign.Center)
          .fontWeight(500)
          .backgroundColor('#f1f3f5')
      }, (item: string) => item) // 建议给 ForEach 加个键值生成器
    }
    .autoPlay(true)
    .interval(2000)
    .loop(true)
    .width('90%')
    .height('50%')
    // 实例化指示器
    .indicator(
      Indicator.digit()
        .fontColor(Color.Gray)
        .selectedFontColor(Color.Blue)
        .digitFont({ size: 20 })
    )
  }

  build() {
    Column() {
      // 调用自定义构建函数 (注意前面要有 this)

      // this.MySwiperBuilder()
      GlobalSwiperBuilder(this.message)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}