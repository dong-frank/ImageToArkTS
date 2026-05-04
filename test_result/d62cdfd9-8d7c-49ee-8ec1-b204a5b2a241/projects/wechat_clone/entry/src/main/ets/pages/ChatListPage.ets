import { router } from '@kit.ArkUI';
import { NavigationService } from '../common/services/NavigationService';

// Conversation data model
interface ConversationItemData {
  title: string;
  subtitle: string;
  timestamp: string;
  avatarType: string;
  unread: boolean;
  badgeCount: number;
}

// Quick action menu item data
interface QuickActionItem {
  label: string;
  icon: string;
}

@Entry
@Component
struct ChatListPage {
  @State showQuickActionMenu: boolean = false;
  @State currentTab: string = '微信';

  private tabLabels: string[] = ['微信', '通讯录', '发现', '我'];

  private conversations: ConversationItemData[] = [
    {
      title: '文件传输助手',
      subtitle: '[图片]',
      timestamp: '15:07',
      avatarType: 'app_icon',
      unread: false,
      badgeCount: 0
    },
    {
      title: '班级小管家客服',
      subtitle: '@江苏南京一年级学生「免费」报名《AI...',
      timestamp: '星期日',
      avatarType: 'custom_icon',
      unread: false,
      badgeCount: 0
    },
    {
      title: '赵先生',
      subtitle: '不过可能不够，我到时候还得买',
      timestamp: '14:51',
      avatarType: 'contact_avatar',
      unread: false,
      badgeCount: 0
    },
    {
      title: '萨仁小姐衣橱 21群',
      subtitle: '"HYY ❤️"与群里其他人都不是朋友关...',
      timestamp: '14:32',
      avatarType: 'group_avatar',
      unread: false,
      badgeCount: 0
    },
    {
      title: '服务号',
      subtitle: '[招商银行信用...等8条通知] 江苏省农学会: 我...',
      timestamp: '14:31',
      avatarType: 'service_account_icon',
      unread: true,
      badgeCount: 1
    },
    {
      title: '饶东',
      subtitle: '嗯嗯',
      timestamp: '14:29',
      avatarType: 'contact_avatar',
      unread: false,
      badgeCount: 0
    },
    {
      title: '马尔斯轮滑俱乐部 仙林湖校区',
      subtitle: '十一: #接龙 周六课程提醒 今天上课小朋...',
      timestamp: '14:24',
      avatarType: 'group_avatar',
      unread: false,
      badgeCount: 0
    },
    {
      title: '公众号',
      subtitle: '[7条]八月熏风: 人是铁，雪糕是钢',
      timestamp: '14:17',
      avatarType: 'official_account_icon',
      unread: true,
      badgeCount: 1
    }
  ];

  private quickActions: QuickActionItem[] = [
    { label: '发起群聊', icon: '👥' },
    { label: '添加朋友', icon: '👤' },
    { label: '扫一扫', icon: '📷' },
    { label: '收付款', icon: '💰' }
  ];

  // Avatar background colors by type
  private getAvatarColor(avatarType: string): string {
    switch (avatarType) {
      case 'app_icon':
        return '#07C160';
      case 'custom_icon':
        return '#576B95';
      case 'contact_avatar':
        return '#1485EE';
      case 'group_avatar':
        return '#576B95';
      case 'service_account_icon':
        return '#F97316';
      case 'official_account_icon':
        return '#576B95';
      default:
        return '#CCCCCC';
    }
  }

  private getAvatarInitial(title: string): string {
    if (title.length === 0) {
      return '';
    }
    return title.charAt(0);
  }

  // Tab switch handler using NavigationService + router
  private onTabSwitch(tabLabel: string): void {
    if (tabLabel === this.currentTab) {
      return;
    }
    const targetRoute: string = NavigationService.routeFor(tabLabel);
    if (targetRoute && targetRoute !== 'pages/Index') {
      router.replaceUrl({ url: targetRoute });
    }
  }

  // Conversation tap handler
  private onConversationTap(item: ConversationItemData): void {
    // Navigate to chat detail (target page not in current 22-page scope)
    // Reserved navigation placeholder
    console.info('Navigate to chat detail: ' + item.title);
  }

  // Search tap handler
  private onSearchTap(): void {
    // Search mode activation - reserved for future implementation
    console.info('Search activated');
  }

  // Status banner tap handler
  private onStatusBannerTap(): void {
    // Possible device settings navigation - low confidence
    console.info('Status banner tapped');
  }

  // Quick action menu item tap handler
  private onQuickActionTap(action: QuickActionItem): void {
    this.showQuickActionMenu = false;
    console.info('Quick action: ' + action.label);
  }

  // Toggle quick action menu
  private toggleQuickActionMenu(): void {
    this.showQuickActionMenu = !this.showQuickActionMenu;
  }

