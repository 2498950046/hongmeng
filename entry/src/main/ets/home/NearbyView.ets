// NearbyView.ets
import geoLocationManager from '@ohos.geoLocationManager';
import abilityAccessCtrl, { Permissions, PermissionRequestResult } from '@ohos.abilityAccessCtrl';
import router from '@ohos.router';
import relationalStore from '@ohos.data.relationalStore';
import { RdbManager } from '../utils/RdbManager';

// 当数据库还没预置数据时，用于快速开发调试的本地假数据（显式标注类型）
const MOCK_RESTAURANTS: RestaurantInfo[] = [
  {
    id: 'r001',
    name: '老北京涮肉',
    category: '火锅',
    address: '北京市东城区王府井大街1号',
    latitude: 39.914,
    longitude: 116.399,
    rating: 4.5,
    coverUrl: '/images/rest1.jpg',
    distance: 0
  },
  {
    id: 'r002',
    name: '日式烧肉屋',
    category: '烧烤',
    address: '北京市朝阳区三里屯路2号',
    latitude: 39.935,
    longitude: 116.455,
    rating: 4.8,
    coverUrl: '/images/rest2.jpg',
    distance: 0
  },
  {
    id: 'r003',
    name: '川味小馆',
    category: '川菜',
    address: '北京市海淀区中关村大街3号',
    latitude: 39.983,
    longitude: 116.313,
    rating: 4.2,
    coverUrl: '/images/rest3.jpg',
    distance: 0
  }
];

@Component
export struct NearbyView {
  @State currentLatitude: number = 39.908;   // 默认天安门附近，拿不到定位时的兜底
  @State currentLongitude: number = 116.397;
  @State nearbyRestaurants: RestaurantInfo[] = [];
  @State isLocating: boolean = true;
  @State locationDesc: string = '正在定位中...';

  aboutToAppear() {
    // 正式接入 LocationKit 权限 & 获取当前位置，然后再查数据库并计算距离
    this.requestLocationPermission();
  }

  /**
   * 申请定位权限
   */
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
        // 权限拒绝时仍然从数据库加载附近数据，只是基于默认经纬度
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

  /**
   * 调用 geoLocationManager 获取当前位置
   */
  async getCurrentLocation() {
    try {
      let location = await geoLocationManager.getCurrentLocation();
      this.currentLatitude = location.latitude;
      this.currentLongitude = location.longitude;
      this.locationDesc = `当前经纬度：${this.currentLatitude.toFixed(4)}, ${this.currentLongitude.toFixed(4)}`;
      await this.loadNearbyFromDB();
    } catch (err) {
      console.error('定位失败', JSON.stringify(err));
      this.locationDesc = '定位失败，使用默认位置';
      await this.loadNearbyFromDB();
    }
  }

  /**
   * 从本地 SQLite 的 restaurants 表中读取数据，
   * 计算与当前经纬度的距离并按距离升序排序
   */
  async loadNearbyFromDB() {
    this.isLocating = true;
    let resultList: RestaurantInfo[] = [];
    try {
      const store = RdbManager.getStore();
      let predicates = new relationalStore.RdbPredicates('restaurants');
      // 可以根据需要加筛选条件，例如只查评分>3.5的店：
      // predicates.greaterThanOrEqualTo('rating', 3.5);

      // 查询所有字段，便于后续详情页展示
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
          this.currentLatitude,
          this.currentLongitude,
          latitude,
          longitude
        );

        resultList.push({
          id,
          name,
          category,
          address,
          latitude,
          longitude,
          rating,
          coverUrl,
          distance
        });
      }

      // 一定要关闭 ResultSet，避免内存泄漏
      resultSet.close();

      // 如果数据库里暂时还没有任何餐厅数据，就用 mock 数据兜底展示
      if (resultList.length === 0) {
        console.info('restaurants 表为空，使用本地 MOCK 数据');
        // 修改点：避免使用对象展开运算符，逐个属性赋值并断言类型
        resultList = MOCK_RESTAURANTS.map((item: RestaurantInfo) => {
          const distance = this.calcDistance(
            this.currentLatitude,
            this.currentLongitude,
            item.latitude,
            item.longitude
          );
          return {
            id: item.id,
            name: item.name,
            category: item.category,
            address: item.address,
            latitude: item.latitude,
            longitude: item.longitude,
            rating: item.rating,
            coverUrl: item.coverUrl,
            distance: distance
          } as RestaurantInfo;
        });
      }

      // 按距离从近到远排序
      resultList.sort((a, b) => a.distance - b.distance);
      this.nearbyRestaurants = resultList;
    } catch (err) {
      console.error('从数据库加载附近餐厅失败', JSON.stringify(err));
      // 查询失败时也可以退回到 MOCK 数据，保证 UI 有内容
      let list: RestaurantInfo[] = MOCK_RESTAURANTS.map((item: RestaurantInfo) => {
        const distance = this.calcDistance(
          this.currentLatitude,
          this.currentLongitude,
          item.latitude,
          item.longitude
        );
        return {
          id: item.id,
          name: item.name,
          category: item.category,
          address: item.address,
          latitude: item.latitude,
          longitude: item.longitude,
          rating: item.rating,
          coverUrl: item.coverUrl,
          distance: distance
        } as RestaurantInfo;
      });
      list.sort((a, b) => a.distance - b.distance);
      this.nearbyRestaurants = list;
    } finally {
      this.isLocating = false;
    }
  }

  /**
   * 计算两点经纬度之间的距离（km）
   */
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
      // 这里将来可以替换为真正的 Map Kit 组件，比如地图容器 + 用户当前位置 marker
      Text('地图预览区域（可接入 Map Kit）')
        .width('100%')
        .height(200)
        .backgroundColor('#f0f0f0')
        .textAlign(TextAlign.Center)
        .fontColor('#999')
        .fontSize(14);

      Text(this.locationDesc)
        .fontSize(12)
        .fontColor('#666')
        .padding({ top: 8, left: 12, right: 12 });

      if (this.isLocating) {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ top: 20 });
      } else if (this.nearbyRestaurants.length === 0) {
        Text('附近暂无餐厅')
          .margin({ top: 20 })
          .fontColor('#999');
      } else {
        List({ space: 12 }) {
          ForEach(this.nearbyRestaurants, (item: RestaurantInfo) => {
            ListItem() {
              this.restaurantItem(item)
            }
            .onClick(() => {
              // 跳转到店铺详情页，传入 restaurantId
              try {
                router.pushUrl({
                  url: 'pages/StoreDetailView',
                  params: { restaurantId: item.id }
                });
              } catch (err) {
                console.error('路由跳转失败', JSON.stringify(err));
              }
            })
          })
        }
        .width('100%')
        .height('100%')
        .layoutWeight(1)
        .padding(12)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8f8f8')
  }

  @Builder restaurantItem(item: RestaurantInfo) {
    Row() {
      Image(item.coverUrl)
        .width(80)
        .height(80)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
        .margin({ right: 12 })

      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .width('100%')
        Text(`${item.category} · ${item.distance.toFixed(1)}km`)
          .fontSize(14)
          .fontColor('#666')
          .width('100%')
        Row() {
          Text(`评分 ${item.rating.toFixed(1)}`)
            .fontSize(12)
            .fontColor('#ff8c00')
        }
        .width('100%')
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