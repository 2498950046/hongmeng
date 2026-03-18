没问题！如果是纯本地数据库开发，对你们小组来说其实**更容易把控，也更方便调试**。在鸿蒙（HarmonyOS）中，本地关系型数据库使用的是 **`@ohos.data.relationalStore`**（底层是 SQLite）。

既然是4个人协作操作同一个本地 SQLite 数据库，**“规范”就是重中之重**。否则很容易出现“你建的表我查不到”或者“数据库被锁死”的问题。

下面我为你们整理了一套**《本地数据库协作规范与核心代码模版》**，你们可以直接照抄进项目里。

------

### 第一步：统一定义数据库表结构（SQL 语句）

在 SQLite 中，没有数组类型，所以图片列表等复杂数据需要转成 `JSON 字符串` (TEXT) 存储。请大家严格按照以下字段名和类型开发：

#### 1. 用户表 `users` (成员 D 负责)

SQL

```
CREATE TABLE IF NOT EXISTS users (
    user_id TEXT PRIMARY KEY,       -- 用户ID (可用时间戳字符串)
    nickname TEXT NOT NULL,         -- 昵称
    avatar_url TEXT,                -- 头像本地路径
    create_time INTEGER             -- 注册时间戳
)
```

#### 2. 餐厅表 `restaurants` (成员 A、B 负责)

SQL

```
CREATE TABLE IF NOT EXISTS restaurants (
    restaurant_id TEXT PRIMARY KEY, -- 餐厅ID
    name TEXT NOT NULL,             -- 餐厅名称
    category TEXT,                  -- 分类(火锅/烧烤等)
    address TEXT,                   -- 地址
    latitude REAL,                  -- 纬度 (REAL 对应浮点数)
    longitude REAL,                 -- 经度
    rating REAL,                    -- 评分
    cover_url TEXT                  -- 封面图本地路径
)
```

#### 3. 探店帖子表 `posts` (成员 C 负责)

SQL

```
CREATE TABLE IF NOT EXISTS posts (
    post_id TEXT PRIMARY KEY,       -- 帖子ID
    user_id TEXT NOT NULL,          -- 发布者ID (关联users表)
    restaurant_id TEXT NOT NULL,    -- 关联的餐厅ID (关联restaurants表)
    content TEXT,                   -- 评价文本
    image_urls TEXT,                -- 图片路径数组 (存入前用 JSON.stringify() 转成字符串)
    likes_count INTEGER DEFAULT 0,  -- 点赞数
    publish_time INTEGER            -- 发布时间戳
)
```

#### 4. 收藏表 `collections` (成员 D 负责)

SQL

```
CREATE TABLE IF NOT EXISTS collections (
    collection_id TEXT PRIMARY KEY, -- 收藏ID
    user_id TEXT NOT NULL,          -- 收藏者ID
    target_id TEXT NOT NULL,        -- 收藏的目标ID (餐厅ID或帖子ID)
    type INTEGER NOT NULL           -- 1:收藏餐厅, 2:收藏帖子
)
```

------

### 第二步：建立唯一的“数据库管家”（核心架构）

**【规定】：** 不要每个人都在自己的页面里去初始化数据库！必须由**组长（成员 A）**建一个公共的 `RdbManager.ets` 工具类。所有人都通过这个工具类去拿数据库操作对象。

**新建 `utils/RdbManager.ets`：**

TypeScript

```
import relationalStore from '@ohos.data.relationalStore';
import UIAbility from '@ohos.app.ability.UIAbility';

export class RdbManager {
  private static rdbStore: relationalStore.RdbStore | null = null;

  // 1. 初始化数据库 (组长在 EntryAbility 的 onCreate 中调用)
  public static async initDB(context: any) {
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'TasteTrek.db', // 数据库文件名
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      RdbManager.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      console.info("RDB", "数据库创建/打开成功");

      // 2. 执行建表语句 (把上面定好的4个 CREATE TABLE 语句写在这里)
      const createUsersSQL = `CREATE TABLE IF NOT EXISTS users (user_id TEXT PRIMARY KEY, nickname TEXT NOT NULL, avatar_url TEXT, create_time INTEGER)`;
      const createRestaurantsSQL = `CREATE TABLE IF NOT EXISTS restaurants (restaurant_id TEXT PRIMARY KEY, name TEXT NOT NULL, category TEXT, address TEXT, latitude REAL, longitude REAL, rating REAL, cover_url TEXT)`;
      const createPostsSQL = `CREATE TABLE IF NOT EXISTS posts (post_id TEXT PRIMARY KEY, user_id TEXT NOT NULL, restaurant_id TEXT NOT NULL, content TEXT, image_urls TEXT, likes_count INTEGER DEFAULT 0, publish_time INTEGER)`;
      const createCollectionsSQL = `CREATE TABLE IF NOT EXISTS collections (collection_id TEXT PRIMARY KEY, user_id TEXT NOT NULL, target_id TEXT NOT NULL, type INTEGER NOT NULL)`;

      await RdbManager.rdbStore.executeSql(createUsersSQL);
      await RdbManager.rdbStore.executeSql(createRestaurantsSQL);
      await RdbManager.rdbStore.executeSql(createPostsSQL);
      await RdbManager.rdbStore.executeSql(createCollectionsSQL);
      
      console.info("RDB", "所有数据表初始化完毕");
      
      // 注意：这里可以加一段逻辑，如果是第一次打开App，插入几条"假数据(Mock)"方便大家开发时有东西显示
      
    } catch (err) {
      console.error("RDB", `数据库初始化失败: ${err}`);
    }
  }

  // 3. 提供一个获取 Store 的方法供4个成员调用
  public static getStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error("数据库未初始化");
    }
    return this.rdbStore;
  }
}
```

