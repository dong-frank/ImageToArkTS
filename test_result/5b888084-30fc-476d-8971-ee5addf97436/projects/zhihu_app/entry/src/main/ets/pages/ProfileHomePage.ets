import { router } from '@kit.ArkUI';
import { BottomNavBar } from '../common/components/BottomNavBar';
import { NavigationService } from '../common/services/NavigationService';

@Entry
@Component
struct ProfileHomePage {
  @State currentTab: string = '提问';
  @State activeGridItem: string = '';
  private bottomTabs: string[] = ['首页', '直答', '+', '消息', '我的'];
  private questionTabs: string[] = ['提问', '回答', '文章', '想法'];

  // Grid items: 5 columns x 2 rows
  private gridItems: GridItemData[] = [
    new GridItemData('\uE8B0', '我的直播', '付费咨询'),
    new GridItemData('\uE8C4', '好物推荐', '知乎商城'),
    new GridItemData('\uE8D2', '我的抽奖', '知乎商城'),
    new GridItemData('\uE8C3', '我的订单', '知乎商城'),
    new GridItemData('\uE8B9', '我的草稿', ''),
    new GridItemData('\uE8C1', '我的优惠券', '知乎商城'),
    new GridItemData('\uE8F0', '我的活动', '知乎商城'),
    new GridItemData('\uE8C6', '帮助反馈', '帮助与客服'),
    new GridItemData('\uE8BD', '设置', '设置'),
    new GridItemData('\uE8C0', '更多', '我的-功能列表'),
  ];

