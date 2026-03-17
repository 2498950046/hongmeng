@Entry
@Component
struct FlexPage {

  build() {
    Flex({
      direction:FlexDirection.Row,
      wrap:FlexWrap.Wrap,
      justifyContent:FlexAlign.Center,
      alignContent:FlexAlign.Center
    }){
      Flex().width('30%').height('30%').border({width:2})
      Flex().width('30%').height('30%').border({width:2})
      Flex().width('30%').height('30%').border({width:2})
      Flex().width('30%').height('30%').border({width:2})
      Flex().width('30%').height('30%').border({width:2})
      Flex().width('30%').height('30%').border({width:2})
      Flex().width('30%').height('30%').border({width:2})
      Flex().width('30%').height('30%').border({width:2})
      Flex().width('30%').height('30%').border({width:2})


    }
    .width('100%')
    .height('100%')
  }
}