@Component
export struct swiperComponent {
  // 替换为4张充满中国人文气息与市井烟火气的高清美食图片
  private bannerImages: string[] = [
    // 1. 晨光与热气交织的早茶/点心（竹蒸笼里热气腾腾的小笼包/饺子，充满清晨烟火气）
    'https://images.unsplash.com/photo-1563245372-f21724e3856d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',

    // 2. 中式家庭/朋友聚餐（一桌丰盛的中餐，红油亮色，大家用筷子夹菜，极具人情味）
    'https://images.unsplash.com/photo-1552611052-33e04de081de?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',

    // 3. 传统面食文化（一碗劲道浓郁的汤面与筷子，最治愈的东方碳水）
    'https://images.unsplash.com/photo-1585032226651-759b368d7246?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',

    // 4. 夜市大排档或热辣炒菜（充满镬气的中式香辣菜肴，适合深夜放毒）
    'https://images.pexels.com/photos/2284604/pexels-photo-2284604.jpeg?auto=compress&cs=tinysrgb&w=800'
  ];

  build() {
    Swiper() {
      // 遍历渲染这4张中国风味图片
      ForEach(this.bannerImages, (imgUrl: string) => {
        Image(imgUrl)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover) // 保持横屏铺满裁剪不变形
          .borderRadius(12) // 加圆角，与外部卡片风格统一
      }, (item: string) => item)
    }
    .width('100%')
    .height('25%')
    .autoPlay(true) // 自动轮播
    .interval(3500) // 停留3.5秒，给用户留足“看饿”的时间
    .loop(true)
    .indicator(
      Indicator.dot()
        .selectedColor('#FF5E00') // 觅食记主题活力橙
        .color('rgba(255, 255, 255, 0.6)') // 半透明白
    )
    .padding({ left: 10, right: 10 })
  }
}