import router from '@ohos.router';

@Component
export struct BottomNavBar {
  @Link currentTab: number;

  build() {
    Row() {
      this.TabItem(0, '首页', '🏠', 'pages/HomePage')
      this.TabItem(1, '地图', '🗺️', 'pages/MapPage')
      this.TabItem(2, '消息', '💬', 'pages/MessagePage')
      this.TabItem(3, '我的', '👤', 'pages/ProfilePage')
    }
    .width('100%')
    .height(56)
    .backgroundColor('#FFFFFF')
    .padding({ bottom: 4 })
  }

  @Builder
  TabItem(index: number, label: string, icon: string, route: string) {
    Column() {
      Text(icon)
        .fontSize(22)
        .opacity(this.currentTab === index ? 1.0 : 0.5)
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === index ? '#FF6600' : '#999999')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.currentTab !== index) {
        this.currentTab = index;
        router.replaceUrl({ url: route });
      }
    })
  }
}
