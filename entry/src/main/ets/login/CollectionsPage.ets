import { RdbManager } from '../utils/RdbManager';
import relationalStore from '@ohos.data.relationalStore';
import router from '@ohos.router';

// 定义收藏项接口
interface CollectionItem {
  id: string;
  name: string;
  type: number; // 1:餐厅, 2:帖子
  image?: string;
  rating?: number;
  address?: string;
}

// 定义用户接口
interface User {
  user_id: string;
  nickname: string;
  avatar_url: string;
  create_time: number;
}

// 定义餐厅接口
interface Restaurant {
  name: string;
  address: string;
}

// 定义收藏接口
interface Collection {
  collection_id: string;
  user_id: string;
  target_id: string;
  type: number;
}

@Entry
@Component
struct CollectionsPage {
  @StorageLink('currentUser') currentUser: User | null = null;
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false;

  @State activeTab: number = 0; // 0:餐厅收藏, 1:帖子收藏
  @State restaurantCollections: CollectionItem[] = [];
  @State postCollections: CollectionItem[] = [];
  @State isLoading: boolean = true;

  aboutToAppear() {
    if (this.isLoggedIn && this.currentUser) {
      this.loadCollections();
    }
  }

  async loadCollections() {
    this.isLoading = true;
    
    try {
      // 加载餐厅收藏
      const restaurantCols = await RdbManager.getUserCollections(this.currentUser!.user_id, 1);
      this.restaurantCollections = await this.loadRestaurantDetails(restaurantCols);

      // 加载帖子收藏
      const postCols = await RdbManager.getUserCollections(this.currentUser!.user_id, 2);
      this.postCollections = await this.loadPostDetails(postCols);

    } catch (err) {
      console.error('加载收藏失败:', JSON.stringify(err));
    }

    this.isLoading = false;
  }

  async loadRestaurantDetails(collections: Collection[]): Promise<CollectionItem[]> {
    const store = RdbManager.getStore();
    const result: CollectionItem[] = [];

    for (const collection of collections) {
      const predicates = new relationalStore.RdbPredicates('restaurants');
      predicates.equalTo('restaurant_id', collection.target_id);

      try {
        const resultSet = await store.query(predicates);
        if (resultSet.goToFirstRow()) {
          result.push({
            id: collection.target_id,
            name: resultSet.getString(resultSet.getColumnIndex('name')),
            type: 1,
            rating: resultSet.getDouble(resultSet.getColumnIndex('rating')),
            address: resultSet.getString(resultSet.getColumnIndex('address'))
          } as CollectionItem);
        }
        resultSet.close();
      } catch (err) {
        console.error('查询餐厅详情失败:', JSON.stringify(err));
      }
    }

    return result;
  }

  async loadPostDetails(collections: Collection[]): Promise<CollectionItem[]> {
    const store = RdbManager.getStore();
    const result: CollectionItem[] = [];

    for (const collection of collections) {
      const predicates = new relationalStore.RdbPredicates('posts');
      predicates.equalTo('post_id', collection.target_id);

      try {
        const resultSet = await store.query(predicates);
        if (resultSet.goToFirstRow()) {
          // 获取关联的餐厅信息
          const restaurantId = resultSet.getString(resultSet.getColumnIndex('restaurant_id'));
          const restaurant: Restaurant | null = await this.getRestaurantById(restaurantId);
          
          result.push({
            id: collection.target_id,
            name: restaurant?.name || '未知餐厅',
            type: 2,
            address: restaurant?.address
          } as CollectionItem);
        }
        resultSet.close();
      } catch (err) {
        console.error('查询帖子详情失败:', JSON.stringify(err));
      }
    }

    return result;
  }

  async getRestaurantById(restaurantId: string): Promise<Restaurant | null> {
    const store = RdbManager.getStore();
    const predicates = new relationalStore.RdbPredicates('restaurants');
    predicates.equalTo('restaurant_id', restaurantId);

    try {
      const resultSet = await store.query(predicates);
      if (resultSet.goToFirstRow()) {
        const restaurant: Restaurant = {
          name: resultSet.getString(resultSet.getColumnIndex('name')),
          address: resultSet.getString(resultSet.getColumnIndex('address'))
        };
        resultSet.close();
        return restaurant;
      }
      resultSet.close();
    } catch (err) {
      console.error('查询餐厅失败:', JSON.stringify(err));
    }
    return null;
  }

