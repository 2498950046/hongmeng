@Entry
@Component
struct Test {


  build() {
      Column() {
        //上

        Column() {
          Row({ space: 10 }) {
            Row().width('30%').height('60%').border({ width: 2 })
            Row().width('30%').height('60%').border({ width: 2 })
            Row().width('30%').height('60%').border({ width: 2 })
          }
          .justifyContent(FlexAlign.Center)
          .height('100%')
          .width('100%')
          .margin({top:10})
        }
        .height('20%')
        .width('100%')
        .padding({bottom:20})
        .border({

          width: { bottom: 2 },
          color: Color.Black
        })

        //中
        Column() {
          Row(){
            Row().width('33%').height('100%').border({width:2})
            Row().width('33%').height('100%').border({width:2})
            Row().width('33%').height('100%').border({width:2})
          }
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.White)
        .height('60%')

        //下
        Column() {
          Row({ space: 30 }) {
            Row().width('15%').height('40%').border({ width: 2 })
            Row().width('15%').height('40%').border({ width: 2 })
            Row().width('15%').height('40%').border({ width: 2 })
            Row().width('15%').height('40%').border({ width: 2 })
          }
        }
        .width('100%')
        .height('20%') // 固定高度
        .justifyContent(FlexAlign.Center)
        .border({
          width: { top: 1 },
          color: '#CCCCCC'})








      }
      .width('100%')
      .height('100%')
    .backgroundColor('#F1F3F5')


  }
}

