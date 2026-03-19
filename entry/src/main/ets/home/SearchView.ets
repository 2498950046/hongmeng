import router from '@ohos.router';

// 沿用之前的数据结构
interface FoodItem {
  id: string;
  title: string;
  author: string;
  likes: number;
  imgUrl: string;
  category: string;
}

@Entry
@Component
export struct SearchView {
  // 状态控制变量
  @State searchTxt: string = '';
  @State isSearching: boolean = false; // 是否处于展示搜索结果的状态

  // 历史与热门数据
  @State historyList: string[] = ['麻辣烫', '寿喜锅', '咖啡'];
  @State hotList: string[] = ['烤肉', '爆浆抹茶', '深夜大排档', '精酿', '早茶'];

  // 模拟的全局数据库
  private allFoodData: FoodItem[] = [
    { id: '1', title: '藏在巷子里的神仙烤肉！', author: '小吃货', likes: 256, category: '烧烤', imgUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60' },
    { id: '2', title: '周末打卡超火的网红咖啡店☕', author: '探店达人', likes: 128, category: '咖啡', imgUrl: 'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60' },
    { id: '3', title: '这家寿喜锅我能吃一辈子', author: '干饭王', likes: 89, category: '日料', imgUrl: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60' },
    { id: '4', title: '爆浆抹茶舒芙蕾，甜品控必看', author: '甜甜圈', likes: 512, category: '甜品', imgUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60' },
    { id: '5', title: '深夜放毒：路边摊的麻辣烫', author: '夜猫子', likes: 66, category: '火锅', imgUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60' }
  ];

  // 存放当前搜索过滤出的结果
  @State searchResults: FoodItem[] = [];

  // ================= 核心业务逻辑 =================

  // 执行搜索
  doSearch(keyword: string) {
    if (!keyword.trim()) {
      return;
    }
    this.searchTxt = keyword;

    //  将搜索词加入历史记录（去重并放到第一位）
    let filteredHistory = this.historyList.filter(item => item !== keyword);
    this.historyList = [keyword, ...filteredHistory];

    // 过滤数据：只要标题或分类包含关键词，就算匹配中
    this.searchResults = this.allFoodData.filter(item =>
    item.title.includes(keyword) || item.category.includes(keyword)
    );

    // 切换到结果页状态
    this.isSearching = true;
  }



  // 清空历史记录
  clearHistory() {
    this.historyList = [];
  }

  // 退出搜索状态
  cancelSearch() {
    this.searchTxt = '';
    this.isSearching = false;
    this.searchResults = [];
  }

  // ================= UI 构建 =================

  // 抽取 Tag 标签组件（用于历史记录和热门词）
  @Builder
  TagItem(text: string, isHot: boolean = false) {
    Text(text)
      .fontSize(13)
      .fontColor(isHot ? '#FF5E00' : '#666666') // 热门词用主题橙色，普通词用灰色
      .backgroundColor(isHot ? '#FFF3E0' : '#F5F5F5')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(16)
      .margin({ right: 10, bottom: 10 })
      .onClick(() => {
        // 点击标签直接触发搜索
        this.doSearch(text);
      })
  }

  // 抽取搜索结果单行卡片组件（搜索结果通常用横向列表，区别于首页的瀑布流）
  @Builder
  ResultCard(item: FoodItem) {
    Row() {
      // 左侧图片
      Image(item.imgUrl)
        .width(100).height(100)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)

      // 右侧信息
      Column() {
        Text(item.title)
          .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#333333')
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(item.category)
          .fontSize(12).fontColor('#FF5E00')
          .backgroundColor('#FFF3E0')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
          .margin({ top: 6, bottom: 6 })

        Row() {
          Text(`@${item.author}`).fontSize(12).fontColor('#999999')
          Text(`❤️ ${item.likes}`).fontSize(12).fontColor('#999999')
        }.width('100%').justifyContent(FlexAlign.SpaceBetween)

      }
      .layoutWeight(1)
      .height(100)
      .padding({ left: 10 })
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceBetween) // 上下分散对齐
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 10 })
    .shadow({ radius: 4, color: '#0A000000', offsetY: 2 })
  }







  build() {
    Column() {
      // ========== 1. 顶部搜索头 ==========
      Row() {
        // 返回按钮
        Text('❮ 返回')
          .fontSize(16).fontColor('#333333')
          .margin({ right: 10 })
          .onClick(() => {
            router.back(); // 路由返回上一页
          })

        // 搜索框
        Search({ value: this.searchTxt, placeholder: '搜一搜附近的神仙美食...' })
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F5F5F5')
          .onSubmit((value: string) => {
            this.doSearch(value); // 按回车/搜索键时触发
          })
          .onChange((value: string) => {
            this.searchTxt = value;
            // 如果用户清空了输入框，自动退回搜索主页
            if (value === '') {
              this.cancelSearch();
            }
          })

        // 搜索按钮
        Text('搜索')
          .fontSize(16).fontColor('#FF5E00').fontWeight(FontWeight.Medium)
          .margin({ left: 10 })
          .onClick(() => {
            this.doSearch(this.searchTxt);
          })
      }
      .width('100%').padding({ left: 15, right: 15, top: 10, bottom: 10 })
      .backgroundColor('#FFFFFF')

      // ========== 2. 内容区 ==========
      if (this.isSearching) {
        // --- 状态A：展示搜索结果 ---
        if (this.searchResults.length > 0) {
          List() {
            ForEach(this.searchResults, (item: FoodItem) => {
              ListItem() {
                this.ResultCard(item)
              }
            }, (item: FoodItem) => item.id)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 15, right: 15, top: 10 })
        } else {
          // 空状态展示
          Column() {
            Text('🔍').fontSize(50).margin({ bottom: 15 })
            Text('抱歉，没有找到相关美食').fontSize(14).fontColor('#999999')
          }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        }

      } else {
        // --- 状态B：展示历史记录与热门搜索 ---
        Scroll() {
          Column() {
            // 历史搜索模块
            if (this.historyList.length > 0) {
              Row() {
                Text('历史搜索').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
                Text('🗑️ 清空').fontSize(13).fontColor('#999999')
                  .onClick(() => {
                    this.clearHistory();
                  })
              }
              .width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ bottom: 15 })

              // Flex 组件用于流式布局（标签自动换行）
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.historyList, (item: string) => {
                  this.TagItem(item, false)
                }, (item: string) => item)
              }.width('100%').margin({ bottom: 30 })
            }

            // 热门搜索模块
            Row() {
              Text('🔥 热门搜索').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
            }.width('100%').margin({ bottom: 15 })

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.hotList, (item: string) => {
                this.TagItem(item, true) // isHot 传 true，使用特殊样式
              }, (item: string) => item)
            }.width('100%')

          }
          .width('100%')
          .padding(15)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }









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