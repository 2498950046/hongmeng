// 引入你们4个人各自负责的页面组件
import { HomeView } from '../home/HomeView';


interface TabData {
  txt: string;
  iconPath: Resource;
  selectIconPath: Resource;
}

@Entry
@Component
struct MainPage {
  // 修改为《觅食记》的四大金刚模块
  datas: Array<TabData> = [
    { txt: '首页', iconPath: $r('app.media.home1'), selectIconPath: $r('app.media.home2') },
    { txt: '附近', iconPath: $r('app.media.map1'), selectIconPath: $r('app.media.map2') },
    { txt: '发现', iconPath: $r('app.media.share1'), selectIconPath: $r('app.media.share2')},
    { txt: '我的', iconPath: $r('app.media.my1'), selectIconPath:$r('app.media.my2') }
  ];

  // 状态变量，0代表默认显示第一个Tab（首页）
  @State currentIndex: number = 0;

  build() {
    // 整体纵向布局
    Column() {

      // 1. 动态内容展示区
      Column() {
        if (this.currentIndex === 0) {
          // 这里是你(成员A)负责的页面
          HomeView()
        } else if (this.currentIndex === 1) {
          // NearbyView()
        } else if (this.currentIndex === 2) {
          // DiscoverView()
        } else if (this.currentIndex === 3) {
          // ProfileView()
        }
      }
      .layoutWeight(1) // 自动撑开，占满除底栏外的所有垂直空间
      .width('100%')

      // 2. 分割线
      Divider().color('#E5E5E5').strokeWidth(0.5)

      // 3. 底部导航栏 (Tab)
      Row() {
        ForEach(this.datas, (item: TabData, index: number) => {
          // 每个 Tab 按钮
          Column() {
            // 图标
            Image(this.currentIndex === index ? item.selectIconPath : item.iconPath)
              .width(26)
              .height(26)
              .objectFit(ImageFit.Contain)
              .margin({ bottom: 4 })

            // 图标名称
            Text(item.txt)
              .fontSize(12)
              .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
              // 选中时显示美食应用常用的活力橙色，未选中为灰色
              .fontColor(this.currentIndex === index ? '#FF5E00' : '#8A8A8A')
          }
          .layoutWeight(1) // 四个按钮平分宽度
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            // 点击切换状态，利用 ArkUI 的响应式状态刷新上方的内容区
            this.currentIndex = index;
          })
        })
      }
      .width('100%')
      .height(60) // 固定底栏高度
      .backgroundColor('#FFFFFF') // 底栏背景改为纯白更清爽
    }
    .width('100%')
    .height('100%')
  }
}