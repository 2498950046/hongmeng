// entry/src/main/ets/pages/EntryToPage.ets
@Entry
@Component
struct EntryToPage {
  // 核心改动：使用 @StorageProp 直接绑定 AppStorage 中的变量
  @StorageProp('passedMessage') message: string = 'Hello World';

  build() {
    RelativeContainer() {
      Text(this.message) // 这里会自动显示 '传递123'
        .id('EntryToPageHelloWorld')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          this.message = 'Welcome';
        })
    }
    .height('100%')
    .width('100%')
  }
}