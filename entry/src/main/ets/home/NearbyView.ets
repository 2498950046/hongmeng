// 用于地理位置信息服务
import geoLocationManager from '@ohos.geoLocationManager';
// 用于权限管理
import abilityAccessCtrl, { Permissions, PermissionRequestResult } from '@ohos.abilityAccessCtrl';
// 页面路由
import router from '@ohos.router';
// 关系型数据库
import relationalStore from '@ohos.data.relationalStore';
// 自定义数据库管理工具类
import { RdbManager } from '../utils/RdbManager';

// ✅ 新增：引入华为地图服务核心组件
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Component
export struct NearbyView {
  // 默认定位（成都天府广场）
  @State currentLatitude: number = 30.657;
  @State currentLongitude: number = 104.066;

  @State allRestaurants: RestaurantInfo[] = [];
  @State nearbyRestaurants: RestaurantInfo[] = [];

  @State isLocating: boolean = true;
  @State locationDesc: string = '正在定位中...';

  @State minRatingStr: string = '';
  @State maxRatingStr: string = '';

  // ✅ 新增：地图控制器，用于后续操作地图（移动视角、画点）
  private mapController?: map.MapComponentController;

  // ✅ 新增：地图初始化配置
  @State mapOptions: mapCommon.MapOptions = {
    position: {
      target: { latitude: 30.657, longitude: 104.066 }, // 初始先对准默认坐标
      zoom: 14 // 缩放级别
    }
  };

  // ✅ 新增：地图加载成功的回调
  private mapCallback: AsyncCallback<map.MapComponentController> = (err, controller) => {
    // 里面的逻辑不用动
    if (!err) {
      console.info("Map", "地图加载成功！");
      this.mapController = controller;
      this.updateMapMarkers();
    } else {
      console.error("Map", `地图加载失败: ${err.message}`);
    }
  };

  aboutToAppear() {
    this.requestLocationPermission();
  }