  // Dismiss quick action menu
  private dismissQuickActionMenu(): void {
    this.showQuickActionMenu = false;
  }

  build() {
    Stack() {
      Column() {
        // ========== AppBar ==========
        Row() {
          // Spacer for left balance
          Row()
            .width(32)
            .height(32)

          Text('微信')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111111')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Text('+')
            .fontSize(24)
            .fontColor('#111111')
            .fontWeight(FontWeight.Medium)
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.toggleQuickActionMenu();
            })
        }
        .width('100%')
        .height(44)
        .padding({ left: 16, right: 12 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#EDEDED')

        // ========== SearchBar ==========
        Row() {
          Text('🔍')
            .fontSize(14)
            .margin({ right: 6 })

          Text('搜索')
            .fontSize(14)
            .fontColor('#999999')
        }
        .width('100%')
        .height(32)
        .backgroundColor('#EDEDED')
        .borderRadius(6)
        .padding({ left: 12, right: 12 })
        .alignItems(VerticalAlign.Center)
        .margin({ left: 12, right: 12, top: 8, bottom: 4 })
        .onClick(() => {
          this.onSearchTap();
        })

        // ========== StatusBanner ==========
        Row() {
          Text('🖥')
            .fontSize(14)
            .margin({ right: 6 })

          Text('Windows 微信已登录，手机通知已关闭')
            .fontSize(12)
            .fontColor('#666666')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .height(36)
        .backgroundColor('#EDEDED')
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.onStatusBannerTap();
        })

        // ========== ConversationList ==========
        Scroll() {
          Column() {
            ForEach(this.conversations, (item: ConversationItemData, index: number) => {
              this.buildConversationItem(item)
            })
          }
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor('#FFFFFF')

        // ========== BottomTabBar ==========
        Row() {
          ForEach(this.tabLabels, (tab: string) => {
            Column() {
              Text(tab)
                .fontSize(14)
                .fontWeight(this.currentTab === tab ? FontWeight.Bold : FontWeight.Regular)
                .fontColor(this.currentTab === tab ? '#07C160' : '#888888')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 8, bottom: 8 })
            .onClick(() => {
              this.onTabSwitch(tab);
            })
          })
        }
        .width('100%')
        .padding({ top: 4, bottom: 4 })
        .backgroundColor('#F7F7F7')
        .justifyContent(FlexAlign.SpaceAround)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // ========== QuickActionMenu overlay ==========
      if (this.showQuickActionMenu) {
        Column() {
          // Quick action menu popup - positioned near top-right
          Row() {
            Column() {
              ForEach(this.quickActions, (action: QuickActionItem, index: number) => {
                Row() {
                  Text(action.icon)
                    .fontSize(16)
                    .margin({ right: 10 })

                  Text(action.label)
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                }
                .width('100%')
                .padding({ left: 14, right: 14, top: 12, bottom: 12 })
                .onClick(() => {
                  this.onQuickActionTap(action);
                })

                if (index < this.quickActions.length - 1) {
                  Divider()
                    .strokeWidth(0.5)
                    .color('rgba(255, 255, 255, 0.15)')
                    .margin({ left: 14, right: 14 })
                }
              })
            }
            .width(140)
            .backgroundColor('#4C4C4C')
            .borderRadius(8)
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          .padding({ right: 16 })
          .margin({ top: 52 })

          // Spacer fills the rest with backdrop
          Column()
            .width('100%')
            .layoutWeight(1)
            .onClick(() => {
              this.dismissQuickActionMenu();
            })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.15)')
        .onClick(() => {
          this.dismissQuickActionMenu();
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildConversationItem(item: ConversationItemData) {
    Row() {
      // Avatar area
      Stack() {
        Column() {
          Text(this.getAvatarInitial(item.title))
            .fontSize(18)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
        }
        .width(48)
        .height(48)
        .borderRadius(6)
        .backgroundColor(this.getAvatarColor(item.avatarType))
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // Unread badge
        if (item.unread) {
          Text(item.badgeCount.toString())
            .fontSize(10)
            .fontColor('#FFFFFF')
            .width(16)
            .height(16)
            .borderRadius(8)
            .backgroundColor('#FF3B30')
            .textAlign(TextAlign.Center)
            .position({ x: 36, y: -6 })
        }
      }
      .width(48)
      .height(48)

      // Content area
      Column() {
        Row() {
          Text(item.title)
            .fontSize(16)
            .fontColor('#111111')
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(item.timestamp)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: 8 })
        }
        .width('100%')

        Text(item.subtitle)
          .fontSize(13)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 3 })
          .width('100%')
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      this.onConversationTap(item);
    })

    // Divider
    Divider()
      .strokeWidth(0.5)
      .color('#F0F0F0')
      .margin({ left: 76 })
  }
}