------

### 第三步：4个成员的实战操作规范

数据库建好后，大家就可以在各自的模块里干活了。

**【规范 1：新增数据】（以成员 C 发布帖子为例）**

使用 `insert` 方法，传一个 `ValuesBucket` 对象：

TypeScript

```
import { RdbManager } from '../utils/RdbManager';
import relationalStore from '@ohos.data.relationalStore';

async function insertPost(userId: string, restId: string, content: string, images: Array<string>) {
  const store = RdbManager.getStore();
  
  // 组装要插入的数据
  const valueBucket: relationalStore.ValuesBucket = {
    'post_id': Date.now().toString(), // 用时间戳当唯一ID
    'user_id': userId,
    'restaurant_id': restId,
    'content': content,
    'image_urls': JSON.stringify(images), // 数组必须转成 JSON 字符串存入 SQLite
    'likes_count': 0,
    'publish_time': Date.now()
  };

  try {
    let rowId = await store.insert('posts', valueBucket);
    console.info('发布成功，行号：', rowId);
  } catch (err) {
    console.error('发布失败', err);
  }
}
```

**【规范 2：查询数据】（以成员 A 首页查“火锅”店为例）**

使用 `RdbPredicates` 构造查询条件：

TypeScript

```
import { RdbManager } from '../utils/RdbManager';
import relationalStore from '@ohos.data.relationalStore';

async function getHotpotRestaurants() {
  const store = RdbManager.getStore();
  
  // 构造查询条件：查 restaurants 表，category 等于 "火锅"
  let predicates = new relationalStore.RdbPredicates('restaurants');
  predicates.equalTo('category', '火锅');

  try {
    // 执行查询，返回 resultSet 结果集
    let resultSet = await store.query(predicates, ['restaurant_id', 'name', 'cover_url']);
    
    let resultList = [];
    // 遍历结果集
    while (resultSet.goToNextRow()) {
      let id = resultSet.getString(resultSet.getColumnIndex('restaurant_id'));
      let name = resultSet.getString(resultSet.getColumnIndex('name'));
      let cover = resultSet.getString(resultSet.getColumnIndex('cover_url'));
      
      resultList.push({ id, name, cover });
    }
    // 务必释放结果集内存！
    resultSet.close(); 
    
    return resultList;
  } catch (err) {
    console.error('查询失败', err);
  }
}
```

------

### 小组协作避坑指南（重点提配）

1. **预置假数据（Mock Data）：** 既然是本地数据库，刚装上App时数据库是空的！建议组长在 `RdbManager.ets` 初始化完表之后，写一个判断：如果 `restaurants` 表为空，就用代码自动 `insert` 10条不同分类的美食店数据进去。这样其他 3 个人一跑代码，页面上立马就有内容可以测试了。
2. **数组与对象的存储：** 强调一遍，SQLite 存不了数组。成员 C 存多张图片路径时，一定要 `JSON.stringify(urls)` 存入；查询拿出来时，记得用 `JSON.parse(str)` 转回数组再给 ArkUI 渲染。
3. **ResultSet 内存泄漏：** 成员 A、B 在做查询（`store.query`）拿到 `resultSet` 处理完数据后，**必须要写 `resultSet.close()`**，否则应用跑一会就会卡死或闪退！

有了这个标准规范，你们四个人的代码合并时，数据流向就会极其清晰！组长可以先把 `RdbManager` 写好推送到 Git，大家拉取代码后就可以快乐开工了。



