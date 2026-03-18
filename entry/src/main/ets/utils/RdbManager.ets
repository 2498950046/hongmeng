import relationalStore from '@ohos.data.relationalStore';

import common from '@ohos.app.ability.common'; // 添加这行新版导入
// 定义用户接口
interface User {
  user_id: string;
  nickname: string;
  avatar_url: string;
  create_time: number;
}

// 定义收藏接口
interface Collection {
  collection_id: string;
  user_id: string;
  target_id: string;
  type: number;
}

export class RdbManager {
  private static rdbStore: relationalStore.RdbStore | null = null;

  // 初始化数据库
  public static async initDB(context:common.UIAbilityContext): Promise<void> {
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'TasteTrek.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      const store = await relationalStore.getRdbStore(context, STORE_CONFIG);
      RdbManager.rdbStore = store;
      console.info("RDB", "数据库创建/打开成功");

      // 执行建表语句
      const createUsersSQL = 'CREATE TABLE IF NOT EXISTS users (user_id TEXT PRIMARY KEY, nickname TEXT NOT NULL, avatar_url TEXT, create_time INTEGER)';
      const createRestaurantsSQL = 'CREATE TABLE IF NOT EXISTS restaurants (restaurant_id TEXT PRIMARY KEY, name TEXT NOT NULL, category TEXT, address TEXT, latitude REAL, longitude REAL, rating REAL, cover_url TEXT)';
      const createPostsSQL = 'CREATE TABLE IF NOT EXISTS posts (post_id TEXT PRIMARY KEY, user_id TEXT NOT NULL, restaurant_id TEXT NOT NULL, content TEXT, image_urls TEXT, likes_count INTEGER DEFAULT 0, publish_time INTEGER)';
      const createCollectionsSQL = 'CREATE TABLE IF NOT EXISTS collections (collection_id TEXT PRIMARY KEY, user_id TEXT NOT NULL, target_id TEXT NOT NULL, type INTEGER NOT NULL)';

      await RdbManager.executeSql(createUsersSQL);
      await RdbManager.executeSql(createRestaurantsSQL);
      await RdbManager.executeSql(createPostsSQL);
      await RdbManager.executeSql(createCollectionsSQL);
      
      console.info("RDB", "所有数据表初始化完毕");
      
      // 插入测试数据
      await RdbManager.insertMockData();
      
    } catch (err) {
      console.error("RDB", `数据库初始化失败: ${JSON.stringify(err)}`);
    }
  }

  // 执行SQL语句的辅助方法
  private static async executeSql(sql: string): Promise<void> {
    if (!RdbManager.rdbStore) {
      throw new Error("数据库未初始化");
    }
    await RdbManager.rdbStore.executeSql(sql);
  }

  // 插入测试数据
  private static async insertMockData(): Promise<void> {
    if (!RdbManager.rdbStore) return;

    try {
      // 检查是否已有数据
      const predicates = new relationalStore.RdbPredicates('users');
      const resultSet = await RdbManager.rdbStore.query(predicates, []);
      const hasData = resultSet.rowCount > 0;
      resultSet.close();

      if (hasData) {
        console.info("RDB", "数据库已有数据，跳过测试数据插入");
        return;
      }

      // 插入测试用户
      const testUser: relationalStore.ValuesBucket = {
        'user_id': 'user_001',
        'nickname': '美食达人',
        'avatar_url': '',
        'create_time': Date.now()
      };
      await RdbManager.rdbStore.insert('users', testUser);

      // 插入测试餐厅
      const testRestaurants: relationalStore.ValuesBucket[] = [
        {
          'restaurant_id': 'rest_001',
          'name': '海底捞火锅',
          'category': '火锅',
          'address': '北京市朝阳区三里屯',
          'latitude': 39.9042,
          'longitude': 116.4074,
          'rating': 4.8,
          'cover_url': ''
        },
        {
          'restaurant_id': 'rest_002',
          'name': '日式居酒屋',
          'category': '日料',
          'address': '上海市黄浦区南京路',
          'latitude': 31.2304,
          'longitude': 121.4737,
          'rating': 4.6,
          'cover_url': ''
        }
      ];

      for (const restaurant of testRestaurants) {
        await RdbManager.rdbStore.insert('restaurants', restaurant);
      }

      console.info("RDB", "测试数据插入完毕");
    } catch (err) {
      console.error("RDB", `插入测试数据失败: ${JSON.stringify(err)}`);
    }
  }

  // 提供获取Store的方法
  public static getStore(): relationalStore.RdbStore {
    if (!RdbManager.rdbStore) {
      throw new Error("数据库未初始化");
    }
    return RdbManager.rdbStore;
  }

  // 用户相关操作
  public static async getUserById(userId: string): Promise<User | null> {
    const store = RdbManager.getStore();
    const predicates = new relationalStore.RdbPredicates('users');
    predicates.equalTo('user_id', userId);

    try {
      const resultSet = await store.query(predicates);
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        const user: User = {
          user_id: resultSet.getString(resultSet.getColumnIndex('user_id')),
          nickname: resultSet.getString(resultSet.getColumnIndex('nickname')),
          avatar_url: resultSet.getString(resultSet.getColumnIndex('avatar_url')),
          create_time: resultSet.getLong(resultSet.getColumnIndex('create_time'))
        };
        resultSet.close();
        return user;
      }
      resultSet.close();
      return null;
    } catch (err) {
      console.error("RDB", `查询用户失败: ${JSON.stringify(err)}`);
      return null;
    }
  }

  public static async createUser(nickname: string): Promise<string> {
    const store = RdbManager.getStore();
    const userId = `user_${Date.now()}`;
    
    const valueBucket: relationalStore.ValuesBucket = {
      'user_id': userId,
      'nickname': nickname,
      'avatar_url': '',
      'create_time': Date.now()
    };

    try {
      await store.insert('users', valueBucket);
      return userId;
    } catch (err) {
      console.error("RDB", `创建用户失败: ${JSON.stringify(err)}`);
      throw new Error(`创建用户失败: ${JSON.stringify(err)}`);
    }
  }

  // 收藏相关操作
  public static async addCollection(userId: string, targetId: string, type: number): Promise<void> {
    const store = RdbManager.getStore();
    const collectionId = `col_${Date.now()}`;
    
    const valueBucket: relationalStore.ValuesBucket = {
      'collection_id': collectionId,
      'user_id': userId,
      'target_id': targetId,
      'type': type
    };

    try {
      await store.insert('collections', valueBucket);
    } catch (err) {
      console.error("RDB", `添加收藏失败: ${JSON.stringify(err)}`);
      throw new Error(`添加收藏失败: ${JSON.stringify(err)}`);
    }
  }

  public static async removeCollection(userId: string, targetId: string, type: number): Promise<void> {
    const store = RdbManager.getStore();
    const predicates = new relationalStore.RdbPredicates('collections');
    predicates.equalTo('user_id', userId).equalTo('target_id', targetId).equalTo('type', type);

    try {
      await store.delete(predicates);
    } catch (err) {
      console.error("RDB", `删除收藏失败: ${JSON.stringify(err)}`);
      throw new Error(`删除收藏失败: ${JSON.stringify(err)}`);
    }
  }

  public static async getUserCollections(userId: string, type: number): Promise<Collection[]> {
    const store = RdbManager.getStore();
    const predicates = new relationalStore.RdbPredicates('collections');
    predicates.equalTo('user_id', userId).equalTo('type', type);

    try {
      const resultSet = await store.query(predicates);
      const collections: Collection[] = [];
      
      while (resultSet.goToNextRow()) {
        collections.push({
          collection_id: resultSet.getString(resultSet.getColumnIndex('collection_id')),
          target_id: resultSet.getString(resultSet.getColumnIndex('target_id')),
          type: resultSet.getLong(resultSet.getColumnIndex('type'))
        } as Collection);
      }
      
      resultSet.close();
      return collections;
    } catch (err) {
      console.error("RDB", `查询收藏失败: ${JSON.stringify(err)}`);
      return [];
    }
  }

  public static async isCollected(userId: string, targetId: string, type: number): Promise<boolean> {
    const store = RdbManager.getStore();
    const predicates = new relationalStore.RdbPredicates('collections');
    predicates.equalTo('user_id', userId).equalTo('target_id', targetId).equalTo('type', type);

    try {
      const resultSet = await store.query(predicates);
      const isCollected = resultSet.rowCount > 0;
      resultSet.close();
      return isCollected;
    } catch (err) {
      console.error("RDB", `检查收藏状态失败: ${JSON.stringify(err)}`);
      return false;
    }
  }
}