  build() {
    Column() {
      // Scrollable content area
      Scroll() {
        Column() {
          // ── Profile Header ──
          this.buildProfileHeader();

          // Divider
          Divider()
            .color('#F0F0F0')
            .width('100%')
            .margin({ top: 8, bottom: 8 });

          // ── Membership Banner ──
          this.buildMembershipBanner();

          // Divider
          Divider()
            .color('#F0F0F0')
            .width('100%')
            .margin({ top: 8, bottom: 8 });

          // ── 5×2 Function Grid ──
          this.buildFunctionGrid();

          // Divider
          Divider()
            .color('#F0F0F0')
            .width('100%')
            .margin({ top: 8, bottom: 8 });

          // ── Question Tabs ──
          this.buildQuestionTabs();

          // ── Content Area (placeholder) ──
          this.buildContentArea();
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // ── Bottom Navigation ──
      this.buildBottomNavigation();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // ─── Profile Header ───
  @Builder
  buildProfileHeader() {
    Column() {
      Row() {
        // Avatar
        Stack() {
          Circle()
            .width(64)
            .height(64)
            .fill('#E0E0E0')
          Text('\uE8B8')
            .fontSize(32)
            .fontColor('#999999')
        }
        .onClick(() => {
          console.info('[ProfileHomePage] 点击个人资料区 - 个人资料编辑页');
        })

        Column() {
          // Nickname row
          Row({ space: 6 }) {
            Text('小雨滴')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111111')
            // Verified badge
            Circle()
              .width(16)
              .height(16)
              .fill('#0088FF')
          }
          .margin({ bottom: 8 })

          // Stats row
          Row({ space: 16 }) {
            this.buildStatItem('关注', '123')
            this.buildStatItem('粉丝', '456')
            this.buildStatItem('已认证', '')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)

        // Chevron
        Text('\uE8DF')
          .fontSize(18)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildStatItem(label: string, value: string) {
    Row({ space: 4 }) {
      if (value !== '') {
        Text(value)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')
      }
      Text(label)
        .fontSize(12)
        .fontColor('#999999')
    }
  }

  // ─── Membership Banner ───
  @Builder
  buildMembershipBanner() {
    Row() {
      Row({ space: 8 }) {
        // Crown icon
        Text('\uE8F2')
          .fontSize(20)
          .fontColor('#FF9500')
        Column() {
          Text('开通盐选会员')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111111')
          Text('畅享 10w+ 优质内容 · 最低 0.3 元/天')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
      }

      Blank()

      Text('立即开通')
        .fontSize(13)
        .fontColor('#FFFFFF')
        .backgroundColor('#0088FF')
        .borderRadius(14)
        .padding({ left: 14, right: 14, top: 6, bottom: 6 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      console.info('[ProfileHomePage] 点击会员促销区 - 会员购买/升级页');
    })
  }

  // ─── 5×2 Function Grid ───
  @Builder
  buildFunctionGrid() {
    Column() {
      Grid() {
        ForEach(this.gridItems, (item: GridItemData, index: number) => {
          GridItem() {
            Column({ space: 6 }) {
              Text(item.icon)
                .fontSize(24)
                .fontColor('#333333')
              Text(item.label)
                .fontSize(11)
                .fontColor('#666666')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding({ top: 14, bottom: 14 })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.onGridItemClick(item);
            })
          }
          .backgroundColor('#FFFFFF')
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsGap(1)
      .columnsGap(1)
      .width('100%')
      .backgroundColor('#F0F0F0')
    }
    .width('100%')
  }

  private onGridItemClick(item: GridItemData): void {
    if (item.action === '') {
      console.info(`[ProfileHomePage] ${item.label} - 暂无目标页面`);
      return;
    }
    const route = NavigationService.routeFor(item.action);
    if (route && route !== 'pages/Index') {
      router.pushUrl({ url: route });
    } else {
      console.info(`[ProfileHomePage] ${item.label} - 路由未找到`);
    }
  }

  // ─── Question Tabs ───
  @Builder
  buildQuestionTabs() {
    Column() {
      Row() {
        // Tab bar
        Row({ space: 0 }) {
          ForEach(this.questionTabs, (tab: string) => {
            Column() {
              Text(tab)
                .fontSize(15)
                .fontWeight(this.currentTab === tab ? FontWeight.Bold : FontWeight.Regular)
                .fontColor(this.currentTab === tab ? '#111111' : '#666666')
                .padding({ left: 14, right: 14, top: 10, bottom: 8 })
              // Active indicator
              if (this.currentTab === tab) {
                Divider()
                  .width(20)
                  .height(3)
                  .color('#0088FF')
                  .borderRadius(1.5)
              }
            }
            .onClick(() => {
              this.currentTab = tab;
            })
          })
        }

        Blank()

        // Draft entry
        Row({ space: 4 }) {
          Text('\uE8B9')
            .fontSize(14)
            .fontColor('#666666')
          Text('草稿')
            .fontSize(13)
            .fontColor('#666666')
        }
        .onClick(() => {
          console.info('[ProfileHomePage] 草稿入口点击');
        })
      }
      .width('100%')
      .padding({ left: 8, right: 16 })
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
  }

  // ─── Content Area ───
  @Builder
  buildContentArea() {
    Column() {
      Column({ space: 16 }) {
        Text('📋')
          .fontSize(48)
          .opacity(0.3)
        Text(this.getContentPlaceholderText())
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .height(200)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .margin({ top: 1 })
  }

  private getContentPlaceholderText(): string {
    switch (this.currentTab) {
      case '回答':
        return '暂无回答内容';
      case '文章':
        return '暂无文章内容';
      case '想法':
        return '暂无想法内容';
      default:
        return '暂无提问内容';
    }
  }

  // ─── Bottom Navigation ───
  @Builder
  buildBottomNavigation() {
    Column() {
      Row() {
        ForEach(this.bottomTabs, (tab: string, index: number) => {
          Column({ space: 2 }) {
            if (tab === '+') {
              Text('+')
                .fontSize(28)
                .fontWeight(FontWeight.Lighter)
                .fontColor('#FFFFFF')
                .backgroundColor('#0088FF')
                .borderRadius(20)
                .width(40)
                .height(40)
                .textAlign(TextAlign.Center)
            } else {
              Text(this.getBottomTabIcon(index))
                .fontSize(20)
                .fontColor(tab === '我的' ? '#0088FF' : '#999999')
              Text(tab)
                .fontSize(10)
                .fontColor(tab === '我的' ? '#0088FF' : '#999999')
            }
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.onBottomTabClick(tab);
          })
        })
      }
      .width('100%')
      .height(56)
      .padding({ top: 4, bottom: 4 })
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 4, color: '#10000000', offsetY: -2 })
  }

  private getBottomTabIcon(index: number): string {
    const icons: string[] = ['\uE8B1', '\uE8D5', '', '\uE8C7', '\uE8DE'];
    return icons[index] || '';
  }

  private onBottomTabClick(tab: string): void {
    if (tab === '我的') {
      return; // Already on this page
    }
    let route: string = '';
    switch (tab) {
      case '首页':
        route = NavigationService.routeFor('首页信息流');
        break;
      case '直答':
        route = NavigationService.routeFor('直答/提问首页');
        break;
      case '+':
        route = NavigationService.routeFor('内容编辑器');
        break;
      case '消息':
        route = NavigationService.routeFor('消息列表');
        break;
    }
    if (route && route !== 'pages/Index') {
      router.replaceUrl({ url: route });
    }
  }
}

// ─── Data types ───
class GridItemData {
  icon: string = '';
  label: string = '';
  action: string = '';

  constructor(icon: string, label: string, action: string) {
    this.icon = icon;
    this.label = label;
    this.action = action;
  }
}