  async removeCollection(item: CollectionItem) {
    try {
      await RdbManager.removeCollection(this.currentUser!.user_id, item.id, item.type);
      
      // 重新加载数据
      if (item.type === 1) {
        this.restaurantCollections = this.restaurantCollections.filter(col => col.id !== item.id);
      } else {
        this.postCollections = this.postCollections.filter(col => col.id !== item.id);
      }
      
    } catch (err) {
      console.error('取消收藏失败:', JSON.stringify(err));
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('我的收藏')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        // 返回按钮
        Image($r('app.media.home1'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')
      .padding({ left: 15, right: 15, top: 10, bottom: 15 })

      // Tab切换
      Row() {
        Button('餐厅收藏')
          .layoutWeight(1)
          .height(40)
          .fontSize(16)
          .fontColor(this.activeTab === 0 ? '#FFFFFF' : '#FF5E00')
          .backgroundColor(this.activeTab === 0 ? '#FF5E00' : '#FFFFFF')
          .border({
            width: 1,
            color: '#FF5E00'
          })
          .borderRadius(0)
          .onClick(() => {
            this.activeTab = 0;
          })

        Button('帖子收藏')
          .layoutWeight(1)
          .height(40)
          .fontSize(16)
          .fontColor(this.activeTab === 1 ? '#FFFFFF' : '#FF5E00')
          .backgroundColor(this.activeTab === 1 ? '#FF5E00' : '#FFFFFF')
          .border({
            width: 1,
            color: '#FF5E00'
          })
          .borderRadius(0)
          .onClick(() => {
            this.activeTab = 1;
          })
      }
      .width('100%')
      .margin({ bottom: 15 })

      // 内容区域
      if (!this.isLoggedIn) {
        this.buildGuestView()
      } else if (this.isLoading) {
        this.buildLoadingView()
      } else {
        this.buildCollectionsView()
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }

  @Builder
  buildGuestView() {
    Column() {
      Text('请先登录')
        .fontSize(18)
        .fontColor('#666666')
        .margin({ top: 100, bottom: 20 })

      Button('立即登录')
        .width(200)
        .height(45)
        .backgroundColor('#FF5E00')
        .fontColor('#FFFFFF')
        .onClick(() => {
          router.pushUrl({
            url: 'pages/LoginPage'
          });
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildLoadingView() {
    Column() {
      Progress({ value: 0, total: 100, type: ProgressType.Ring })
        .width(40)
        .height(40)
        .margin({ top: 100 })

      Text('加载中...')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 15 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildCollectionsView() {
    Scroll() {
      Column() {
        // ✅ 修复：直接使用条件渲染 (if/else)，不在这里声明 const 变量
        if (this.activeTab === 0) {
          // 渲染餐厅收藏
          if (this.restaurantCollections.length === 0) {
            this.buildEmptyView()
          } else {
            ForEach(this.restaurantCollections, (item: CollectionItem) => {
              this.buildCollectionItem(item)
            }, (item: CollectionItem) => item.id)
          }
        } else {
          // 渲染帖子收藏
          if (this.postCollections.length === 0) {
            this.buildEmptyView()
          } else {
            ForEach(this.postCollections, (item: CollectionItem) => {
              this.buildCollectionItem(item)
            }, (item: CollectionItem) => item.id)
          }
        }
      }
      .width('100%')
      .padding(15)
    }
    .layoutWeight(1)
  }

  @Builder
  buildEmptyView() {
    Column() {
      Image($r('app.media.home1'))
        .width(80)
        .height(80)
        .margin({ top: 100, bottom: 20 })

      Text(this.activeTab === 0 ? '暂无收藏的餐厅' : '暂无收藏的帖子')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ bottom: 10 })

      Text('快去发现更多美食吧！')
        .fontSize(14)
        .fontColor('#999999')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildCollectionItem(item: CollectionItem) {
    Row() {
      // 左侧图标
      Image($r('app.media.home1'))
        .width(50)
        .height(50)
        .borderRadius(8)
        .margin({ right: 15 })

      // 中间信息
      Column() {
        Text(item.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .align(Alignment.Start)

        if (item.address) {
          Text(item.address)
            .fontSize(12)
            .fontColor('#666666')
            .align(Alignment.Start)
            .margin({ top: 4 })
        }

        if (item.rating) {
          Row() {
            Text('评分：')
              .fontSize(12)
              .fontColor('#666666')
            
            Text(item.rating.toFixed(1))
              .fontSize(12)
              .fontColor('#FF5E00')
              .fontWeight(FontWeight.Medium)
          }
          .align(Alignment.Start)
          .margin({ top: 4 })
        }
      }
      .layoutWeight(1)

      // 右侧操作
      Button('取消收藏')
        .width(80)
        .height(30)
        .fontSize(12)
        .border({
          width: 1,
          color: '#FF5E00'
        })
        .backgroundColor('#FFFFFF')
        .fontColor('#FF5E00')
        .onClick(() => {
          this.removeCollection(item);
        })

    }
    .width('100%')
    .height(80)
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 10 })
  }
}