import router from '@ohos.router';
import relationalStore from '@ohos.data.relationalStore';
import { RdbManager } from '../utils/RdbManager';

@Entry
@Component
struct StoreDetailView {
  // 从路由参数中获取的餐厅 ID
  @State restaurantId: string = '';
  // 存储当前餐厅的详细信息，可能为 null（如果未找到）
  @State restaurant: RestaurantDetail | null = null;
  // 存储该餐厅关联的所有探店帖子列表
  @State postList: PostInfo[] = [];
  // 加载状态标志，用于显示加载动画
  @State loading: boolean = true;

  // 页面即将显示时调用，获取路由参数并初始化数据
  aboutToAppear() {
    // 获取路由传递的参数（通过 router.pushUrl 传入的 params）
    const params = router.getParams() as Record<string, Object>;
    if (params && params['restaurantId']) {
      this.restaurantId = params['restaurantId'] as string; // 提取餐厅 ID
      this.initData(); // 开始加载数据
    } else {
      console.error('StoreDetailView 缺少 restaurantId 参数');
      this.loading = false; // 无参数时直接结束加载，显示错误
    }
  }

  // 初始化数据：同时加载店铺详情和评价列表
  async initData() {
    this.loading = true;
    // 并行执行两个加载任务，提高效率（但为了顺序明确，这里使用 await 顺序执行）
    await this.loadRestaurantDetail();
    await this.loadRestaurantPosts();
    this.loading = false; // 所有数据加载完毕
  }

  // 从 restaurants 表读取该店铺的详细信息
  async loadRestaurantDetail() {
    try {
      const store = RdbManager.getStore(); // 获取数据库实例
      let predicates = new relationalStore.RdbPredicates('restaurants');
      predicates.equalTo('restaurant_id', this.restaurantId); // 根据餐厅 ID 精确查询

      // 查询指定字段
      let resultSet = await store.query(
        predicates,
        ['restaurant_id', 'name', 'category', 'address', 'latitude', 'longitude', 'rating', 'cover_url']
      );

      // 如果查询结果不为空
      if (resultSet.goToNextRow()) {
        // 按列索引提取数据
        const id = resultSet.getString(resultSet.getColumnIndex('restaurant_id'));
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        const category = resultSet.getString(resultSet.getColumnIndex('category'));
        const address = resultSet.getString(resultSet.getColumnIndex('address'));
        const latitude = resultSet.getDouble(resultSet.getColumnIndex('latitude'));
        const longitude = resultSet.getDouble(resultSet.getColumnIndex('longitude'));
        const rating = resultSet.getDouble(resultSet.getColumnIndex('rating'));
        const coverUrl = resultSet.getString(resultSet.getColumnIndex('cover_url'));

        // 构造餐厅详情对象
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
        this.restaurant = null; // 未找到时置为 null
      }
      resultSet.close(); // 关闭结果集
    } catch (err) {
      console.error('查询店铺详情失败', JSON.stringify(err));
      this.restaurant = null;
    }
  }

