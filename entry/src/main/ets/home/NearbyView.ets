// 用于地理位置信息服务（LocationKit），提供 getCurrentLocation 等 API 获取实时经纬度
import geoLocationManager from '@ohos.geoLocationManager';
// 用于权限管理模块，负责申请 ohos.permission.LOCATION 等敏感权限
import abilityAccessCtrl, { Permissions, PermissionRequestResult } from '@ohos.abilityAccessCtrl';
// 页面路由模块，用于从列表页跳转到店铺详情页（pushUrl）
import router from '@ohos.router';
// 关系型数据库操作模块，用于查询 SQLite 中的 restaurants 表
import relationalStore from '@ohos.data.relationalStore';
// 自定义数据库管理工具类，提供单例 store 实例，避免重复创建连接
import { RdbManager } from '../utils/RdbManager';

// 引入华为地图服务核心组件（API 11+ 标准，使用 map 命名空间）
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Component
export struct NearbyView {
  // 拿不到定位时，定位默认在成都天府广场
  @State currentLatitude: number = 30.287459;
  @State currentLongitude: number = 120.153576;
  // 存放全量数据（从数据库一次性查出所有餐厅，包含原始经纬度、评分等）
  @State allRestaurants: RestaurantInfo[] = [];
  // 存放筛选排序后展示的数据（实时响应用户评分筛选）
  @State nearbyRestaurants: RestaurantInfo[] = [];

  @State isLocating: boolean = true;
  @State locationDesc: string = '正在定位中...';

  // 筛选状态：用户输入的最低和最高评分（字符串形式，便于 TextInput 双向绑定）
  @State minRatingStr: string = '';
  @State maxRatingStr: string = '';

  // 地图控制器，用于后续操作地图（移动视角、添加大头针标记等）
  private mapController?: map.MapComponentController;

  // 地图初始化配置（默认先对准成都天府广场）
  @State mapOptions: mapCommon.MapOptions = {
    position: {
      target: { latitude: 30.287459, longitude: 120.153576 },
      zoom: 14 // 缩放级别（14左右能看清街道）
    }
  };

  // 地图加载完成的异步回调函数
  private mapCallback: AsyncCallback<map.MapComponentController> = (err, controller) => {
    if (!err) {
      console.info("Map", "地图加载成功！");
      // 保存控制器实例
      this.mapController = controller;
      // 地图加载完毕后，立刻同步刷新地图上的标记点
      this.updateMapMarkers();
    } else {
      console.error("Map", `地图加载失败: ${err.message}`);
    }
  };

  aboutToAppear() {
    // 页面即将显示时，优先申请定位权限，再获取位置，最后加载并计算距离数据
    this.requestLocationPermission();
  }

