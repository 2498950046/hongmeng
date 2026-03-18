import { FoodDatabase } from './FoodDatabase';
import { Post, Comment } from './Post';
import router from '@ohos.router';
import { BusinessError } from '@ohos.base';
import promptAction from '@ohos.promptAction';

// 定义路由参数接口
interface RouterParams {
  postId: number;
  postContent?: string;
  userName?: string;
  refreshCallback?: () => void;
}

// 定义CommentItem的参数接口
interface CommentItemParams {
  comment: Comment;
}

@Entry
@Component
struct CommentPage {
  @State comments: Comment[] = []; // 评论列表
  @State newComment: string = ''; // 新评论内容
  @State isSubmitting: boolean = false; // 提交中状态
  @State postContent: string = ''; // 帖子内容
  @State postUserName: string = ''; // 帖子作者

  private postId: number = 0;
  private foodDb: FoodDatabase = FoodDatabase.getInstance();
  private refreshCallback?: () => void; // 回调函数

  aboutToAppear() {
    console.info('[CommentPage] aboutToAppear called');

    // 获取传递的参数
    try {
      const params = router.getParams() as RouterParams;
      console.info('[CommentPage] Received params:', JSON.stringify(params));

      if (params) {
        this.postId = params.postId || 0;
        this.postContent = params.postContent || '';
        this.postUserName = params.userName || '美食爱好者';
        this.refreshCallback = params.refreshCallback as (() => void) || undefined;

        console.info(`[CommentPage] Post ID: ${this.postId}, Content: ${this.postContent}`);

        if (this.postId > 0) {
          this.loadComments();
        } else {
          console.error('[CommentPage] Invalid post ID');
          promptAction.showToast({
            message: '帖子ID无效',
            duration: 2000
          });
        }
      } else {
        console.error('[CommentPage] No params provided');
      }
    } catch (err) {
      console.error(`[CommentPage] Failed to get params: ${JSON.stringify(err)}`);
    }
  }

  // 加载评论
  async loadComments() {
    console.info(`[CommentPage] Loading comments for post ${this.postId}`);

    try {
      const loadedComments = await this.foodDb.queryCommentsByPostId(this.postId);
      console.info(`[CommentPage] Loaded ${loadedComments.length} comments`);
      this.comments = [...loadedComments];
    } catch (err) {
      console.error(`[CommentPage] Failed to load comments: ${JSON.stringify(err)}`);
      promptAction.showToast({
        message: '加载评论失败',
        duration: 2000
      });
    }
  }

  // 提交评论
  // 提交评论
  async submitComment() {
    if (!this.newComment.trim()) {
      promptAction.showToast({ message: '请输入评论内容', duration: 2000 });
      return;
    }

    this.isSubmitting = true;
    console.info('[CommentPage] Submitting comment...');

    try {
      // 1. 创建评论对象
      const comment = new Comment(this.postId, this.newComment);

      // 2. 保存到数据库
      const commentId = await this.foodDb.insertComment(comment);

      if (commentId > 0) {
        promptAction.showToast({ message: '评论成功', duration: 2000 });

        // 3. 清空输入框
        this.newComment = '';

        // 4. 重新加载当前页面的评论列表
        await this.loadComments();

        // 5. 核心：通过 EventHub 广播全局事件，通知上一页(广场页)刷新！
        getContext(this).eventHub.emit('refreshFoodSquare');

      } else {
        promptAction.showToast({ message: '评论失败，请重试', duration: 2000 });
      }
    } catch (err) {
      console.error(`[CommentPage] Failed to submit comment: ${JSON.stringify(err)}`);
      promptAction.showToast({ message: '评论失败', duration: 2000 });
    } finally {
      // 6. 无论成功失败，恢复按钮状态
      this.isSubmitting = false;
    }
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
      return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()} ${date.getHours()}:${date.getMinutes().toString().padStart(2, '0')}`;
    }
  }

  build() {
    Column() {
      // 导航栏
      Row({ space: 0 }) {
        // 返回按钮
        Row() {
          Text('←')
            .fontSize(20)
            .fontColor('#333333')
        }
        .padding({ left: 12 })
        .onClick(() => {
          try {
            router.back();
          } catch (error) {
            console.error(`[CommentPage] Failed to navigate back: ${JSON.stringify(error)}`);
          }
        })

        Text('评论')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位符，使标题居中
        Row() {
          Text('←')
            .fontSize(20)
            .fontColor(Color.Transparent)
        }
        .padding({ right: 12 })
        .width(24)
      }
      .width('100%')
      .height(60)
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)
      .shadow({ radius: 2, color: '#20000000' })

      // 帖子内容预览
      Column({ space: 8 }) {
        // 用户信息
        Row({ space: 8 }) {
          // 用户头像
          Column() {
            Text('👤')
              .fontSize(16)
              .fontColor('#4CAF50')
              .textAlign(TextAlign.Center)
              .width(30)
              .height(30)
              .backgroundColor('#E8F5E9')
              .borderRadius(15)
          }
          .width(30)
          .height(30)

          // 用户名
          Text(this.postUserName || '美食爱好者')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        // 帖子内容
        Text(this.postContent)
          .fontSize(15)
          .fontColor('#333333')
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(3)
          .width('100%')
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F9F9F9')
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      // 评论列表区域
      Column() {
        if (this.comments.length === 0) {
          // 没有评论时的提示
          Column() {
            Text('💬')
              .fontSize(40)
              .fontColor('#CCCCCC')
              .margin({ bottom: 12 })

            Text('还没有评论，快来抢沙发吧～')
              .fontSize(16)
              .fontColor('#999999')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          // 评论数量
          Text(`全部评论 (${this.comments.length})`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .margin({ left: 16, top: 12, bottom: 8 })
            .width('100%')
            .textAlign(TextAlign.Start)

          // 评论列表
          List({ space: 8 }) {
            ForEach(this.comments, (comment: Comment) => {
              ListItem() {
                this.CommentItem({ comment: comment })
              }
            }, (comment: Comment) => comment.id.toString())
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(Color.White)

      // 底部输入区域
      Row({ space: 8 }) {
        // 输入框
        TextInput({ text: this.newComment, placeholder: '说点什么...' })
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.newComment = value;
          })

        // 发送按钮
        Button('发送', { type: ButtonType.Capsule, stateEffect: true })
          .backgroundColor(this.isSubmitting ? '#CCCCCC' : '#FF6B81')
          .fontColor(Color.White)
          .fontSize(14)
          .width(60)
          .height(40)
          .enabled(!this.isSubmitting && this.newComment.trim().length > 0)
          .onClick(() => {
            this.submitComment();
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: '#F0F0F0' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  @Builder
  CommentItem(commentObj: CommentItemParams) {
    Row({ space: 12 }) {
      // 用户头像
      Column() {
        Text('👤')
          .fontSize(16)
          .fontColor('#4CAF50')
          .textAlign(TextAlign.Center)
          .width(40)
          .height(40)
          .backgroundColor('#E8F5E9')
          .borderRadius(20)
      }
      .width(40)
      .height(40)

      // 评论内容区域
      Column({ space: 4 }) {
        // 用户名和时间
        Row() {
          Text(commentObj.comment.userName || '匿名用户')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          Text(this.formatTime(commentObj.comment.createTime))
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: 8 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        // 评论内容
        Text(commentObj.comment.content)
          .fontSize(14)
          .fontColor('#333333')
          .width('100%')
          .textAlign(TextAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
  }
}