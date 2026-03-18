import { RdbManager } from '../utils/RdbManager';
import router from '@ohos.router';
import type { User } from '../types';

@Component
export struct ProfileView {
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false;
  @StorageLink('currentUser') currentUser: User | null = null;

  @State collectionsCount: number = 0;
  @State likedPostsCount: number = 0;

  aboutToAppear() {
    this.loadUserData();
  }

  async loadUserData() {
    if (this.currentUser) {
      try {
        // 加载收藏数量
        const restaurantCollections = await RdbManager.getUserCollections(this.currentUser.user_id, 1);
        const postCollections = await RdbManager.getUserCollections(this.currentUser.user_id, 2);
        this.collectionsCount = restaurantCollections.length;
        this.likedPostsCount = postCollections.length;
      } catch (err) {
        console.warn('加载用户数据失败，使用默认值:', JSON.stringify(err));
        this.collectionsCount = 0;
        this.likedPostsCount = 0;
      }
    }
  }

  handleLogin() {
    router.pushUrl({
      url: 'login/LoginPage'
    });
  }

  handleLogout() {
    // 清除登录状态
    AppStorage.setOrCreate('isLoggedIn', false);
    AppStorage.setOrCreate('currentUser', null);
    this.collectionsCount = 0;
    this.likedPostsCount = 0;
  }

  navigateToCollections() {
    if (this.isLoggedIn) {
      router.pushUrl({
        url: 'login/CollectionsPage'
      });
    } else {
      this.handleLogin();
    }
  }

  build() {
    Column() {
      if (!this.isLoggedIn) {
        // 未登录状态
        this.buildGuestView()
      } else {
        // 已登录状态
        this.buildUserView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }

  @Builder
  buildGuestView() {
    Column() {
      // 用户头像占位
      Image($r('app.media.my1'))
        .width(80)
        .height(80)
        .borderRadius(40)
        .margin({ top: 100, bottom: 20 })

      Text('登录觅食记')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 10 })

      Text('登录后查看个人收藏和足迹')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 40 })

      Button('立即登录')
        .width(200)
        .height(45)
        .backgroundColor('#FF5E00')
        .fontColor('#FFFFFF')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .borderRadius(22)
        .onClick(() => {
          this.handleLogin();
        })

    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildUserView() {
    Scroll() {
      Column() {
        // 用户信息卡片
        Column() {
          // 用户头像和基本信息
          Row() {
            Image($r('app.media.my2'))
              .width(60)
              .height(60)
              .borderRadius(30)
              .margin({ right: 15 })

            Column() {
              Text(this.currentUser?.nickname || '用户')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')

              Text(`ID: ${this.currentUser?.user_id?.substring(0, 8)}...`)
                .fontSize(12)
                .fontColor('#666666')
                .margin({ top: 4 })
            }
            .layoutWeight(1)

            // 编辑资料按钮
            Button('编辑资料')
              .width(80)
              .height(30)
              .fontSize(12)
              .border({
                width: 1,
                color: '#FF5E00'
              })
              .backgroundColor('#FFFFFF')
              .fontColor('#FF5E00')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ bottom: 15 })

        }

        // 数据统计
        Row() {
          // 收藏统计
          Column() {
            Text(this.collectionsCount.toString())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF5E00')
            
            Text('收藏店铺')
              .fontSize(12)
              .fontColor('#666666')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding(15)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ right: 8 })
          .onClick(() => {
            this.navigateToCollections();
          })

          // 点赞统计
          Column() {
            Text(this.likedPostsCount.toString())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF5E00')
            
            Text('点赞帖子')
              .fontSize(12)
              .fontColor('#666666')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding(15)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 8 })

        }
        .width('100%')
        .margin({ bottom: 20 })

        // 功能菜单
        Column() {
          // 我的收藏
          this.buildMenuItem('我的收藏', $r('app.media.home1'), () => {
            this.navigateToCollections();
          })

          // 设置
          this.buildMenuItem('设置', $r('app.media.home1'), () => {
            // 跳转到设置页面
          })

          // 关于我们
          this.buildMenuItem('关于我们', $r('app.media.home1'), () => {
            // 跳转到关于页面
          })

          // 退出登录
          this.buildMenuItem('退出登录', $r('app.media.home1'), () => {
            this.handleLogout();
          }, true)

        }
        .width('100%')

      }
      .width('100%')
      .padding(15)
    }
  }

  @Builder
  buildMenuItem(title: string, icon: Resource, onClick: () => void, isDanger: boolean = false) {
    Row() {
      Image(icon)
        .width(20)
        .height(20)
        .margin({ right: 12 })

      Text(title)
        .fontSize(16)
        .fontColor(isDanger ? '#FF3B30' : '#333333')
        .layoutWeight(1)

      Image($r('app.media.home1'))
        .width(16)
        .height(16)
    }
    .width('100%')
    .height(50)
    .padding({ left: 15, right: 15 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 10 })
    .onClick(onClick)
  }
}