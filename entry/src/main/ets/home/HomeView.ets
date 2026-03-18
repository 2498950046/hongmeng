import { swiperComponent } from "./swiperComponent";
import router from "@ohos.router";

// 1. 数据结构新增 category (分类) 字段
interface FoodItem {
  id: string;
  title: string;
  author: string;
  likes: number;
  imgUrl: string;
  imgHeight: number;
  category: string;  // <--- 新增字段，用于和金刚区匹配
}

@Component
export struct HomeView {
  @State searchTxt: string = '';
  private categories: string[] = ['🥘 火锅', '🍢 烧烤', '🍰 甜品', '☕ 咖啡', '🍣 日料'];

  // 滚动控制器与悬浮按钮状态
  private scroller: Scroller = new Scroller();
  @State isShowTopBtn: boolean = false;

  // 2. 新增：记录当前选中的分类，默认为空（表示看全部）
  @State selectedCategory: string = '';

  // 模拟数据：为每一项都加上了对应的 category 字段
  @State foodList: FoodItem[] = [
    { id: '1', title: '藏在巷子里的神仙烤肉！', author: '小吃货', likes: 256, imgHeight: 180, category: '烧烤', imgUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60' },
    { id: '2', title: '周末打卡超火的网红咖啡店☕', author: '探店达人', likes: 128, imgHeight: 220, category: '咖啡', imgUrl: 'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60' },
    { id: '3', title: '这家寿喜锅我能吃一辈子', author: '干饭王', likes: 89, imgHeight: 160, category: '日料', imgUrl: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60' },
    { id: '4', title: '爆浆抹茶舒芙蕾，甜品控必看', author: '甜甜圈', likes: 512, imgHeight: 200, category: '甜品', imgUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60' },
    { id: '5', title: '深夜放毒：路边摊的麻辣烫', author: '夜猫子', likes: 66, imgHeight: 190, category: '火锅', imgUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60' },
    { id: '6', title: '排队两小时才吃到的正宗老火锅', author: '辣妹子', likes: 341, imgHeight: 210, category: '火锅', imgUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60' },
  ];

  @State leftColList: FoodItem[] = [];
  @State rightColList: FoodItem[] = [];

  // 3. 核心方法：根据分类过滤瀑布流数据
  filterData(targetCategory: string) {
    // 如果点击的是已经选中的分类，则取消选中，展示全部数据
    if (this.selectedCategory === targetCategory) {
      this.selectedCategory = '';
      this.leftColList = this.foodList.filter((_, index) => index % 2 === 0);
      this.rightColList = this.foodList.filter((_, index) => index % 2 !== 0);
    } else {
      this.selectedCategory = targetCategory;
      // 利用 includes 匹配，例如 '🥘 火锅'.includes('火锅') 为 true
      let filteredList = this.foodList.filter(item => targetCategory.includes(item.category));

      this.leftColList = filteredList.filter((_, index) => index % 2 === 0);
      this.rightColList = filteredList.filter((_, index) => index % 2 !== 0);
    }
  }

  aboutToAppear() {
    // 初始化时展示全部（等同于执行一次取消选中）
    this.filterData('');
  }

  // 抽取单个卡片为一个局部构建函数，代码更简洁
  @Builder
  FoodCard(item: FoodItem) {
    Column() {
      Image(item.imgUrl)
        .width('100%')
        .height(item.imgHeight)
        .objectFit(ImageFit.Cover)
        .borderRadius({ topLeft: 8, topRight: 8 })

      Column() {
        Text(item.title)
          .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333333')
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ bottom: 8 })

        Row() {
          Text(item.author).fontSize(11).fontColor('#999999')
          Row() {
            Text('❤️').fontSize(10).margin({ right: 2 })
            Text(item.likes.toString()).fontSize(11).fontColor('#999999')
          }
        }.width('100%').justifyContent(FlexAlign.SpaceBetween)
      }.padding(8).alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 10 })
    .shadow({ radius: 4, color: '#0A000000', offsetY: 2 })
    // ================= 👇 新增的跳转逻辑 =================
    .onClick(() => {
      router.pushUrl({
        url: 'home/PostDetailView', // 假设你的详情页建在 home 文件夹下，请确保并在 main_pages.json 中注册
        params: {
          postData: item // 将整个 item 对象作为参数传过去
        }
      })
    })
    // ====================================================

  }


  //主显示
  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Scroll(this.scroller) {
        Column() {
          // ========== 1. 顶部搜索栏 ==========

          Row() {
            Search({ placeholder: '搜一搜附近的神仙美食...' })

              .width('100%')
              .height(40)
              .backgroundColor('#F5F5F5')
              .focusable(false) // 让首页的搜索框失去焦点，防止弹出输入法键盘
              .onClick(() => {
                // 点击直接跳转到专业的搜索页面
                router.pushUrl({
                  url: 'home/SearchView' // 确保这里和你的真实文件路径一致！
                })
              })
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 10, bottom: 10 })
          .backgroundColor('#FFFFFF')



          // ========== 2. 轮播图 ==========
          swiperComponent()

          // ========== 3. 金刚区 (修改点) ==========
          Row() {
            ForEach(this.categories, (item: string) => {
              Column() {
                // 如果当前 item 被选中，背景色变为主题橙色，否则为浅橙色
                Circle({ width: 45, height: 45 })
                  .fill(this.selectedCategory === item ? '#FF5E00' : '#FFF3E0')
                  .margin({ bottom: 6 })

                // 选中时，文字变成白色加粗；未选中为深灰色
                Text(item)
                  .fontSize(12)
                  .fontColor(this.selectedCategory === item ? '#FFFFFF' : '#333333')
                  .fontWeight(this.selectedCategory === item ? FontWeight.Bold : FontWeight.Normal)
                  .position({ y: 14, x: 5 })
              }
              .layoutWeight(1)
              // 绑定点击事件，并加上流畅的过渡动画
              .onClick(() => {
                animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
                  this.filterData(item);
                })
              })
            })
          }.width('100%').padding({ top: 20, bottom: 20, left: 10, right: 10 })

          // ========== 4. 猜你喜欢标题 (动态修改文案) ==========
          Row() {
            // 当选中某个分类时，标题也会跟着变成 "✨ 推荐火锅" 等等
            Text(this.selectedCategory === '' ? '✨ 猜你喜欢' : `✨ 推荐${this.selectedCategory.replace(/[^一-龥]/g, '')}`)
              .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
          }.width('100%').padding({ left: 15, bottom: 10 })

          // ========== 5. 纯手工双列瀑布流 ==========
          Row() {
            Column() {
              ForEach(this.leftColList, (item: FoodItem) => {
                this.FoodCard(item)
              }, (item: FoodItem) => item.id)
            }.width('48%').alignItems(HorizontalAlign.Start)

            Column() {
              ForEach(this.rightColList, (item: FoodItem) => {
                this.FoodCard(item)
              }, (item: FoodItem) => item.id)
            }.width('48%').alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 10, right: 10, bottom: 20 })

        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .onScroll(() => {
        let yOffset = this.scroller.currentOffset().yOffset;
        if (yOffset > 200) {
          this.isShowTopBtn = true;
        } else {
          this.isShowTopBtn = false;
        }
      })

      // ========== 悬浮的回到顶部按钮 ==========
      if (this.isShowTopBtn) {
        Button() {
          Text('↑').fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
        }
        .type(ButtonType.Circle)
        .width(45)
        .height(45)
        .backgroundColor('#FF5E00')
        .shadow({ radius: 6, color: '#33000000', offsetY: 3 })
        .margin({ right: 20, bottom: 30 })
        .onClick(() => {
          this.scroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 300, curve: Curve.EaseOut } });
        })
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }




  // ==================== 👇 新增：页面过渡动画 ====================
  // ==================== 修改：纯净的渐变过渡动画 ====================
  pageTransition() {
    // 进场时：透明度从 0 开始，同时强制 X 和 Y 轴的位移都为 0（彻底干掉滑动）
    PageTransitionEnter({ duration: 300, curve: Curve.EaseInOut })
      .opacity(0)
      .translate({ x: 0, y: 0 })

    // 退场时：透明度变为 0，同样强制位移为 0
    PageTransitionExit({ duration: 300, curve: Curve.EaseInOut })
      .opacity(0)
      .translate({ x: 0, y: 0 })
  }
}