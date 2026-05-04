import router from '@ohos.router';

@Component
export struct BottomNavBar {
  @Prop currentTab: number = 0;

  build() {
    Row() {
      this.TabItem(0, '首页', '\u{1F3E0}')
      this.TabItem(1, '知乎', '\u{2753}')
      this.TabItem(2, '消息', '\u{1F514}')
      this.TabItem(3, '商城', '\u{1F6CD}')
      this.TabItem(4, '我的', '\u{1F464}')
    }
    .width('100%')
    .height(56)
    .backgroundColor('#FFFFFF')
    .padding({ top: 4, bottom: 4 })
  }

  @Builder
  TabItem(index: number, label: string, icon: string) {
    Column() {
      Text(icon)
        .fontSize(22)
        .fontColor(this.currentTab === index ? '#0066FF' : '#999999')
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === index ? '#0066FF' : '#999999')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (index !== this.currentTab) {
        if (index === 0) {
          router.replaceUrl({ url: 'pages/HomePage' });
        } else if (index === 1) {
          router.replaceUrl({ url: 'pages/AskHubPage' });
        } else if (index === 2) {
          router.replaceUrl({ url: 'pages/MessagesPage' });
        } else if (index === 3) {
          router.replaceUrl({ url: 'pages/MallPage' });
        } else if (index === 4) {
          router.replaceUrl({ url: 'pages/ProfilePage' });
        }
      }
    })
  }
}
