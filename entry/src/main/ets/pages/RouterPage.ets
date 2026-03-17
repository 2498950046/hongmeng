@Entry
@Component
struct RouterPage {
  @State message: string = '跳转';
  info : NavPathStack = new NavPathStack();

  build() {

    Navigation(this.info){
      Column(){
        Text(this.message).fontSize(20).fontColor(Color.Black)
          .onClick(()=>
          {
            this.info.pushPathByName("pageList","")
          })
      }
    }
    .width('100%')
    .height('100%')
  }


}