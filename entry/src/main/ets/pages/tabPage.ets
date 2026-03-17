import { swiperComponent } from '../home/swiperComponent';

interface data {
  txt: string;
  iconPath: Resource;
  selectIconPath: Resource;
}

@Entry
@Component
struct TabPage {

  datas: Array<data> = [
    { txt: '微信', iconPath: $r('app.media.wechat'), selectIconPath: $r('app.media.wechat2') },
    { txt: '通讯录', iconPath: $r('app.media.like'), selectIconPath: $r('app.media.like2') },
    { txt: '发现', iconPath: $r('app.media.search'), selectIconPath: $r('app.media.search2')},
    { txt: '我', iconPath: $r('app.media.user'), selectIconPath:$r('app.media.user2') }
  ];

  // 状态变量
  @State currentIndex: number = 0;

  build() {
    // 整体纵向布局
    Column() {
      // 内容
      Column() {
        swiperComponent()
      }
      .layoutWeight(1) // 自动撑开，占满剩余垂直空间
      .width('100%')
      .height('30%')



      // 分割线
      Divider().color('#D8D8D8').strokeWidth(0.5)

      //tab
      Row() {
        ForEach(this.datas, (item: data, index: number) => {
          // 每个 Tab 按钮
          Column() {
            // 图标
            Image(this.currentIndex === index ? item.selectIconPath : item.iconPath)
              .width(28)
              .height(28)
              .objectFit(ImageFit.Contain) // 确保图标比例不变形
              .margin({ bottom: 4 })      // 图标和文字之间的间距



            // 图标名称
            Text(item.txt)
              .fontSize(12)
              .fontColor(this.currentIndex === index ? '#07C160' : '#191919') // 选中时显示微信绿
          }
          .layoutWeight(1) // 四个按钮平分宽度
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            // 点击切换状态
            this.currentIndex = index;
          })
        })
      }
      .width('100%')
      .height(60) // 固定底栏高度
      .backgroundColor('#F7F7F7')
    }
    .width('100%')
    .height('100%')
  }
}