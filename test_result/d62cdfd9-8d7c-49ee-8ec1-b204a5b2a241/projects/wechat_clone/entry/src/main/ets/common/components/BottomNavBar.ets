import router from '@ohos.router';
import { NavigationService } from '../services/NavigationService';

@Component
export struct BottomNavBar {
  @Prop currentPage: string = '';
  @Prop tabs: string[] = [];

  // Map tab labels to icon characters
  private getTabIcon(tab: string): string {
    const iconMap: Record<string, string> = {
      '微信': '\uE001',
      '通讯录': '\uE002',
      '发现': '\uE003',
      '我': '\uE004'
    };
    return iconMap[tab] || '●';
  }

  private onTabClick(tab: string): void {
    if (tab === this.currentPage) {
      return;
    }
    const route: string = NavigationService.routeFor(tab);
    if (route && route !== 'pages/Index') {
      router.replaceUrl({ url: route });
    }
  }

  build() {
    Row({ space: 8 }) {
      ForEach(this.tabs, (tab: string) => {
        Column({ space: 2 }) {
          Text(this.getTabIcon(tab))
            .fontSize(22)
            .fontColor(this.currentPage === tab ? '#07C160' : '#888888')
          Text(tab)
            .fontSize(10)
            .fontColor(this.currentPage === tab ? '#07C160' : '#888888')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 8, bottom: 8 })
        .onClick(() => {
          this.onTabClick(tab);
        })
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
    .padding({ top: 4, bottom: 6 })
  }
}
