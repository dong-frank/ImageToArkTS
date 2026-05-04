import router from '@ohos.router';

export interface TabItem {
  label: string;
  route: string;
  isOverlayTrigger: boolean;
}

@Component
export struct BottomNavBar {
  @Prop activeTab: string = '首页';
  @State tabs: TabItem[] = [
    { label: '首页', route: 'pages/HomeDiscovery', isOverlayTrigger: false },
    { label: '地图', route: 'pages/MapPoi', isOverlayTrigger: false },
    { label: '+', route: '', isOverlayTrigger: true },
    { label: '消息', route: 'pages/Messages', isOverlayTrigger: false },
    { label: '我的', route: 'pages/MyProfile', isOverlayTrigger: false }
  ];
  onOverlayTrigger?: () => void;

  handleTabClick(tab: TabItem) {
    if (tab.isOverlayTrigger) {
      if (this.onOverlayTrigger) {
        this.onOverlayTrigger();
      }
      return;
    }
    if (tab.label === this.activeTab) {
      return;
    }
    if (tab.route && tab.route !== '') {
      router.replaceUrl({ url: tab.route });
    }
  }

  build() {
    Row() {
      ForEach(this.tabs, (tab: TabItem, index: number) => {
        Column({ space: 2 }) {
          Text(tab.label)
            .fontSize(tab.isOverlayTrigger ? 28 : 12)
            .fontWeight(tab.isOverlayTrigger ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(this.activeTab === tab.label ? '#FF6600' : '#888888')
        }
        .width('20%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.handleTabClick(tab);
        })
      })
    }
    .width('100%')
    .height(56)
    .backgroundColor('#FFFFFF')
    .padding({ top: 4, bottom: 4 })
  }
}
