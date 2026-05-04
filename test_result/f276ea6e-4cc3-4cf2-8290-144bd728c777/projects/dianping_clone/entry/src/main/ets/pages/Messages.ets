import router from '@ohos.router';
import { BottomNavBar } from '../common/components/BottomNavBar';

interface QuickAction {
  icon: string;
  label: string;
  color: string;
}

interface MessageItem {
  icon: string;
  title: string;
  subtitle: string;
  timestamp: string;
  badge: string;
  isRead: boolean;
}

interface MessageSection {
  headerText: string;
  headerTimestamp: string;
  items: MessageItem[];
}

@Entry
@Component
struct Messages {
  @State showBanner: boolean = true;
  @State activeQuickAction: string = '';

  private quickActions: QuickAction[] = [
    { icon: '👍', label: '赞/收藏/有帮助', color: '#FF6B35' },
    { icon: '💬', label: '评论和@', color: '#FF8DA1' },
    { icon: '👤', label: '新增粉丝', color: '#5B9DFF' }
  ];

  private activitySection: MessageSection = {
    headerText: '活动消息',
    headerTimestamp: '14:53',
    items: [
      {
        icon: '🚩',
        title: '您的春日限定礼包（露营椅/野餐垫/青团花茶/现金...',
        subtitle: '点击查看详情',
        timestamp: '14:53',
        badge: '',
        isRead: true
      }
    ]
  };

  private systemSection: MessageSection = {
    headerText: '系统消息',
    headerTimestamp: '03/15',
    items: [
      {
        icon: '🔔',
        title: '恭喜获得打卡好礼——2元无门槛美团打车红包...',
        subtitle: '点击查看详情',
        timestamp: '03/15',
        badge: '1',
        isRead: false
      }
    ]
  };

  handleOverlayTrigger() {
    console.info('Messages: overlay trigger from BottomNavBar + button');
  }

  handleQuickActionTap(label: string) {
    this.activeQuickAction = (this.activeQuickAction === label) ? '' : label;
    console.info('Messages: quick action filter - ' + label);
  }

  handleMessageTap(section: MessageSection, item: MessageItem) {
    if (section.headerText === '活动消息') {
      router.pushUrl({ url: 'pages/ActivityMessages' });
    } else {
      console.info('Messages: message detail not yet available for - ' + item.title);
    }
  }

  handleAddFriendTap() {
    console.info('Messages: add friend page not yet available');
  }

  handleBannerAction() {
    console.info('Messages: notification settings page not yet available');
  }

  handleDismissBanner() {
    this.showBanner = false;
  }

  build() {
    Column() {
      // Title Bar
      Row() {
        Text('消息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Text('👥')
          .fontSize(22)
          .onClick(() => {
            this.handleAddFriendTap();
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Banner Alert
      if (this.showBanner) {
        Row() {
          Text('开启系统通知，订单聊天等信息不错过 ')
            .fontSize(13)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Text('去开启>')
            .fontSize(13)
            .fontColor('#FF6600')
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.handleBannerAction();
            })

          Text('×')
            .fontSize(18)
            .fontColor('#999999')
            .margin({ left: 8 })
            .onClick(() => {
              this.handleDismissBanner();
            })
        }
        .width('100%')
        .height(40)
        .padding({ left: 16, right: 12 })
        .backgroundColor('#FFF8E1')
      }

      // Quick Action Row
      Row() {
        ForEach(this.quickActions, (action: QuickAction, index: number) => {
          Column({ space: 6 }) {
            Text(action.icon)
              .fontSize(28)

            Text(action.label)
              .fontSize(12)
              .fontColor(this.activeQuickAction === action.label ? '#FF6600' : '#666666')
              .fontWeight(this.activeQuickAction === action.label ? FontWeight.Medium : FontWeight.Regular)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.handleQuickActionTap(action.label);
          })
        })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .padding({ left: 8, right: 8 })

      // Divider
      Divider()
        .height(8)
        .color('#F5F5F5')

      // Scrollable Message List
      Scroll() {
        Column() {
          // Activity Messages Section
          Column() {
            // Section Header
            Row() {
              Text(this.activitySection.headerText)
                .fontSize(14)
                .fontColor('#999999')

              Blank()

              Text(this.activitySection.headerTimestamp)
                .fontSize(12)
                .fontColor('#BBBBBB')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 8 })

            // Message Item
            Row() {
              Text(this.activitySection.items[0].icon)
                .fontSize(36)
                .margin({ right: 12 })

              Column({ space: 4 }) {
                Text(this.activitySection.items[0].title)
                  .fontSize(15)
                  .fontColor('#333333')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(this.activitySection.items[0].subtitle)
                  .fontSize(12)
                  .fontColor('#999999')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Image($r('sys.media.ohos_ic_public_arrow_right'))
                .width(16)
                .height(16)
                .fillColor('#CCCCCC')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            .backgroundColor('#FFFFFF')
            .onClick(() => {
              this.handleMessageTap(this.activitySection, this.activitySection.items[0]);
            })
          }
          .width('100%')

          // Archive Header
          Row() {
            Text('2周前和长期未读消息')
              .fontSize(13)
              .fontColor('#BBBBBB')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 8 })

          // System Messages Section
          Column() {
            // Section Header
            Row() {
              Text(this.systemSection.headerText)
                .fontSize(14)
                .fontColor('#999999')

              Blank()

              Text(this.systemSection.headerTimestamp)
                .fontSize(12)
                .fontColor('#BBBBBB')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })

            // Message Item
            Row() {
              Stack() {
                Text(this.systemSection.items[0].icon)
                  .fontSize(36)

                if (this.systemSection.items[0].badge !== '') {
                  Text(this.systemSection.items[0].badge)
                    .fontSize(10)
                    .fontColor('#FFFFFF')
                    .backgroundColor('#FF4444')
                    .borderRadius(8)
                    .width(16)
                    .height(16)
                    .textAlign(TextAlign.Center)
                    .position({ x: 24, y: -4 })
                }
              }
              .margin({ right: 12 })

              Column({ space: 4 }) {
                Text(this.systemSection.items[0].title)
                  .fontSize(15)
                  .fontColor('#333333')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(this.systemSection.items[0].subtitle)
                  .fontSize(12)
                  .fontColor('#999999')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Image($r('sys.media.ohos_ic_public_arrow_right'))
                .width(16)
                .height(16)
                .fillColor('#CCCCCC')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            .backgroundColor('#FFFFFF')
            .onClick(() => {
              this.handleMessageTap(this.systemSection, this.systemSection.items[0]);
            })
          }
          .width('100%')
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')

      // Bottom Navigation Bar
      BottomNavBar({
        activeTab: '消息',
        onOverlayTrigger: () => {
          this.handleOverlayTrigger();
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
