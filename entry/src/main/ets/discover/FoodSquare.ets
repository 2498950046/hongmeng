import { FoodDatabase } from './FoodDatabase';
import { Post } from './Post';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';

// 定义接口
interface PostItemParams {
  post: Post;
  onLikeClick: (post: Post) => void;
  onCommentClick: (post: Post) => void;
}

@Entry
@Component
export struct FoodSquare {
  @State posts: Post[] = []; // 帖子列表
  @State showPublishDialog: boolean = false; // 发布弹窗
  private foodDb: FoodDatabase = FoodDatabase.getInstance();

  // ✅ 新增：只要页面回到前台（比如从评论页 router.back() 回来），就强制拉取最新数据！
  onPageShow() {
    console.info('[FoodSquare] onPageShow: 页面重新出现在前台，强制刷新列表数据');

    // 为了让 UI 引擎感知到剧烈变化，我们可以先瞬间清空，再赋新值（可选，但极其稳妥）
    this.posts = [];

    // 重新查询数据库，拿到最新的评论数和点赞数
    this.loadPosts();
  }

  aboutToAppear() {
    console.info('[FoodSquare] aboutToAppear called');
    this.initDatabaseAndLoadPosts();

    // ✅ 监听全局刷新事件
    this.getContext().eventHub.on('refreshFoodSquare', () => {
      console.info('[FoodSquare] 收到评论页的刷新通知，正在重新加载帖子...');
      this.loadPosts();
    });
  }

  // ✅ 页面销毁时取消监听，防止内存泄漏
  aboutToDisappear() {
    this.getContext().eventHub.off('refreshFoodSquare');
  }

  // 获取上下文
  getContext(): common.Context {
    return getContext(this) as common.Context;
  }

  // 初始化数据库并加载帖子
  async initDatabaseAndLoadPosts() {
    try {
      const ctx = this.getContext() as common.UIAbilityContext;
      console.info('[FoodSquare] Initializing database...');
      await this.foodDb.initialize(ctx);
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

      if (this.posts.length === 0) {
        console.info('[FoodSquare] No posts found, you can add a new post');
        const examplePost = new Post(
          '欢迎来到觅食记社区！这里是美食爱好者的聚集地，分享你的美食发现吧！',
          [],
          '美食小助手'
        );
        this.posts = [examplePost];
      }
    } catch (err) {
      console.error(`[FoodSquare] Failed to load posts: ${JSON.stringify(err)}`);
    }
  }

  // 处理点赞
  async handleLike(post: Post) {
    console.info(`[FoodSquare] Handling like for post ${post.id}`);

    const newLikes = post.isLiked ? post.likes - 1 : post.likes + 1;
    const newIsLiked = !post.isLiked;

    const updatedPosts = this.posts.map(p => {
      if (p.id === post.id) {
        const updatedPost = new Post(p.content, [...p.images], p.userName);
        updatedPost.id = p.id;
        updatedPost.userId = p.userId;
        updatedPost.userAvatar = p.userAvatar;
        updatedPost.likes = newLikes;
        updatedPost.comments = p.comments;
        updatedPost.isLiked = newIsLiked;
        updatedPost.createTime = p.createTime;
        return updatedPost;
      }
      const newPost = new Post(p.content, [...p.images], p.userName);
      newPost.id = p.id;
      newPost.userId = p.userId;
      newPost.userAvatar = p.userAvatar;
      newPost.likes = p.likes;
      newPost.comments = p.comments;
      newPost.isLiked = p.isLiked;
      newPost.createTime = p.createTime;
      return newPost;
    });

    this.posts = updatedPosts;

    try {
      const success = await this.foodDb.updateLike(post.id, newIsLiked, newLikes);
      if (!success) {
        await this.loadPosts();
      }
    } catch (err) {
      console.error(`[FoodSquare] Failed to update like: ${JSON.stringify(err)}`);
      await this.loadPosts();
    }
  }

  // 跳转到发布页
  navigateToPublish() {
    try {
      router.pushUrl({
        url: 'discover/PublishPost'
      });
    } catch (error) {
      console.error(`[FoodSquare] Failed to navigate: ${JSON.stringify(error)}`);
    }
  }

  // 跳转到评论页面
  navigateToCommentPage(post: Post) {
    try {
      router.pushUrl({
        url: 'discover/CommentPage',
        params: {
          postId: post.id,
          postContent: post.content,
          userName: post.userName
        }
      });
    } catch (error) {
      console.error(`[FoodSquare] Failed to navigate to comment page: ${JSON.stringify(error)}`);
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
        Column() {
          Text('📄')
            .fontSize(60)
            .fontColor('#CCCCCC')
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
          // 👇 核心修复：修改了这里的第三个参数！将评论数和点赞数绑定到组件的Key上！
          ForEach(this.posts, (post: Post) => {
            ListItem() {
              this.PostItem({
                post: post,
                onLikeClick: (clickedPost: Post) => {
                  this.handleLike(clickedPost);
                },
                onCommentClick: (clickedPost: Post) => {
                  this.navigateToCommentPage(clickedPost);
                }
              })
            }
          }, (post: Post) => `${post.id}_${post.likes}_${post.comments}`)
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
        Column() {
          if (postObj.post.userAvatar && postObj.post.userAvatar !== '') {
            Image(postObj.post.userAvatar)
              .width(40)
              .height(40)
              .borderRadius(20)
              .objectFit(ImageFit.Cover)
          } else {
            Text('👤')
              .fontSize(24)
              .fontColor('#4CAF50')
              .textAlign(TextAlign.Center)
              .width(40)
              .height(40)
              .backgroundColor('#E8F5E9')
              .borderRadius(20)
          }
        }
        .width(40)
        .height(40)

        Column({ space: 4 }) {
          Text(postObj.post.userName || '美食爱好者')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

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
      if (postObj.post.images && postObj.post.images.length > 0) {
        if (postObj.post.images.length === 1) {
          Text('🖼')
            .fontSize(100)
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(200)
            .fontColor('#999999')
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ left: 16, right: 16, bottom: 16 })
        } else {
          GridRow({ columns: 3, gutter: 4 }) {
            ForEach(postObj.post.images.slice(0, 9), (image: string, index: number) => {
              GridCol({ span: 1 }) {
                Text('🖼')
                  .fontSize(30)
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .aspectRatio(1)
                  .fontColor('#999999')
                  .backgroundColor('#F5F5F5')
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
          if (postObj.post.isLiked) {
            Text('❤').fontSize(20).fontColor('#FF6B81')
          } else {
            Text('🤍').fontSize(20).fontColor('#666666')
          }
          Text(postObj.post.likes.toString())
            .fontSize(14)
            .fontColor(postObj.post.isLiked ? '#FF6B81' : '#666666')
        }
        .padding({ left: 16, right: 12, top: 8, bottom: 8 })
        .onClick(() => {
          postObj.onLikeClick(postObj.post);
        })

        // 评论按钮
        Row({ space: 6 }) {
          Text('💬').fontSize(20).fontColor('#666666')
          Text(postObj.post.comments.toString())
            .fontSize(14)
            .fontColor('#666666')
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .onClick(() => {
          postObj.onCommentClick(postObj.post);
        })

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