import router from '@ohos.router';

@Component
export struct BottomNavBar {
  @Prop currentTab: number = 0;

  build() {
    Row() {
      this.TabItem('微信', 'pages/ChatListPage', 0)
      this.TabItem('通讯录', 'pages/ContactsPage', 1)
      this.TabItem('发现', 'pages/DiscoverPage', 2)
      this.TabItem('我', 'pages/MePage', 3)
    }
    .width('100%')
    .height(56)
    .backgroundColor('#F7F7F7')
    .border({ width: { top: 0.5 }, color: '#D9D9D9' })
  }

  @Builder
  TabItem(label: string, route: string, tabIndex: number) {
    Column() {
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === tabIndex ? '#07C160' : '#999999')
        .margin({ top: 6 })
      if (this.currentTab === tabIndex) {
        Divider()
          .width(20)
          .height(2)
          .color('#07C160')
          .margin({ top: 2 })
      }
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.currentTab !== tabIndex) {
        router.replaceUrl({ url: route });
      }
    })
  }
}
