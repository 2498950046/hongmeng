import geoLocationManager from '@ohos.geoLocationManager';
import abilityAccessCtrl, { Permissions, PermissionRequestResult } from '@ohos.abilityAccessCtrl';
import router from '@ohos.router';
import relationalStore from '@ohos.data.relationalStore';
import { RdbManager } from '../utils/RdbManager';

@Component
export struct NearbyView {
  // 拿不到定位时，定位默认在成都天府广场
  @State currentLatitude: number = 39.908;
  @State currentLongitude: number = 116.397;
  // 存放全量数据
  @State allRestaurants: RestaurantInfo[] = [];
  // 存放筛选排序后展示的数据
  @State nearbyRestaurants: RestaurantInfo[] = [];

  @State isLocating: boolean = true;
  @State locationDesc: string = '正在定位中...';

  // 筛选状态：用户输入的最低和最高评分
  @State minRatingStr: string = '';
  @State maxRatingStr: string = '';

  // @State filterMode: 'distance' | 'rating' | 'rating_high' = 'distance';

  aboutToAppear() {
    // 接入LocationKit权限并获取当前位置，然后再查数据库并计算距离
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

  // 调用 geoLocationManager 获取当前位置
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

  // 从本地SQLite的restaurants表中读取数据，计算与当前经纬度的距离并按距离升序排序
  async loadNearbyFromDB() {
    this.isLocating = true;
    let resultList: RestaurantInfo[] = [];
    try {
      const store = RdbManager.getStore();
      let predicates = new relationalStore.RdbPredicates('restaurants');

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

      // 关闭 ResultSet，避免内存泄漏
      resultSet.close();
      this.allRestaurants = resultList;
      // 应用默认排序
      this.applyFilter();
    } catch (err) {
      console.error('从数据库加载附近餐厅失败', JSON.stringify(err));
    } finally {
      this.isLocating = false;
    }
  }
  // 根据当前条件进行筛选和排序
  applyFilter() {
    let list = [...this.allRestaurants];

    // 解析用户输入，如果未输入或输入非法则赋予默认极值
    let min = parseFloat(this.minRatingStr);
    let max = parseFloat(this.maxRatingStr);

    if (isNaN(min)) min = 0;   // 默认最低 0 分
    if (isNaN(max)) max = 5.0; // 默认最高 5 分

    // 过滤在评分区间内的店铺
    list = list.filter(item => item.rating >= min && item.rating <= max);

    // 默认按距离升序展示
    list.sort((a, b) => a.distance - b.distance);

    this.nearbyRestaurants = list;
  }

  // 计算两点经纬度之间的距离（km）
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
      Text(this.locationDesc)
        .fontSize(12)
        .fontColor('#666')
        .padding({ top: 8, left: 12, right: 12, bottom: 8 })

      // 区间输入筛选栏
      Row({ space: 8 }) {
        Text('评分筛选:')
          .fontSize(14)
          .fontColor('#333')

        TextInput({
          placeholder: '最低'
        })
          .type(InputType.NUMBER_DECIMAL)
          .width(90)
          .height(36)
          .fontSize(13)
          .onChange((value: string) => {
            this.minRatingStr = value;
          })

        Text('-').fontSize(14)

        TextInput({
          placeholder: '最高'
        })
          .type(InputType.NUMBER_DECIMAL)
          .width(90)
          .height(36)
          .fontSize(13)
          .onChange((value: string) => {
            this.maxRatingStr = value;
          })

        Button('确定')
          .height(36)
          .fontSize(14)
          .onClick(() => {
            this.applyFilter();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      if (this.isLocating) {
        LoadingProgress().width(50).height(50).margin({ top: 20 });
      } else if (this.nearbyRestaurants.length === 0) {
        Text('该评分区间暂无餐厅').margin({ top: 20 }).fontColor('#999');
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
        .layoutWeight(1)
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