  // 从 posts 表中查询该店铺下所有评价/探店帖子
  async loadRestaurantPosts() {
    try {
      const store = RdbManager.getStore();
      let predicates = new relationalStore.RdbPredicates('posts');
      predicates.equalTo('restaurant_id', this.restaurantId); // 筛选该店铺的帖子
      // 按发布时间倒序排列，最新评价在前
      predicates.orderByDesc('publish_time');

      // 查询帖子相关字段
      let resultSet = await store.query(
        predicates,
        ['post_id', 'user_id', 'content', 'image_urls', 'likes_count', 'publish_time']
      );

      const tmpList: PostInfo[] = [];
      // 遍历结果集
      while (resultSet.goToNextRow()) {
        const postId = resultSet.getString(resultSet.getColumnIndex('post_id'));
        const userId = resultSet.getString(resultSet.getColumnIndex('user_id'));
        const content = resultSet.getString(resultSet.getColumnIndex('content'));
        const imageUrlsStr = resultSet.getString(resultSet.getColumnIndex('image_urls'));
        const likesCount = resultSet.getLong(resultSet.getColumnIndex('likes_count'));
        const publishTime = resultSet.getLong(resultSet.getColumnIndex('publish_time'));

        // 解析图片 URL 字符串（JSON 数组格式）
        let images: string[] = [];
        try {
          images = imageUrlsStr ? JSON.parse(imageUrlsStr) : [];
        } catch (e) {
          console.error('解析 image_urls 失败', e);
        }

        // 构造帖子信息对象
        tmpList.push({
          postId,
          userId,
          content,
          images,
          likesCount: Number(likesCount),
          publishTime: Number(publishTime)
        });
      }

      resultSet.close(); // 关闭结果集
      this.postList = tmpList; // 更新帖子列表
    } catch (err) {
      console.error('查询店铺关联帖子失败', JSON.stringify(err));
      this.postList = []; // 查询失败时置为空数组
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        // 返回箭头图标，点击调用 router.back() 返回上一页
        Image($r('app.media.back'))
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

      // 根据加载状态显示不同内容
      if (this.loading) {
        // 加载中：显示旋转进度条
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
        // 店铺信息不存在（例如 ID 错误或数据库无此店）
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
        // 内容区：店铺信息 + 评价列表（可滚动）
        Scroll() {
          Column() {
            // 店铺头图（使用本地资源）
            Image($r('app.media.' + this.restaurant.coverUrl))
              .width('100%')
              .height(200)
              .objectFit(ImageFit.Cover)

            // 店铺基本信息卡片
            Column({ space: 8 }) {
              Text(this.restaurant.name).fontSize(20).fontWeight(FontWeight.Bold).width('100%')
              Text(`${this.restaurant.category} · 评分 ${this.restaurant.rating.toFixed(1)}`)
                .fontSize(14).fontColor('#ff8c00').width('100%')

              // 地址（静态字段）
              Text(`📍 地址：${this.restaurant.address}`)
                .fontSize(13).fontColor('#333').width('100%').margin({ top: 4 })

              // 营业时间（目前为静态示例，后续可从数据库扩展）
              Text(`⏰ 营业时间：周一至周日 10:00 - 22:00`)
                .fontSize(13).fontColor('#333').width('100%')

              // 招牌菜品（静态示例）
              Text(`🍲 招牌菜品：招牌推荐菜、主厨精选系列`)
                .fontSize(13).fontColor('#333').width('100%')
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ top: 12, left: 12, right: 12 })

            // 评价/探店帖子列表区域
            Column() {
              Row() {
                Text('用户评价')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Text(`（${this.postList.length} 条）`)
                  .fontSize(12)
                  .fontColor('#999')
                  .margin({ left: 4 })
              }
              .margin({ left: 12, right: 12, top: 16, bottom: 8 })

              if (this.postList.length === 0) {
                // 无评价时显示提示语
                Text('还没有人来点评这家店，快去社区发布第一篇探店日记吧～')
                  .fontSize(13)
                  .fontColor('#999')
                  .margin({ left: 16, right: 16, bottom: 20 })
              } else {
                // 遍历显示每一条帖子
                ForEach(this.postList, (item: PostInfo) => {
                  this.postItem(item)
                })
              }
            }
          }
        }
        .layoutWeight(1) // 可滚动区域占据剩余高度
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  // 单个帖子展示卡片
  @Builder postItem(item: PostInfo) {
    Column() {
      // 文本内容（如果为空则显示默认文案）
      Text(item.content || '这位同学很懒，没有写评语~')
        .fontSize(14)
        .fontColor('#333')
        .margin({ bottom: 8 })
        .width('100%')

      // 图片预览（简化版：只显示前三张图片横向排列，可扩展为九宫格）
      if (item.images && item.images.length > 0) {
        Row() {
          ForEach(item.images, (img: string, index: number) => {
            if (index < 3) { // 限制最多显示3张
              Image(img) // 图片 URL 为字符串
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

        Blank() // 撑开空间，使时间戳靠右

        // 简单显示时间戳（可以自行格式化为日期，此处仅展示原始数值）
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

// 定义餐厅详情接口
interface RestaurantDetail {
  id: string;
  name: string;
  category: string;
  address: string;
  latitude: number;
  longitude: number;
  rating: number;
  coverUrl: string; // 本地资源名称（如 '1'）
}

// 定义帖子信息接口
interface PostInfo {
  postId: string;
  userId: string;
  content: string;
  images: string[]; // 图片 URL 列表（可能为网络路径或本地路径）
  likesCount: number;
  publishTime: number; // 发布时间戳
}