import { FoodDatabase } from './FoodDatabase';
import { Post } from './Post';
import router from '@ohos.router';
import prompt from '@ohos.promptAction';

// 定义路由参数接口
interface RouterParams {
  refreshCallback?: () => void;
}

@Entry
@Component
 struct PublishPost {
  @State content: string = ''; // 帖子内容
  @State selectedImages: string[] = []; // 已选图片
  @State isPublishing: boolean = false; // 发布中状态
  private foodDb: FoodDatabase = FoodDatabase.getInstance();
  private refreshCallback?: () => void; // 回调函数

  aboutToAppear() {
    console.info('[PublishPost] aboutToAppear called');
    // 获取传递的参数
    const params = router.getParams() as RouterParams;
    console.info('[PublishPost] Received params:', JSON.stringify(params));

    if (params && params.refreshCallback) {
      this.refreshCallback = params.refreshCallback as () => void;
      console.info('[PublishPost] Refresh callback set');
    } else {
      console.warn('[PublishPost] No refresh callback provided');
    }
  }

  // 从相册选择图片
  async selectFromGallery() {
    try {
      prompt.showToast({
        message: '图片选择功能开发中',
        duration: 2000
      });
    } catch (err) {
      console.error(`[PublishPost] Failed to select photos: ${JSON.stringify(err)}`);
      prompt.showToast({
        message: '选择图片失败',
        duration: 2000
      });
    }
  }

  // 拍照
  async takePhoto() {
    prompt.showToast({
      message: '相机功能开发中，请先使用相册选择',
      duration: 2000
    });
  }

  // 移除图片
  removeImage(index: number) {
    const newImages = [...this.selectedImages];
    newImages.splice(index, 1);
    this.selectedImages = newImages;
  }

  // 发布帖子
  async publishPost() {
    if (!this.content.trim() && this.selectedImages.length === 0) {
      prompt.showToast({
        message: '请填写内容或选择图片',
        duration: 2000
      });
      return;
    }

    this.isPublishing = true;
    console.info('[PublishPost] Starting publish...');

    try {
      // 创建帖子对象
      const newPost = new Post(this.content, this.selectedImages);
      console.info('[PublishPost] Created new post:', {
        content: newPost.content.substring(0, 50) + (newPost.content.length > 50 ? '...' : ''),
        userId: newPost.userId,
        imagesCount: newPost.images.length
      });

      // 保存到数据库
      const postId = await this.foodDb.insertPost(newPost);
      console.info(`[PublishPost] Insert result: postId=${postId}`);

      if (postId > 0) {
        prompt.showToast({
          message: '发布成功',
          duration: 2000
        });

        // 清空表单
        this.content = '';
        this.selectedImages = [];

        // 触发回调刷新列表
        console.info('[PublishPost] Calling refresh callback...');
        if (this.refreshCallback) {
          this.refreshCallback();
        } else {
          console.warn('[PublishPost] Refresh callback is null!');
        }

        // 返回广场页
        try {
          console.info('[PublishPost] Navigating back to FoodSquare...');
          // 添加短暂延迟确保回调执行
          setTimeout(() => {
            router.back();
          }, 100);
        } catch (error) {
          console.error(`[PublishPost] Failed to navigate back: ${JSON.stringify(error)}`);
        }
      } else {
        prompt.showToast({
          message: '发布失败，请重试',
          duration: 2000
        });
      }
    } catch (err) {
      console.error(`[PublishPost] Failed to publish post: ${JSON.stringify(err)}`);
      prompt.showToast({
        message: '发布失败',
        duration: 2000
      });
    } finally {
      this.isPublishing = false;
    }
  }

  build() {
    Column() {
      // 导航栏
      Row({ space: 0 }) {
        // 返回按钮
        Image('common/back.png')
          .width(24)
          .height(24)
          .margin({ left: 12 })
          .onClick(() => {
            try {
              console.info('[PublishPost] Manual back navigation');
              router.back();
            } catch (error) {
              console.error(`[PublishPost] Failed to navigate back: ${JSON.stringify(error)}`);
            }
          })

        Text('发布帖子')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 发布按钮
        Button('发布', { type: ButtonType.Normal, stateEffect: true })
          .backgroundColor(this.isPublishing ? '#CCCCCC' : '#FF6B81')
          .fontColor(Color.White)
          .fontSize(16)
          .padding({ left: 20, right: 20, top: 8, bottom: 8 })
          .margin({ right: 12 })
          .enabled(!this.isPublishing)
          .onClick(() => {
            this.publishPost();
          })
      }
      .width('100%')
      .height(60)
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)
      .shadow({ radius: 2, color: '#20000000' })

      // 内容编辑区域
      Scroll() {
        Column({ space: 16 }) {
          // 文本输入
          TextArea({ text: this.content, placeholder: '分享你的美食发现...' })
            .width('100%')
            .height(120)
            .fontSize(16)
            .backgroundColor(Color.White)
            .onChange((value: string) => {
              this.content = value;
            })

          // 图片预览区域
          if (this.selectedImages.length > 0) {
            Column({ space: 8 }) {
              Text('已选图片')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .textAlign(TextAlign.Start)

              // 图片网格
              GridRow({ columns: 3, gutter: 8 }) {
                ForEach(this.selectedImages, (image: string, index: number) => {
                  GridCol({ span: 1 }) {
                    Stack({ alignContent: Alignment.TopEnd }) {
                      Image(image)
                        .width('100%')
                        .aspectRatio(1)
                        .objectFit(ImageFit.Cover)
                        .borderRadius(8)

                      // 删除按钮
                      Image('common/close_circle.png')
                        .width(20)
                        .height(20)
                        .margin({ top: 4, right: 4 })
                        .onClick(() => {
                          this.removeImage(index);
                        })
                    }
                  }
                })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(8)
          }

          // 媒体选择区域
          Column({ space: 12 }) {
            Text('添加图片')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .textAlign(TextAlign.Start)

            Row({ space: 20 }) {
              // 从相册选择
              Column({ space: 8 }) {
                Image('common/photo.png')
                  .width(60)
                  .height(60)
                  .padding(16)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(12)

                Text('相册')
                  .fontSize(14)
                  .fontColor('#666666')
              }
              .onClick(() => {
                this.selectFromGallery();
              })

              // 拍照
              Column({ space: 8 }) {
                Image('common/camera.png')
                  .width(60)
                  .height(60)
                  .padding(16)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(12)

                Text('拍照')
                  .fontSize(14)
                  .fontColor('#666666')
              }
              .onClick(() => {
                this.takePhoto();
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(8)
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F8F8F8')
    }
    .width('100%')
    .height('100%')
  }
}