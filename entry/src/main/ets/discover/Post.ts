// 帖子数据模型
export class Post {
  id: number = 0; // 帖子ID
  userId: string = ''; // 用户ID
  userName: string = ''; // 用户名
  userAvatar: string = ''; // 用户头像路径
  content: string = ''; // 帖子内容
  images: string[] = []; // 图片URI数组
  likes: number = 0; // 点赞数
  comments: number = 0; // 评论数
  isLiked: boolean = false; // 当前用户是否点赞
  createTime: number = Date.now(); // 创建时间戳

  constructor(content: string, images: string[] = [], userName: string = '美食达人') {
    this.content = content;
    this.images = images;
    this.userName = userName;
    this.userId = this.generateUserId(); // 生成一个用户ID
    this.userAvatar = 'common/default_avatar.png'; // 默认头像
    this.createTime = Date.now();
  }

  // 生成一个简单的用户ID（实际项目中应该从用户系统获取）
  private generateUserId(): string {
    return 'user_' + Math.random().toString(36).substring(2, 9);
  }
}

// 评论数据模型
export class Comment {
  id: number = 0;
  postId: number = 0;
  userId: string = '';
  userName: string = '';
  content: string = '';
  createTime: number = Date.now();

  constructor(postId: number, content: string, userName: string = '用户') {
    this.postId = postId;
    this.content = content;
    this.userName = userName;
    this.userId = 'user_' + Math.random().toString(36).substring(2, 9);
    this.createTime = Date.now();
  }
}