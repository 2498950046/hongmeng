import relationalStore from '@ohos.data.relationalStore';
import { Post, Comment } from './Post';
import common from '@ohos.app.ability.common';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'FoodCommunity.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const SQL_CREATE_TABLE_POST = `
  CREATE TABLE IF NOT EXISTS POSTS (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId TEXT,
    userName TEXT,
    userAvatar TEXT,
    content TEXT,
    images TEXT,
    likes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    isLiked INTEGER DEFAULT 0,
    createTime INTEGER
  )
`;

const SQL_CREATE_TABLE_COMMENT = `
  CREATE TABLE IF NOT EXISTS COMMENTS (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    postId INTEGER,
    userId TEXT,
    userName TEXT,
    content TEXT,
    createTime INTEGER
  )
`;

export class FoodDatabase {
  private rdbStore: relationalStore.RdbStore | null = null;
  private static instance: FoodDatabase = new FoodDatabase();

  static getInstance(): FoodDatabase {
    return FoodDatabase.instance;
  }

  // 初始化数据库
  async initialize(context: common.Context): Promise<void> {
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      await this.rdbStore.executeSql(SQL_CREATE_TABLE_POST);
      await this.rdbStore.executeSql(SQL_CREATE_TABLE_COMMENT);
      console.info('Database initialized successfully');

      // 尝试查询表来验证是否创建成功
      await this.queryAllPosts();
      console.info('[FoodDatabase] Table verification successful');
    } catch (err) {
      console.error(`Failed to initialize database: ${err.message}`);
    }
  }

  // 插入帖子
  async insertPost(post: Post): Promise<number> {
    if (!this.rdbStore) {
      console.error('Database not initialized');
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'userId': post.userId || 'user_001',
      'userName': post.userName,
      'userAvatar': post.userAvatar,
      'content': post.content,
      'images': JSON.stringify(post.images),
      'likes': post.likes,
      'comments': post.comments,
      'isLiked': post.isLiked ? 1 : 0,
      'createTime': post.createTime
    };

    console.info('[FoodDatabase] Inserting post:', {
      content: post.content.substring(0, 50) + (post.content.length > 50 ? '...' : ''),
      userId: post.userId,
      imagesCount: post.images.length
    });

    try {
      const insertId = await this.rdbStore.insert('POSTS', valueBucket);
      console.info(`[FoodDatabase] Inserted post with id: ${insertId}`);

      // 验证插入是否成功
      const predicates = new relationalStore.RdbPredicates('POSTS');
      predicates.equalTo('id', insertId);
      const resultSet = await this.rdbStore.query(predicates, ['id', 'content', 'createTime']);

      if (resultSet.rowCount > 0) {
        console.info('[FoodDatabase] Post inserted successfully, can be queried');
      } else {
        console.error('[FoodDatabase] Post inserted but cannot be queried');
      }
      resultSet.close();

      return insertId;
    } catch (err) {
      console.error(`[FoodDatabase] Failed to insert post: ${err.message}`);
      return -1;
    }
  }

  // 查询所有帖子
  async queryAllPosts(): Promise<Post[]> {
    if (!this.rdbStore) {
      console.error('[FoodDatabase] Database not initialized');
      return [];
    }

    const posts: Post[] = [];
    const predicates = new relationalStore.RdbPredicates('POSTS');
    predicates.orderByDesc('createTime');

    console.info('[FoodDatabase] Starting to query all posts');

    try {
      const resultSet = await this.rdbStore.query(predicates,
        ['id', 'userId', 'userName', 'userAvatar', 'content', 'images', 'likes', 'comments', 'isLiked', 'createTime']);

      console.info(`[FoodDatabase] Query result count: ${resultSet.rowCount} posts found`);

      while (resultSet.goToNextRow()) {
        const imagesJson = resultSet.getString(resultSet.getColumnIndex('images'));
        let imagesArray: string[] = [];

        try {
          imagesArray = JSON.parse(imagesJson);
        } catch (err) {
          console.error(`[FoodDatabase] Failed to parse images JSON: ${imagesJson}`);
        }

        const post = new Post(
          resultSet.getString(resultSet.getColumnIndex('content')),
          imagesArray,
          resultSet.getString(resultSet.getColumnIndex('userName'))
        );

        post.id = resultSet.getLong(resultSet.getColumnIndex('id'));
        post.userId = resultSet.getString(resultSet.getColumnIndex('userId'));
        post.userAvatar = resultSet.getString(resultSet.getColumnIndex('userAvatar'));
        post.likes = resultSet.getLong(resultSet.getColumnIndex('likes'));
        post.comments = resultSet.getLong(resultSet.getColumnIndex('comments'));
        post.isLiked = resultSet.getLong(resultSet.getColumnIndex('isLiked')) === 1;
        post.createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));

        console.info(`[FoodDatabase] Loaded post id=${post.id}, content="${post.content.substring(0, 30)}${post.content.length > 30 ? '...' : ''}"`);
        posts.push(post);
      }
      resultSet.close();
    } catch (err) {
      console.error(`[FoodDatabase] Failed to query posts: ${err.message}`);
    }

    console.info(`[FoodDatabase] Total posts loaded: ${posts.length}`);
    return posts;
  }

  // 更新点赞状态
  async updateLike(postId: number, isLiked: boolean, newLikes: number): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'isLiked': isLiked ? 1 : 0,
      'likes': newLikes
    };

    const predicates = new relationalStore.RdbPredicates('POSTS');
    predicates.equalTo('id', postId);

    try {
      const rows = await this.rdbStore.update(valueBucket, predicates);
      console.info(`[FoodDatabase] Updated like for post ${postId}, rows affected: ${rows}`);
      return rows > 0;
    } catch (err) {
      console.error(`[FoodDatabase] Failed to update like: ${err.message}`);
      return false;
    }
  }

  // 插入评论
  async insertComment(comment: Comment): Promise<number> {
    if (!this.rdbStore) {
      console.error('[FoodDatabase] Database not initialized');
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'postId': comment.postId,
      'userId': comment.userId,
      'userName': comment.userName,
      'content': comment.content,
      'createTime': comment.createTime
    };

    console.info('[FoodDatabase] Inserting comment:', {
      postId: comment.postId,
      content: comment.content
    });

    try {
      const insertId = await this.rdbStore.insert('COMMENTS', valueBucket);
      console.info(`[FoodDatabase] Inserted comment with id: ${insertId}`);

      // 更新帖子的评论数
      const postPredicates = new relationalStore.RdbPredicates('POSTS');
      postPredicates.equalTo('id', comment.postId);
      const postResult = await this.rdbStore.query(postPredicates, ['comments']);

      if (postResult.goToFirstRow()) {
        const currentComments = postResult.getLong(postResult.getColumnIndex('comments'));
        const updateValue: relationalStore.ValuesBucket = {
          'comments': currentComments + 1
        };
        await this.rdbStore.update(updateValue, postPredicates);
        console.info(`[FoodDatabase] Updated post ${comment.postId} comments count to ${currentComments + 1}`);
      }
      postResult.close();

      return insertId;
    } catch (err) {
      console.error(`[FoodDatabase] Failed to insert comment: ${err.message}`);
      return -1;
    }
  }

  // 根据帖子ID查询评论
  async queryCommentsByPostId(postId: number): Promise<Comment[]> {
    if (!this.rdbStore) {
      console.error('[FoodDatabase] Database not initialized');
      return [];
    }

    const comments: Comment[] = [];
    const predicates = new relationalStore.RdbPredicates('COMMENTS');
    predicates.equalTo('postId', postId);
    predicates.orderByAsc('createTime'); // 按时间升序，最早的在前

    console.info(`[FoodDatabase] Querying comments for postId: ${postId}`);

    try {
      const resultSet = await this.rdbStore.query(predicates,
        ['id', 'postId', 'userId', 'userName', 'content', 'createTime']);

      console.info(`[FoodDatabase] Query result count: ${resultSet.rowCount} comments found`);

      while (resultSet.goToNextRow()) {
        const comment = new Comment(
          resultSet.getLong(resultSet.getColumnIndex('postId')),
          resultSet.getString(resultSet.getColumnIndex('content')),
          resultSet.getString(resultSet.getColumnIndex('userName'))
        );

        comment.id = resultSet.getLong(resultSet.getColumnIndex('id'));
        comment.userId = resultSet.getString(resultSet.getColumnIndex('userId'));
        comment.createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));

        console.info(`[FoodDatabase] Loaded comment id=${comment.id} for post ${comment.postId}`);
        comments.push(comment);
      }
      resultSet.close();
    } catch (err) {
      console.error(`[FoodDatabase] Failed to query comments: ${err.message}`);
    }

    console.info(`[FoodDatabase] Total comments loaded: ${comments.length}`);
    return comments;
  }

  // 根据帖子ID查询评论数
  async getCommentCount(postId: number): Promise<number> {
    if (!this.rdbStore) {
      return 0;
    }

    const predicates = new relationalStore.RdbPredicates('COMMENTS');
    predicates.equalTo('postId', postId);

    try {
      const resultSet = await this.rdbStore.query(predicates, ['COUNT(*) as count']);
      if (resultSet.goToFirstRow()) {
        const count = resultSet.getLong(resultSet.getColumnIndex('count'));
        resultSet.close();
        return count;
      }
      resultSet.close();
    } catch (err) {
      console.error(`[FoodDatabase] Failed to get comment count: ${err.message}`);
    }
    return 0;
  }
}