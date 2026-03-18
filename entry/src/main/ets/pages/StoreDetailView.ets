import router from '@ohos.router';
import relationalStore from '@ohos.data.relationalStore';
import { RdbManager } from '../utils/RdbManager';

@Entry
@Component
export struct StoreDetailView {
  @State restaurantId: string = '';
  @State restaurant: RestaurantDetail | null = null;
  @State postList: PostInfo[] = [];
  @State loading: boolean = true;

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['restaurantId']) {
      this.restaurantId = params['restaurantId'] as string;
      this.initData();
    } else {
      console.error('StoreDetailView 缺少 restaurantId 参数');
      this.loading = false;
    }
  }

  async initData() {
    this.loading = true;
    await this.loadRestaurantDetail();
    await this.loadRestaurantPosts();
    this.loading = false;
  }

  /**
   * 从 restaurants 表读取该店铺的详细信息
   */
  async loadRestaurantDetail() {
    try {
      const store = RdbManager.getStore();
      let predicates = new relationalStore.RdbPredicates('restaurants');
      predicates.equalTo('restaurant_id', this.restaurantId);

      let resultSet = await store.query(
        predicates,
        ['restaurant_id', 'name', 'category', 'address', 'latitude', 'longitude', 'rating', 'cover_url']
      );

      if (resultSet.goToNextRow()) {
        const id = resultSet.getString(resultSet.getColumnIndex('restaurant_id'));
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        const category = resultSet.getString(resultSet.getColumnIndex('category'));
        const address = resultSet.getString(resultSet.getColumnIndex('address'));
        const latitude = resultSet.getDouble(resultSet.getColumnIndex('latitude'));
        const longitude = resultSet.getDouble(resultSet.getColumnIndex('longitude'));
        const rating = resultSet.getDouble(resultSet.getColumnIndex('rating'));
        const coverUrl = resultSet.getString(resultSet.getColumnIndex('cover_url'));

        this.restaurant = {
          id,
          name,
          category,
          address,
          latitude,
          longitude,
          rating,
          coverUrl
        };
      } else {
        console.warn('未在 restaurants 表中找到对应店铺，restaurantId=', this.restaurantId);
        this.restaurant = null;
      }

      resultSet.close();
    } catch (err) {
      console.error('查询店铺详情失败', JSON.stringify(err));
      this.restaurant = null;
    }
  }

  /**
   * 从 posts 表中查询该店铺下所有评价/探店帖子
   */
  async loadRestaurantPosts() {
    try {
      const store = RdbManager.getStore();
      let predicates = new relationalStore.RdbPredicates('posts');
      predicates.equalTo('restaurant_id', this.restaurantId);
      // 可以按发布时间倒序，最新评价在前
      predicates.orderByDesc('publish_time');

      let resultSet = await store.query(
        predicates,
        ['post_id', 'user_id', 'content', 'image_urls', 'likes_count', 'publish_time']
      );

      const tmpList: PostInfo[] = [];
      while (resultSet.goToNextRow()) {
        const postId = resultSet.getString(resultSet.getColumnIndex('post_id'));
        const userId = resultSet.getString(resultSet.getColumnIndex('user_id'));
        const content = resultSet.getString(resultSet.getColumnIndex('content'));
        const imageUrlsStr = resultSet.getString(resultSet.getColumnIndex('image_urls'));
        const likesCount = resultSet.getLong(resultSet.getColumnIndex('likes_count'));
        const publishTime = resultSet.getLong(resultSet.getColumnIndex('publish_time'));

        let images: string[] = [];
        try {
          images = imageUrlsStr ? JSON.parse(imageUrlsStr) : [];
        } catch (e) {
          console.error('解析 image_urls 失败', e);
        }

        tmpList.push({
          postId,
          userId,
          content,
          images,
          likesCount: Number(likesCount),
          publishTime: Number(publishTime)
        });
      }

      resultSet.close();
      this.postList = tmpList;
    } catch (err) {
      console.error('查询店铺关联帖子失败', JSON.stringify(err));
      this.postList = [];
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Image($r('app.media.1'))
          .width(24)
          .height(24)
          .margin({ right: 8 })
          .onClick(() => {
            router.back();
          })
        Text('店铺详情')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ top: 16, left: 16, right: 16, bottom: 8 })

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
          Text('加载中...')
            .margin({ top: 8 })
            .fontColor('#666')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (!this.restaurant) {
        Column() {
          Text('未找到该店铺信息')
            .fontColor('#999')
          Button('返回上一页')
            .margin({ top: 12 })
            .onClick(() => router.back())
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 内容区：店铺信息 + 评价列表
        Scroll() {
          Column() {
            // 店铺头图
            Image(this.restaurant.coverUrl)
              .width('100%')
              .height(200)
              .objectFit(ImageFit.Cover)

            // 店铺基本信息卡片
            Column({ space: 6 }) {
              Text(this.restaurant.name)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)

              Text(`${this.restaurant.category} · 评分 ${this.restaurant.rating.toFixed(1)}`)
                .fontSize(14)
                .fontColor('#ff8c00')

              Text(this.restaurant.address)
                .fontSize(13)
                .fontColor('#666')

              // 这里可以预留出一块位置，用于后续接入 Map Kit 的单店铺详情地图（比如展示店铺位置 pin）
              Text('地图位置（可接入 Map Kit 显示该店铺标记）')
                .fontSize(12)
                .fontColor('#999')
                .margin({ top: 8 })
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ top: 12, left: 12, right: 12 })

            // 评价/探店帖子列表
            Column() {
              Row() {
                Text('探店日记 / 用户评价')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Text(`（${this.postList.length} 条）`)
                  .fontSize(12)
                  .fontColor('#999')
                  .margin({ left: 4 })
              }
              .margin({ left: 12, right: 12, top: 16, bottom: 8 })

              if (this.postList.length === 0) {
                Text('还没有人来点评这家店，快去社区发布第一篇探店日记吧～')
                  .fontSize(13)
                  .fontColor('#999')
                  .margin({ left: 16, right: 16, bottom: 20 })
              } else {
                ForEach(this.postList, (item: PostInfo) => {
                  this.postItem(item)
                })
              }
            }
          }
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  @Builder postItem(item: PostInfo) {
    Column() {
      // 文本内容
      Text(item.content || '这位同学很懒，没有写评语~')
        .fontSize(14)
        .fontColor('#333')
        .margin({ bottom: 6 })

      // 图片九宫格（简单版本，只做横向 Row，实际可以按 3 列网格来写）
      if (item.images && item.images.length > 0) {
        Row() {
          ForEach(item.images, (img: string, index: number) => {
            if (index < 3) {
              Image(img)
                .width(80)
                .height(80)
                .borderRadius(6)
                .objectFit(ImageFit.Cover)
                .margin({ right: 6 })
            }
          })
        }
        .margin({ bottom: 6 })
      }

      Row() {
        Text(`点赞 ${item.likesCount}`)
          .fontSize(12)
          .fontColor('#ff8c00')

        Blank()

        // 简单显示时间戳（可以自行格式化为日期）
        Text(`${item.publishTime}`)
          .fontSize(11)
          .fontColor('#999')
      }
    }
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(10)
    .margin({ left: 12, right: 12, bottom: 10 })
  }
}

interface RestaurantDetail {
  id: string;
  name: string;
  category: string;
  address: string;
  latitude: number;
  longitude: number;
  rating: number;
  coverUrl: string;
}

interface PostInfo {
  postId: string;
  userId: string;
  content: string;
  images: string[];
  likesCount: number;
  publishTime: number;
}