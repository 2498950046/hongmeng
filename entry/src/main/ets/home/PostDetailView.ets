import router from '@ohos.router';


interface FoodItem {
  id: string;
  title: string;
  author: string;
  likes: number;
  imgUrl: string;
  category: string;
  imgHeight: number;
}


@Entry
@Component
struct PostDetailView {


  @State postInfo: FoodItem = {
    id: '',
    title: '',
    author: '',
    likes: 0,
    imgUrl: '',
    category: '',
    imgHeight: 0
  } as FoodItem;

  @State isLiked: boolean = false;

  aboutToAppear() {

    const params = router.getParams() as Record<string, Object>;

    // 使用中括号的方式安全读取属性
    if (params && params['postData']) {
      this.postInfo = params['postData'] as FoodItem;
    }
  }



  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 1. 页面主体内容：支持上下滑动
      Scroll() {
        Column() {
          // ================== A. 沉浸式大图展示 ==================
          Stack({ alignContent: Alignment.TopStart }) {
            Image(this.postInfo.imgUrl)
              .width('100%')
              .height(450) // 详情页图片通常更大，给用户沉浸感
              .objectFit(ImageFit.Cover)

            // 返回按钮（悬浮在图片左上角）
            Row() {
              Text('❮')
                .fontSize(20)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
            }
            .width(40).height(40)
            .backgroundColor('rgba(0,0,0,0.4)') // 半透明黑底，防止图片太白看不清返回键
            .borderRadius(20)
            .justifyContent(FlexAlign.Center)
            .margin({ top: 40, left: 15 }) // top 40 用于避开手机顶部的状态栏
            .onClick(() => {
              router.back();
            })
          }
          .width('100%')

          // ================== B. 帖子基本信息 ==================
          Column() {
            // 作者信息行
            Row() {
              // 假头像
              Circle({ width: 40, height: 40 }).fill('#E5E5E5').margin({ right: 10 })

              Text(this.postInfo.author)
                .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#333333')
                .layoutWeight(1)

              // 关注按钮
              Button('关注')
                .width(60).height(28).fontSize(12)
                .backgroundColor('#FF5E00').fontColor('#FFFFFF')
            }
            .width('100%').margin({ bottom: 20 })

            // 标题
            Text(this.postInfo.title)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
              .margin({ bottom: 15 })

            // 正文假数据（因为首页没传 content，这里写死一段示意）
            Text(`今天来打卡了这家被无数人安利的${this.postInfo.category}店！\n\n味道真的绝了，强烈推荐大家周末来试试，绝对不会踩雷哦！环境也很适合拍照打卡📷。`)
              .fontSize(16)
              .fontColor('#444444')
              .lineHeight(26)
              .margin({ bottom: 20 })

            // 发布时间与分类标签
            Row() {
              Text(`03-18 发布`)
                .fontSize(12).fontColor('#999999').margin({ right: 15 })

              Text(`# ${this.postInfo.category}`)
                .fontSize(12).fontColor('#FF5E00')
                .backgroundColor('#FFF3E0')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(12)
            }
            .width('100%')

            // 底部留白，防止被悬浮的操作栏挡住
            Blank().height(80)
          }
          .width('100%')
          .padding(20)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .backgroundColor('#FFFFFF')

      // 2. 底部悬浮操作栏（点赞、收藏、评论）
      Row() {
        // 假装有个评论框
        Row() {
          Text('说点什么...').fontSize(14).fontColor('#999999')
        }
        .layoutWeight(1)
        .height(36)
        .backgroundColor('#F5F5F5')
        .borderRadius(18)
        .padding({ left: 15 })
        .margin({ right: 20 })

        // 交互按钮
        Row({ space: 15 }) {
          // 点赞按钮 (带交互切换)
          Row() {
            Text(this.isLiked ? '❤️' : '🤍').fontSize(22).margin({ right: 4 })
            Text(this.isLiked ? (this.postInfo.likes + 1).toString() : this.postInfo.likes.toString())
              .fontSize(14).fontColor('#333333')
          }
          .onClick(() => {
            // 点击切换点赞状态
            animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
              this.isLiked = !this.isLiked;
            });
          })

          // 收藏按钮
          Row() {
            Text('⭐').fontSize(22).margin({ right: 4 })
            Text('收藏').fontSize(14).fontColor('#333333')
          }
        }
      }
      .width('100%')
      .height(60)
      .backgroundColor('#FFFFFF')
      // 给底部栏加一个顶部的轻微阴影，和正文隔开
      .shadow({ radius: 10, color: '#1A000000', offsetY: -2 })
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
  }






  // 加上原地的渐变转场动画，保持和首页体验一致
  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.EaseInOut })
      .opacity(0).translate({ x: 0, y: 0 })
    PageTransitionExit({ duration: 300, curve: Curve.EaseInOut })
      .opacity(0).translate({ x: 0, y: 0 })
  }
}