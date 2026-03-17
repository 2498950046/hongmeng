import geoLocationManager from '@ohos.geoLocationManager';
import abilityAccessCtrl, { Permissions, PermissionRequestResult } from '@ohos.abilityAccessCtrl';
import router from '@ohos.router';

// 测试数据
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
  @State currentLatitude: number = 39.908;
  @State currentLongitude: number = 116.397;
  @State nearbyRestaurants: RestaurantInfo[] = [];
  @State isLocating: boolean = true;

  aboutToAppear() {
    // RdbManager.ets工具类编写后可取消注释，并删去53行
    // this.requestLocationPermission();
    this.loadMockNearby();
  }

  loadMockNearby() {
    let list: RestaurantInfo[] = MOCK_RESTAURANTS.map(item => {
      const distance = this.calcDistance(
        this.currentLatitude, this.currentLongitude,
        item.latitude, item.longitude
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
    this.isLocating = false;
  }

  async requestLocationPermission() {
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      const permissions: Permissions[] = [
        'ohos.permission.LOCATION',
        'ohos.permission.APPROXIMATELY_LOCATION'
      ];
      let grantStatus: PermissionRequestResult = await atManager.requestPermissionsFromUser(getContext(), permissions);
      if (grantStatus.authResults.some(res => res !== 0)) {
        console.error('定位权限被拒绝');
        this.loadMockNearby();
        return;
      }
      this.getCurrentLocation();
    } catch (err) {
      console.error('权限申请失败', JSON.stringify(err));
      this.loadMockNearby();
    }
  }

  async getCurrentLocation() {
    try {
      let location = await geoLocationManager.getCurrentLocation();
      this.currentLatitude = location.latitude;
      this.currentLongitude = location.longitude;
      this.loadMockNearby();
    } catch (err) {
      console.error('定位失败', JSON.stringify(err));
      this.loadMockNearby();
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
      Text('地图预览区域（测试）')
        .width('100%')
        .height(200)
        .backgroundColor('#f0f0f0')
        .textAlign(TextAlign.Center)
        .fontColor('#999')

      if (this.isLocating) {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ top: 20 });
      } else if (this.nearbyRestaurants.length === 0) {
        Text('附近暂无餐厅').margin({ top: 20 });
      } else {
        List({ space: 12 }) {
          ForEach(this.nearbyRestaurants, (item: RestaurantInfo) => {
            ListItem() {
              this.restaurantItem(item)
            }
            .onClick(() => {
              try {
                router.pushUrl({
                  url: 'pages/StoreDetailView',
                  params: { restaurantId: item.id }
                });
              }
              catch (err) {
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