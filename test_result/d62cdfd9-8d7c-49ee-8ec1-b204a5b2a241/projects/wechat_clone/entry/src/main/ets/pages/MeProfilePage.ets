import router from '@ohos.router';
import { NavigationService } from '../common/services/NavigationService';

interface MenuItemData {
  icon: string;
  label: string;
  trailingText: string;
  showRedDot: boolean;
  targetRoute: string;
}

@Entry
@Component
struct MeProfilePage {
  private bottomTabs: string[] = ['微信', '通讯录', '发现', '我'];

  @State menuItems: MenuItemData[] = [
    {
      icon: 'check_circle',
      label: '服务',
      trailingText: '',
      showRedDot: false,
      targetRoute: NavigationService.routeFor('服务（金融版）')
    },
    {
      icon: 'cube',
      label: '收藏',
      trailingText: '',
      showRedDot: false,
      targetRoute: ''
    },
    {
      icon: 'image',
      label: '朋友圈',
      trailingText: '',
      showRedDot: false,
      targetRoute: ''
    },
    {
      icon: 'document',
      label: '公众号',
      trailingText: '',
      showRedDot: false,
      targetRoute: ''
    },
    {
      icon: 'shop',
      label: '小店与卡包',
      trailingText: '[关注]本来食物恋的小店有上新',
      showRedDot: true,
      targetRoute: ''
    },
    {
      icon: 'smile',
      label: '表情',
      trailingText: '',
      showRedDot: false,
      targetRoute: ''
    },
    {
      icon: 'settings',
      label: '设置',
      trailingText: '',
      showRedDot: false,
      targetRoute: NavigationService.routeFor('设置')
    }
  ];

  onMenuItemTap(item: MenuItemData): void {
    if (item.targetRoute && item.targetRoute.length > 0) {
      router.pushUrl({ url: item.targetRoute });
    }
  }

  onTabTap(tabLabel: string): void {
    const pageNameMap: Record<string, string> = {
      '微信': '聊天列表',
      '通讯录': '通讯录',
      '发现': '发现',
      '我': '我'
    };
    const targetName = pageNameMap[tabLabel];
    if (targetName && targetName !== '我') {
      const route = NavigationService.routeFor(targetName);
      if (route) {
        router.replaceUrl({ url: route });
      }
    }
  }

  build() {
    Column() {
      // Scrollable content area
      Scroll() {
        Column() {
          // ── Profile Header ──
          Column() {
            // Top row: avatar + name + QR
            Row({ space: 16 }) {
              // Avatar placeholder (One Piece themed)
              Column() {
                Text('☠')
                  .fontSize(30)
              }
              .width(64)
              .height(64)
              .borderRadius(8)
              .backgroundColor('#DDE8F0')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)

              // Nickname and WeChat ID
              Column({ space: 6 }) {
                Text('猫馋喜之郎')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#191919')

                Text('微信号：wxid_')
                  .fontSize(13)
                  .fontColor('#999999')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              // QR code icon
              Text('📱')
                .fontSize(22)
                .fontColor('#666666')
                .onClick(() => {
                  // QR code action placeholder
                })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding({ left: 20, right: 20, top: 16, bottom: 10 })

            // Bottom row: +状态 and 3个朋友
            Row({ space: 16 }) {
              // + 状态 button
              Row({ space: 4 }) {
                Text('+ 状态')
                  .fontSize(13)
                  .fontColor('#576B95')
              }
              .padding({ left: 12, right: 12, top: 4, bottom: 4 })
              .border({ width: 1, color: '#576B95', style: BorderStyle.Solid })
              .borderRadius(4)
              .onClick(() => {
                // Status action placeholder
              })

              // 3个朋友 with red dot
              Row({ space: 6 }) {
                Text('3个朋友')
                  .fontSize(13)
                  .fontColor('#576B95')

                // Red dot indicator
                Circle({ width: 8, height: 8 })
                  .fill('#FA5151')
              }
              .onClick(() => {
                // Friend indicator action placeholder
              })

              Blank()
            }
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 14 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 8 })

          // ── Menu List Section ──
          Column() {
            ForEach(this.menuItems, (item: MenuItemData, index: number) => {
              Column() {
                Row({ space: 12 }) {
                  // Icon
                  Column() {
                    Text(this.getMenuIconText(item.icon))
                      .fontSize(18)
                      .fontColor('#FFFFFF')
                  }
                  .width(28)
                  .height(28)
                  .borderRadius(6)
                  .backgroundColor(this.getMenuIconBg(item.icon))
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)

                  // Label and optional trailing text
                  Column({ space: 3 }) {
                    Text(item.label)
                      .fontSize(16)
                      .fontColor('#191919')

                    if (item.trailingText && item.trailingText.length > 0) {
                      Text(item.trailingText)
                        .fontSize(12)
                        .fontColor('#999999')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  // Red dot + chevron
                  Row({ space: 8 }) {
                    if (item.showRedDot) {
                      Circle({ width: 8, height: 8 })
                        .fill('#FA5151')
                    }

                    Text('›')
                      .fontSize(20)
                      .fontColor('#C8C8C8')
                  }
                }
                .width('100%')
                .padding({ left: 20, right: 20, top: 14, bottom: 14 })
                .alignItems(VerticalAlign.Center)
                .onClick(() => {
                  this.onMenuItemTap(item);
                })

                // Separator
                if (index < this.menuItems.length - 1) {
                  Divider()
                    .strokeWidth(0.5)
                    .color('#F0F0F0')
                    .margin({ left: 60 })
                }
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // ── Bottom Navigation Bar ──
      Row() {
        ForEach(this.bottomTabs, (tab: string) => {
          Column({ space: 3 }) {
            Text(this.getTabIcon(tab))
              .fontSize(22)

            Text(tab)
              .fontSize(10)
              .fontColor(tab === '我' ? '#07C160' : '#999999')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 8, bottom: 10 })
          .onClick(() => {
            this.onTabTap(tab);
          })
        })
      }
      .width('100%')
      .backgroundColor('#F7F7F7')
      .padding({ bottom: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // ── Private helpers ──

  private getMenuIconText(iconType: string): string {
    const map: Record<string, string> = {
      'check_circle': '✓',
      'cube': '⬡',
      'image': '🖼',
      'document': '📄',
      'shop': '🛒',
      'smile': '☺',
      'settings': '⚙'
    };
    return map[iconType] || '•';
  }

  private getMenuIconBg(iconType: string): string {
    const map: Record<string, string> = {
      'check_circle': '#07C160',
      'cube': '#FF9800',
      'image': '#42A5F5',
      'document': '#5C6BC0',
      'shop': '#EF5350',
      'smile': '#FFCA28',
      'settings': '#78909C'
    };
    return map[iconType] || '#BDBDBD';
  }

  private getTabIcon(tab: string): string {
    const map: Record<string, string> = {
      '微信': '💬',
      '通讯录': '👥',
      '发现': '🔍',
      '我': '👤'
    };
    return map[tab] || '•';
  }
}