  // 申请定位权限
  async requestLocationPermission() {
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      const permissions: Permissions[] = [
        'ohos.permission.LOCATION',
        'ohos.permission.APPROXIMATELY_LOCATION'
      ];
      let grantStatus: PermissionRequestResult =
        await atManager.requestPermissionsFromUser(getContext(), permissions);

      if (grantStatus.authResults.some(res => res !== 0)) {
        console.error('定位权限被拒绝');
        this.locationDesc = '定位权限被拒绝，使用默认位置';
        await this.loadNearbyFromDB();
        return;
      }
      await this.getCurrentLocation();
    } catch (err) {
      console.error('权限申请失败', JSON.stringify(err));
      this.locationDesc = '权限申请失败，使用默认位置';
      await this.loadNearbyFromDB();
    }
  }

  // 获取当前位置
  async getCurrentLocation() {
    try {
      let location = await geoLocationManager.getCurrentLocation();
      this.currentLatitude = location.latitude;
      this.currentLongitude = location.longitude;
      this.locationDesc = `当前位置已获取：${this.currentLatitude.toFixed(4)}, ${this.currentLongitude.toFixed(4)}`;

      // ✅ 新增：拿到真实定位后，让地图镜头“飞”到用户真实位置
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

  // 从本地SQLite加载数据
  async loadNearbyFromDB() {
    this.isLocating = true;
    let resultList: RestaurantInfo[] = [];
    try {
      const store = RdbManager.getStore();
      let predicates = new relationalStore.RdbPredicates('restaurants');

      let resultSet = await store.query(
        predicates,
        ['restaurant_id', 'name', 'category', 'address', 'latitude', 'longitude', 'rating', 'cover_url']
      );

      while (resultSet.goToNextRow()) {
        const id = resultSet.getString(resultSet.getColumnIndex('restaurant_id'));
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        const category = resultSet.getString(resultSet.getColumnIndex('category'));
        const address = resultSet.getString(resultSet.getColumnIndex('address'));
        const latitude = resultSet.getDouble(resultSet.getColumnIndex('latitude'));
        const longitude = resultSet.getDouble(resultSet.getColumnIndex('longitude'));
        const rating = resultSet.getDouble(resultSet.getColumnIndex('rating'));
        const coverUrl = resultSet.getString(resultSet.getColumnIndex('cover_url'));

        const distance = this.calcDistance(
          this.currentLatitude, this.currentLongitude, latitude, longitude
        );

        resultList.push({ id, name, category, address, latitude, longitude, rating, coverUrl, distance });
      }

      resultSet.close();
      this.allRestaurants = resultList;
      this.applyFilter();
    } catch (err) {
      console.error('从数据库加载附近餐厅失败', JSON.stringify(err));
    } finally {
      this.isLocating = false;
    }
  }

  // 筛选排序
  applyFilter() {
    let list = [...this.allRestaurants];
    let min = parseFloat(this.minRatingStr);
    let max = parseFloat(this.maxRatingStr);

    if (isNaN(min)) min = 0;
    if (isNaN(max)) max = 5.0;

    list = list.filter(item => item.rating >= min && item.rating <= max);
    list.sort((a, b) => a.distance - b.distance);

    this.nearbyRestaurants = list;

    // ✅ 新增：数据筛选完后，同步刷新地图上的大头针！
    this.updateMapMarkers();
  }

  // ✅ 新增核心逻辑：在地图上批量打点
  async updateMapMarkers() {
    if (!this.mapController) return;

    try {
      // 1. 先清空地图上老的大头针
      this.mapController.clear();

      // 2. 标记用户自己的位置（用一个特殊颜色的点标识）
      await this.mapController.addMarker({
        position: { latitude: this.currentLatitude, longitude: this.currentLongitude },
        title: '我的位置',
        clickable: false
      });

      // 3. 遍历刚才筛选出来的餐厅，挨个插大头针
      for (let item of this.nearbyRestaurants) {
        await this.mapController.addMarker({
          position: { latitude: item.latitude, longitude: item.longitude },
          title: item.name,
          snippet: `${item.category} | 评分: ${item.rating.toFixed(1)} | 距离: ${item.distance.toFixed(1)}km`,
          clickable: true
        });
      }
      console.info("Map", "地图大头针刷新完毕！");
    } catch (error) {
      console.error("Map", `刷新大头针失败: ${JSON.stringify(error)}`);
    }
  }

  calcDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371;
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
  }

  build() {
    Column() {
      // ✅ 新增：上半部分展示地图（占屏幕 40% 左右的高度）
      MapComponent({
        mapOptions: this.mapOptions,
        mapCallback: this.mapCallback
      })
        .width('100%')
        .height('40%') // 地图占一半多一点，体验最好

      // 状态与筛选区
      Column() {
        Row({ space: 8 }) {
          Text('评分筛选:')
            .fontSize(14)
            .fontColor('#333')

          TextInput({ placeholder: '最低' })
            .type(InputType.NUMBER_DECIMAL)
            .width(60)
            .height(32)
            .fontSize(13)
            .onChange((value: string) => this.minRatingStr = value)

          Text('-').fontSize(14)

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

          Text(this.locationDesc)
            .fontSize(10)
            .fontColor('#999')
            .maxLines(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(Color.White)
        .shadow({ radius: 2, color: '#10000000', offsetY: 2 })
      }.width('100%').zIndex(2) // 让阴影盖住下方的列表

      // 下半部分展示列表
      if (this.isLocating) {
        LoadingProgress().width(50).height(50).margin({ top: 40 });
      } else if (this.nearbyRestaurants.length === 0) {
        Text('该评分区间暂无餐厅').margin({ top: 40 }).fontColor('#999');
      } else {
        List({ space: 12 }) {
          ForEach(this.nearbyRestaurants, (item: RestaurantInfo) => {
            ListItem() {
              this.restaurantItem(item)
            }
            .onClick(() => {
              router.pushUrl({
                url: 'pages/StoreDetailView',
                params: { restaurantId: item.id }
              });
            })
          })
        }
        .width('100%')
        .layoutWeight(1) // 填满屏幕剩下的高度
        .padding(12)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8f8f8')
  }

  @Builder
  restaurantItem(item: RestaurantInfo) {
    Row() {
      Image($r('app.media.' + item.coverUrl))
        .width(80)
        .height(80)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
        .margin({ right: 12 })
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