  // 申请定位权限
  async requestLocationPermission() {
    // 创建权限管理实例
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      // 需要申请的定位权限列表
      const permissions: Permissions[] = [
        'ohos.permission.LOCATION',               // 精确位置权限
        'ohos.permission.APPROXIMATELY_LOCATION'  // 模糊位置权限
      ];
      // 请求权限（异步弹出系统授权弹窗），返回授权结果
      let grantStatus: PermissionRequestResult =
        await atManager.requestPermissionsFromUser(getContext(), permissions);
      // 检查授权结果：如果任意一项权限被拒绝（返回值不为0）
      if (grantStatus.authResults.some(res => res !== 0)) {
        console.error('定位权限被拒绝');
        this.locationDesc = '定位权限被拒绝，使用默认位置';
        // 权限拒绝时仍然从数据库加载附近数据，只是基于默认经纬度
        await this.loadNearbyFromDB();
        return;
      }
      // 权限均已授予，获取真实位置
      await this.getCurrentLocation();
    } catch (err) {
      console.error('权限申请失败', JSON.stringify(err));
      this.locationDesc = '权限申请失败，使用默认位置';
      await this.loadNearbyFromDB();
    }
  }

  // 调用 geoLocationManager 获取当前位置
  async getCurrentLocation() {
    try {
      // 取得当前定位（异步 API，返回 Location 对象，包含 latitude、longitude）
      let location = await geoLocationManager.getCurrentLocation();
      this.currentLatitude = location.latitude;
      this.currentLongitude = location.longitude;
      // 计算当前的经纬度，显示当前经纬度（保留4位小数）
      this.locationDesc = `当前经纬度：${this.currentLatitude.toFixed(4)}, ${this.currentLongitude.toFixed(4)}`;

      // 拿到真实定位后，让地图镜头“飞”到用户真实位置
      if (this.mapController) {
        this.mapController.moveCamera({
          target: { latitude: this.currentLatitude, longitude: this.currentLongitude },
          zoom: 15
        });
      }

      await this.loadNearbyFromDB();
    } catch (err) {
      console.error('定位失败', JSON.stringify(err));
      this.locationDesc = '定位失败，使用默认位置';
      await this.loadNearbyFromDB();
    }
  }

  // 从本地SQLite的restaurants表中读取数据，计算与当前经纬度的距离并按距离升序排序
  async loadNearbyFromDB() {
    // 开始加载，显示 Loading 动画
    this.isLocating = true;
    let resultList: RestaurantInfo[] = [];
    try {
      // 获取数据库实例（单例）
      const store = RdbManager.getStore();
      // 创建查询条件，此处无条件
      let predicates = new relationalStore.RdbPredicates('restaurants');

      // 查询所有字段，便于后续详情页展示
      let resultSet = await store.query(
        predicates,
        ['restaurant_id', 'name', 'category', 'address', 'latitude', 'longitude', 'rating', 'cover_url']
      );

      // 遍历结果集，逐行提取数据
      while (resultSet.goToNextRow()) {
        const id = resultSet.getString(resultSet.getColumnIndex('restaurant_id'));
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        const category = resultSet.getString(resultSet.getColumnIndex('category'));
        const address = resultSet.getString(resultSet.getColumnIndex('address'));
        const latitude = resultSet.getDouble(resultSet.getColumnIndex('latitude'));
        const longitude = resultSet.getDouble(resultSet.getColumnIndex('longitude'));
        const rating = resultSet.getDouble(resultSet.getColumnIndex('rating'));
        const coverUrl = resultSet.getString(resultSet.getColumnIndex('cover_url'));

        // 计算当前餐厅与用户当前位置的距离
        const distance = this.calcDistance(
          this.currentLatitude,
          this.currentLongitude,
          latitude,
          longitude
        );

        // 将餐厅信息与计算出的距离一起存入临时数组
        resultList.push({
          id, name, category, address, latitude, longitude, rating, coverUrl, distance
        });
      }

      // 关闭 ResultSet，避免内存泄漏
      resultSet.close();
      // 将原始全量数据保存到 allRestaurants 状态变量
      this.allRestaurants = resultList;
      // 应用当前的评分筛选条件（默认显示全部并按距离排序）
      this.applyFilter();
    } catch (err) {
      console.error('从数据库加载附近餐厅失败', JSON.stringify(err));
    } finally {
      // 无论成功或失败，结束加载状态
      this.isLocating = false;
    }
  }

  // 根据当前条件进行筛选和排序
  applyFilter() {
    // 复制全量数据，避免直接修改原数组
    let list = [...this.allRestaurants];

    // 解析用户输入，如果未输入或输入非法则赋予默认极值
    let min = parseFloat(this.minRatingStr);
    let max = parseFloat(this.maxRatingStr);

    if (isNaN(min)) min = 0;   // 默认最低 0 分
    if (isNaN(max)) max = 5.0; // 默认最高 5 分

    // 根据评分区间过滤：保留评分在 [min, max] 范围内的店铺
    list = list.filter(item => item.rating >= min && item.rating <= max);

    // 默认按距离升序展示
    list.sort((a, b) => a.distance - b.distance);

    // 更新要展示的数据列表
    this.nearbyRestaurants = list;

    // 数据筛选完后，同步刷新地图上的大头针
    this.updateMapMarkers();
  }

  // 核心逻辑：在地图上批量绘制标记点（大头针）
  async updateMapMarkers() {
    if (!this.mapController) return;

    try {
      // 1. 先清空地图上已有的标记点
      this.mapController.clear();

      // 2. 标记用户自己的当前位置（使用默认蓝色点标识）
      await this.mapController.addMarker({
        position: { latitude: this.currentLatitude, longitude: this.currentLongitude },
        title: '我的位置',
        clickable: false
      });

      // 3. 遍历筛选后的餐厅列表，逐个绘制大头针
      for (let item of this.nearbyRestaurants) {
        await this.mapController.addMarker({
          position: { latitude: item.latitude, longitude: item.longitude },
          title: item.name, // 点击标记后显示的主标题
          snippet: `${item.category} | 评分: ${item.rating.toFixed(1)} | 距离: ${item.distance.toFixed(1)}km`, // 副标题详情
          clickable: true
        });
      }
      console.info("Map", "地图大头针刷新完毕！");
    } catch (error) {
      console.error("Map", `刷新大头针失败: ${JSON.stringify(error)}`);
    }
  }

  // 计算两点经纬度之间的距离（km）
  // R 是地球平均半径（单位：km），取值 6371 是常用近似值（实际地球半径在 6356~6378 km 之间）
  // 整体计算逻辑采用 Haversine 公式（球面三角学），用于计算地球表面两点间的大圆距离
  // 公式推导：先将经纬度差转为弧度，计算 a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)
  // 然后 c = 2 * atan2(sqrt(a), sqrt(1-a)) ，最后 distance = R * c
  calcDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371;
    // 将纬度差、经度差转换为弧度
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    // 应用 Haversine 公式计算中间值 a
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    // 计算中心角 c（弧度）
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    // 距离 = 半径 * 中心角
    return R * c;
  }

  // 该函数将角度（度）转换为弧度（radians），因为 Math.sin、Math.cos、Math.atan2 等三角函数要求输入为弧度制（JS 标准）
  deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
  }

  build() {
    Column() {
      // 上半部分展示地图组件，占据屏幕 40% 的高度
      MapComponent({
        mapOptions: this.mapOptions,
        mapCallback: this.mapCallback
      })
        .width('100%')
        .height('40%')

      // 中部：状态与区间输入筛选栏（评分过滤 UI）
      Column() {
        Row({ space: 8 }) {
          Text('评分筛选:')
            .fontSize(14)
            .fontColor('#333')

          // 设置最低分输入框（支持小数输入，绑定到状态变量）
          TextInput({ placeholder: '最低' })
            .type(InputType.NUMBER_DECIMAL)
            .width(60)
            .height(32)
            .fontSize(13)
            .onChange((value: string) => this.minRatingStr = value)

          // 输入框之间以‘-’相连
          Text('-').fontSize(14)

          // 设置最高分输入框
          TextInput({ placeholder: '最高' })
            .type(InputType.NUMBER_DECIMAL)
            .width(60)
            .height(32)
            .fontSize(13)
            .onChange((value: string) => this.maxRatingStr = value)

          Button('确定')
            .height(32)
            .fontSize(14)
            .onClick(() => {
              this.applyFilter();
            })

          Blank()

          // 显示位置信息（动态更新定位状态或默认经纬度）
          Text(this.locationDesc)
            .fontSize(10)
            .fontColor('#999')
            .maxLines(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(Color.White)
        // 增加底部阴影，使上方控制栏与下方列表有层级感
        .shadow({ radius: 2, color: '#10000000', offsetY: 2 })
      }.width('100%').zIndex(2)

      // 下半部分：根据定位加载状态显示不同内容
      if (this.isLocating) {
        LoadingProgress().width(50).height(50).margin({ top: 40 });
      } else if (this.nearbyRestaurants.length === 0) {
        Text('该评分区间暂无餐厅').margin({ top: 40 }).fontColor('#999');
      } else {
        // 列表展示过滤排序后的餐厅
        List({ space: 12 }) {
          ForEach(this.nearbyRestaurants, (item: RestaurantInfo) => {
            ListItem() {
              // 调用自定义构建函数渲染每个列表项
              this.restaurantItem(item)
            }
            .onClick(() => {
              // 点击列表项，跳转到店铺详情页，并传递餐厅 ID
              router.pushUrl({
                url: 'pages/StoreDetailView',
                params: { restaurantId: item.id }
              });
            })
          })
        }
        .width('100%')
        // layoutWeight(1) 使其自动撑满屏幕剩余的所有高度
        .layoutWeight(1)
        .padding(12)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8f8f8')
  }

  // 商铺详细信息展示（列表项卡片）
  @Builder
  restaurantItem(item: RestaurantInfo) {
    Row() {
      // 商铺图标（使用资源引用，支持本地图片）
      Image($r('app.media.' + item.coverUrl))
        .width(80)
        .height(80)
        .borderRadius(8)
        .objectFit(ImageFit.Cover) // 保持图片比例裁剪
        .margin({ right: 12 })

      // 商铺信息，包括距离、评分等
      Column({ space: 6 }) {
        Text(item.name).fontSize(16).fontWeight(FontWeight.Medium).width('100%')
        Text(`${item.category} · 距离 ${item.distance.toFixed(1)}km`).fontSize(13).fontColor('#666').width('100%')
        Text(`⭐ ${item.rating.toFixed(1)}`).fontSize(13).fontColor('#ff8c00').width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(8)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }
}

interface RestaurantInfo {
  id: string;
  name: string;
  category: string;
  address: string;
  latitude: number;
  longitude: number;
  rating: number;
  coverUrl: string;
  distance: number;
}