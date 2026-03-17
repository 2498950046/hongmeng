

@Builder
function listPageBuild(){
ListPage()
}

@Entry
@Component
struct ListPage {
  @State name: string[] = ['cd', 'sh', 'js', 'dw', 'gg', 'vb', 'nb', 'jh', 'jk', 'jl', 'hl', 'hp', 'hi', 'we'];
  @State selectedIndex: number = -1;


  build() {
    NavDestination() {
      Column() {
        // 顶部
        Flex({ alignItems: ItemAlign.Center }) {
          Flex({ justifyContent: FlexAlign.Center }) {
            Text('序号').fontColor(Color.White).fontWeight(FontWeight.Bold)
          }.flexGrow(1)

          Divider().vertical(true).strokeWidth(2).color(Color.White).height('60%')

          Flex({ justifyContent: FlexAlign.Center }) {
            Text('地址').fontColor(Color.White).fontWeight(FontWeight.Bold)
          }.flexGrow(3)
        }
        .width('100%')
        .height('10%')
        .backgroundColor('#ff00a2fd')

        // 列表
        List() {
          ForEach(this.name, (item: string, index: number) => {
            ListItem() {
              Flex({ alignItems: ItemAlign.Center }) {
                // 序号列
                Flex({ justifyContent: FlexAlign.Center }) {
                  Text(`${index + 1}`)
                }.flexGrow(1)

                Divider().vertical(true).strokeWidth(1).height('40%').color('#ccc')

                // 地址列
                Flex({ justifyContent: FlexAlign.Center }) {
                  Text(item)
                }.flexGrow(3)
              }
              .width('100%')
              .height(50)
              .backgroundColor(this.selectedIndex === index ? '#FFE4C4' : (index % 2 === 0 ? '#ffffff' : '#f2f2f2'))
            }
            //点击高亮
            .onClick(() => {
              this.selectedIndex = index
            })

          }, (item: string) => item)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: '#e0e0e0' })

      }
      .width('100%')
      .height('100%')
    }
  }
}