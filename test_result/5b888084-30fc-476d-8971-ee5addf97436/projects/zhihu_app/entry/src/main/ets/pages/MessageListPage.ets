import router from '@ohos.router';
import { NavigationService } from '../common/services/NavigationService';

class MessageItemData {
  icon: string;
  iconColor: string;
  iconBgColor: string;
  title: string;
  summary: string;
  badge: string;
  timestamp: string;

  constructor(icon: string, iconColor: string, iconBgColor: string, title: string, summary: string, badge: string, timestamp: string) {
    this.icon = icon;
    this.iconColor = iconColor;
    this.iconBgColor = iconBgColor;
    this.title = title;
    this.summary = summary;
    this.badge = badge;
    this.timestamp = timestamp;
  }
}

class BottomTabData {
  label: string;
  pageName: string;

  constructor(label: string, pageName: string) {
    this.label = label;
    this.pageName = pageName;
  }
}

@Entry
@Component
struct MessageListPage {
  @State bannerVisible: boolean = true;
  @State activeFilter: string = '评论转发@';

  private filterTabs: string[] = ['评论转发@', '赞同喜欢', '收藏了我', '关注订阅'];
  private bottomTabs: BottomTabData[] = [
    new BottomTabData('首页', '首页信息流'),
    new BottomTabData('直答', '直答/提问首页'),
    new BottomTabData('+', '内容编辑器'),
    new BottomTabData('消息', '消息列表'),
    new BottomTabData('我的', '个人中心')
  ];

  private messageItems: MessageItemData[] = [
    new MessageItemData('📄', '#FFFFFF', '#3B82F6', '邀请回答', '@吐你一脸洗... 等人邀请你回答问题', '6', ''),
    new MessageItemData('🔖', '#FFFFFF', '#8B5CF6', '订阅更新助手', '你订阅的「夏可叔叔讲美容」专栏有更新内...', '2', '昨天'),
    new MessageItemData('💡', '#FFFFFF', '#F97316', '知乎活动助手', '赢万元现金 | 特邀你用 AI，一起重塑知...', '1', '昨天'),
    new MessageItemData('📋', '#FFFFFF', '#3B82F6', '官方账号消息', '亲爱的 小雨滴：你也太幸运了！定向邀你免...', '•', '星期一'),
    new MessageItemData('👤', '#FFFFFF', '#8B5CF6', '创作者小助手', '领盐粒 🎁 | 参与活动 1 天即可瓜分百万盐...', '22', '04-10'),
    new MessageItemData('❓', '#FFFFFF', '#3B82F6', '关注的问题有了新回答', '提问/邀请/关注的问题有了新回答', '1', '04-09'),
    new MessageItemData('📘', '#FFFFFF', '#8B5CF6', '知乎专栏', '你订阅的「夏可叔叔讲美容」专栏有更新内容 ...', '', '2025-07-25')
  ];

  handleTabSwitch(targetPageName: string): void {
    if (targetPageName === '消息列表') {
      return;
    }
    const route: string = NavigationService.routeFor(targetPageName);
    if (route && route !== 'pages/Index') {
      router.replaceUrl({ url: route });
    }
  }

  closeBanner(): void {
    this.bannerVisible = false;
  }

  selectFilter(filter: string): void {
    this.activeFilter = filter;
  }

  build() {
    Column() {
      // TopBar
      Row() {
        Text('消息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')

        Blank()

        Row({ space: 16 }) {
          Text('📥')
            .fontSize(20)
          Text('😊')
            .fontSize(20)
        }
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')

      // NotificationBanner
      if (this.bannerVisible) {
        Row() {
          Row({ space: 8 }) {
            Text('🔔')
              .fontSize(16)
            Text('开启系统通知，及时收到互动推送')
              .fontSize(13)
              .fontColor('#666666')
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)

          Row({ space: 8 }) {
            Text('去开启')
              .fontSize(13)
              .fontColor('#1677FF')
              .onClick(() => {
                console.info('去开启系统通知设置');
              })

            Text('×')
              .fontSize(18)
              .fontColor('#999999')
              .padding({ left: 4, right: 4 })
              .onClick(() => {
                this.closeBanner();
              })
          }
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor('#F0F6FF')
        .alignItems(VerticalAlign.Center)
      }

      // FilterTabs
      Row({ space: 0 }) {
        ForEach(this.filterTabs, (filter: string) => {
          Column() {
            Text(filter)
              .fontSize(14)
              .fontWeight(this.activeFilter === filter ? FontWeight.Medium : FontWeight.Regular)
              .fontColor(this.activeFilter === filter ? '#1677FF' : '#666666')
              .padding({ left: 12, right: 12, top: 10, bottom: 8 })
          }
          .border({
            width: { bottom: this.activeFilter === filter ? 2 : 0 },
            color: this.activeFilter === filter ? '#1677FF' : 'transparent'
          })
          .onClick(() => {
            this.selectFilter(filter);
          })
        })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .padding({ left: 4, right: 4 })
      .justifyContent(FlexAlign.Start)

      // MessageList (scrollable)
      Scroll() {
        Column() {
          ForEach(this.messageItems, (item: MessageItemData, index: number) => {
            Column() {
              Row() {
                // Icon
                Stack() {
                  Text(item.icon)
                    .fontSize(18)
                }
                .width(40)
                .height(40)
                .borderRadius(8)
                .backgroundColor(item.iconBgColor)
                .alignContent(Alignment.Center)

                // Content area
                Column() {
                  Row() {
                    Text(item.title)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#111111')
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    if (item.badge !== '') {
                      Text(item.badge)
                        .fontSize(12)
                        .fontColor('#FFFFFF')
                        .backgroundColor('#FF4444')
                        .borderRadius(10)
                        .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                        .constraintSize({ minWidth: 18 })
                        .textAlign(TextAlign.Center)
                    }
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)

                  Row() {
                    Text(item.summary)
                      .fontSize(13)
                      .fontColor('#999999')
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    if (item.timestamp !== '') {
                      Text(item.timestamp)
                        .fontSize(12)
                        .fontColor('#BBBBBB')
                        .margin({ left: 8 })
                    }
                  }
                  .width('100%')
                  .margin({ top: 4 })
                }
                .layoutWeight(1)
                .margin({ left: 12 })
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .alignItems(VerticalAlign.Top)

              // Divider
              if (index < this.messageItems.length - 1) {
                Divider()
                  .color('#F0F0F0')
                  .width('100%')
                  .margin({ left: 68, right: 16 })
              }
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .onClick(() => {
              console.info('点击消息卡片: ' + item.title);
            })
          })

          // Bottom spacer
          Text('没有更多了')
            .fontSize(12)
            .fontColor('#CCCCCC')
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 20, bottom: 20 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .scrollBar(BarState.Off)

      // BottomNavigationBar
      Row({ space: 0 }) {
        ForEach(this.bottomTabs, (tab: BottomTabData) => {
          Column() {
            Text(tab.label)
              .fontSize(13)
              .fontWeight(tab.label === '消息' ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(tab.label === '消息' ? '#111111' : '#999999')
              .height(24)
              .textAlign(TextAlign.Center)

            if (tab.label === '消息') {
              Text('32')
                .fontSize(10)
                .fontColor('#FFFFFF')
                .backgroundColor('#FF4444')
                .borderRadius(8)
                .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                .margin({ top: 2 })
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .padding({ top: 8, bottom: 8 })
          .onClick(() => {
            this.handleTabSwitch(tab.pageName);
          })
        })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .padding({ bottom: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
