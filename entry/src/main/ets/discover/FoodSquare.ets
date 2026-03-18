import { FoodDatabase } from './FoodDatabase';
import { Post } from './Post';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';

// 定义接口
interface PostItemParams {
  post: Post;
}

@Entry
@Component
export struct  FoodSquare {
  @State posts: Post[] = []; // 帖子列表
  @State showPublishDialog: boolean = false; // 发布弹窗
  private foodDb: FoodDatabase = FoodDatabase.getInstance();

  aboutToAppear() {
    console.info('[FoodSquare] aboutToAppear called');
    this.initDatabaseAndLoadPosts();
  }

  // 页面显示时刷新数据
  onPageShow() {
    console.info('[FoodSquare] onPageShow called, refreshing posts');
    this.loadPosts();
  }

  // 获取上下文
  getContext(): common.Context {
    return getContext(this) as common.Context;
  }

  // 初始化数据库并加载帖子
  async initDatabaseAndLoadPosts() {
    try {
      // 获取应用上下文
      const ctx = this.getContext() as common.UIAbilityContext;
      console.info('[FoodSquare] Initializing database...');

      // 初始化数据库
      await this.foodDb.initialize(ctx);

      // 加载帖子数据
      await this.loadPosts();
    } catch (err) {
      console.error(`[FoodSquare] Failed to initialize: ${JSON.stringify(err)}`);
    }
  }

  // 加载帖子
  async loadPosts() {
    console.info('[FoodSquare] Starting to load posts...');
    try {
      const loadedPosts = await this.foodDb.queryAllPosts();
      console.info(`[FoodSquare] Loaded ${loadedPosts.length} posts`);

      // 使用新的数组确保UI更新
      this.posts = [...loadedPosts];

      // 如果没有帖子，添加一个示例帖子
      if (this.posts.length === 0) {
        console.info('[FoodSquare] No posts found, you can add a new post');
      }
    } catch (err) {
      console.error(`[FoodSquare] Failed to load posts: ${JSON.stringify(err)}`);
    }
  }

  // 处理点赞
  async handleLike(post: Post) {
    console.info(`[FoodSquare] Handling like for post ${post.id}, current liked: ${post.isLiked}`);
    const newLikes = post.isLiked ? post.likes - 1 : post.likes + 1;
    const success = await this.foodDb.updateLike(post.id, !post.isLiked, newLikes);

    if (success) {
      // 更新本地状态
      const index = this.posts.findIndex(p => p.id === post.id);
      if (index !== -1) {
        this.posts[index].isLiked = !post.isLiked;
        this.posts[index].likes = newLikes;
        this.posts = [...this.posts]; // 触发UI更新
        console.info(`[FoodSquare] Like updated for post ${post.id}, new likes: ${newLikes}`);
      }
    } else {
      console.error(`[FoodSquare] Failed to update like for post ${post.id}`);
    }
  }

  // 跳转到发布页
  navigateToPublish() {
    console.info('[FoodSquare] Navigating to publish page');
    try {
      router.pushUrl({
        url: 'pages/PublishPost',
        params: {
          refreshCallback: () => {
            console.info('[FoodSquare] Callback received, refreshing posts');
            this.loadPosts();
          }
        }
      });
    } catch (error) {
      console.error(`[FoodSquare] Failed to navigate: ${JSON.stringify(error)}`);
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('社区广场')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })

        Blank()

        // 发布按钮
        Button('去发布', { type: ButtonType.Capsule, stateEffect: true })
          .backgroundColor('#FF6B81')
          .fontColor(Color.White)
          .margin({ right: 16 })
          .onClick(() => {
            this.navigateToPublish();
          })
      }
      .width('100%')
      .height(60)
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)
      .shadow({ radius: 4, color: '#20000000' })

      // 帖子列表
      if (this.posts.length === 0) {
        // 没有帖子时的提示
        Column() {
          Image('common/no_data.png')
            .width(120)
            .height(120)
            .margin({ bottom: 20 })

          Text('暂无帖子，快去发布第一个吧！')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.posts, (post: Post) => {
            ListItem() {
              this.PostItem({ post: post })
            }
          }, (post: Post) => post.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: '#F0F0F0' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }

  @Builder
  PostItem(postObj: PostItemParams) {
    Column({ space: 0 }) {
      // 用户信息区域
      Row({ space: 12 }) {
        // 用户头像
        Image(postObj.post.userAvatar)
          .width(40)
          .height(40)
          .borderRadius(20)
          .objectFit(ImageFit.Cover)

        Column({ space: 4 }) {
          // 用户名
          Text(postObj.post.userName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          // 发布时间
          Text(this.formatTime(postObj.post.createTime))
            .fontSize(12)
            .fontColor('#999999')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(16)

      // 内容区域
      if (postObj.post.content) {
        Text(postObj.post.content)
          .fontSize(15)
          .fontColor('#333333')
          .maxLines(5)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .padding({ left: 16, right: 16, bottom: postObj.post.images.length > 0 ? 8 : 16 })
      }

      // 图片区域
      if (postObj.post.images.length > 0) {
        if (postObj.post.images.length === 1) {
          // 单图模式
          Image(postObj.post.images[0])
            .width('100%')
            .height(200)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
            .margin({ left: 16, right: 16, bottom: 16 })
        } else {
          // 多图网格布局
          GridRow({ columns: 3, gutter: 4 }) {
            ForEach(postObj.post.images.slice(0, 9), (image: string, index: number) => {
              GridCol({ span: 1 }) {
                Image(image)
                  .width('100%')
                  .aspectRatio(1)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(4)
              }
            })
          }
          .height(120 * Math.ceil(Math.min(postObj.post.images.length, 9) / 3))
          .padding({ left: 16, right: 16, bottom: 16 })
        }
      }

      // 互动区域
      Row({ space: 0 }) {
        // 点赞按钮
        Row({ space: 6 }) {
          Image(postObj.post.isLiked ? 'common/like_filled.png' : 'common/like_outline.png')
            .width(20)
            .height(20)
            .fillColor(postObj.post.isLiked ? '#FF6B81' : '#666666')

          Text(postObj.post.likes.toString())
            .fontSize(14)
            .fontColor(postObj.post.isLiked ? '#FF6B81' : '#666666')
        }
        .padding({ left: 16, right: 12, top: 8, bottom: 8 })
        .onClick(() => {
          this.handleLike(postObj.post);
        })

        // 评论按钮
        Row({ space: 6 }) {
          Image('common/comment.png')
            .width(20)
            .height(20)
            .fillColor('#666666')

          Text(postObj.post.comments.toString())
            .fontSize(14)
            .fontColor('#666666')
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })

        Blank()
      }
      .width('100%')
      .border({ width: { top: 1 }, color: '#F0F0F0' })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }

  // 格式化时间显示
  formatTime(timestamp: number): string {
    const now = Date.now();
    const diff = now - timestamp;
    const minute = 60 * 1000;
    const hour = 60 * minute;
    const day = 24 * hour;

    if (diff < minute) {
      return '刚刚';
    } else if (diff < hour) {
      return `${Math.floor(diff / minute)}分钟前`;
    } else if (diff < day) {
      return `${Math.floor(diff / hour)}小时前`;
    } else if (diff < 7 * day) {
      return `${Math.floor(diff / day)}天前`;
    } else {
      const date = new Date(timestamp);
      return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
    }
  }
}