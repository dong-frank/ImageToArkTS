import router from '@ohos.router';
import { BottomNavBar } from '../components/BottomNavBar';

@Entry
@Component
struct ChatListPage {
  @State showOverlay: boolean = false;

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        // Title bar
        Row() {
          Text('微信')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#191919')
        }
        .width('100%')
        .height(44)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#EDEDED')

        // Search bar
        Row() {
          Text('🔍 搜索')
            .fontSize(14)
            .fontColor('#B2B2B2')
            .layoutWeight(1)
        }
        .width('90%')
        .height(36)
        .backgroundColor('#EDEDED')
        .borderRadius(6)
        .padding({ left: 12, right: 12 })
        .margin({ top: 4, bottom: 4 })
        .justifyContent(FlexAlign.Start)

        // System notice
        Row() {
          Column() {
            Text('💻')
              .fontSize(18)
          }
          .width(36)
          .height(36)
          .borderRadius(4)
          .backgroundColor('#4CAF50')
          .justifyContent(FlexAlign.Center)
          .margin({ right: 10 })
          Column() {
            Text('Windows 微信已登录，手机通知已关闭')
              .fontSize(14)
              .fontColor('#191919')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .backgroundColor('#FFFFFF')
        .border({ width: { bottom: 0.5 }, color: '#E5E5E5' })

        // Chat list
        List({ space: 0 }) {
          // File Transfer Helper
          ListItem() {
            this.ChatItemView(
              '📁',
              '文件传输助手',
              '[图片]',
              '',
              '#4CAF50',
              0
            )
          }

          // Contact: 班级小管家客服
          ListItem() {
            this.ChatItemView(
              '🎓',
              '班级小管家客服',
              '@江苏南京一年级学生「免费」报名《AI...',
              '',
              '#5B9EF5',
              0
            )
          }

          // Chat: 赵先生
          ListItem() {
            this.ChatItemView(
              '🐱',
              '赵先生',
              '不过可能不够，我到时候还得买',
              '14:51',
              '#FF9800',
              0
            )
          }

          // Group: 萨仁小姐衣橱 21群
          ListItem() {
            this.GroupChatItemView(
              '萨仁小姐衣橱 21群',
              '"HYY 💖"与群里其他人都不是朋友关...',
              '14:32',
              0
            )
          }

          // Service Account
          ListItem() {
            this.ChatItemView(
              '🔵',
              '服务号',
              '[招商银行信用...等8条通知] 江苏省农学会: 我...',
              '14:31',
              '#2196F3',
              1
            )
          }

          // Chat: 饶东
          ListItem() {
            this.ChatItemView(
              '🐶',
              '饶东',
              '嗯嗯',
              '14:29',
              '#795548',
              0
            )
          }

          // Group: 马尔斯轮滑俱乐部
          ListItem() {
            this.GroupChatItemView(
              '马尔斯轮滑俱乐部 仙林湖校区',
              '十一: #接龙 周六课程提醒 今天上课小朋...',
              '14:24',
              0
            )
          }

          // Official Account
          ListItem() {
            this.ChatItemView(
              '🌿',
              '公众号',
              '[7条]八月熏风: 人是铁，雪糕是钢',
              '14:17',
              '#4CAF50',
              1
            )
          }
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 70, endMargin: 16 })

        // Bottom nav
        BottomNavBar({ currentTab: 0 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EDEDED')

      // + button
      Row() {
        Text('+')
          .fontSize(24)
          .fontColor('#191919')
          .fontWeight(FontWeight.Bold)
      }
      .width(30)
      .height(30)
      .justifyContent(FlexAlign.Center)
      .position({ x: '85%', y: 3 })
      .onClick(() => {
        this.showOverlay = !this.showOverlay;
      })

      // Overlay menu
      if (this.showOverlay) {
        Column() {
          this.OverlayMenuItem('💬', '发起群聊')
          this.OverlayMenuItem('👤', '添加朋友')
          this.OverlayMenuItem('📷', '扫一扫')
          this.OverlayMenuItem('💳', '收付款')
        }
        .width(140)
        .backgroundColor('#4C4C4C')
        .borderRadius(8)
        .padding({ top: 4, bottom: 4 })
        .position({ x: 10, y: 35 })
        .onClick(() => {
          this.showOverlay = false;
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ChatItemView(icon: string, title: string, preview: string, time: string, bgColor: string, unread: number) {
    Row() {
      // Avatar
      Column() {
        Text(icon)
          .fontSize(18)
      }
      .width(44)
      .height(44)
      .borderRadius(6)
      .backgroundColor(bgColor)
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      // Content
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor('#191919')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(preview)
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // Time and badge
      Column({ space: 4 }) {
        Text(time)
          .fontSize(11)
          .fontColor('#B2B2B2')
        if (unread > 0) {
          Text(unread.toString())
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor('#F44837')
            .borderRadius(9)
            .width(18)
            .height(18)
            .textAlign(TextAlign.Center)
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  GroupChatItemView(title: string, preview: string, time: string, unread: number) {
    Row() {
      // Group avatar (2x2 grid using Column+Row)
      Column() {
        Row() {
          Text('👤').fontSize(8).width(22).height(22).textAlign(TextAlign.Center).backgroundColor('#FF9800')
          Text('👤').fontSize(8).width(22).height(22).textAlign(TextAlign.Center).backgroundColor('#4CAF50')
        }
        Row() {
          Text('👤').fontSize(8).width(22).height(22).textAlign(TextAlign.Center).backgroundColor('#2196F3')
          Text('👤').fontSize(8).width(22).height(22).textAlign(TextAlign.Center).backgroundColor('#9C27B0')
        }
      }
      .width(44)
      .height(44)
      .borderRadius(6)
      .margin({ right: 12 })

      Column() {
        Text(title)
          .fontSize(15)
          .fontColor('#191919')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(preview)
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: 4 }) {
        Text(time)
          .fontSize(11)
          .fontColor('#B2B2B2')
        if (unread > 0) {
          Text(unread.toString())
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor('#F44837')
            .borderRadius(9)
            .width(18)
            .height(18)
            .textAlign(TextAlign.Center)
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  OverlayMenuItem(icon: string, text: string) {
    Row() {
      Text(icon)
        .fontSize(16)
        .margin({ right: 12, left: 16 })
      Text(text)
        .fontSize(14)
        .fontColor('#FFFFFF')
    }
    .width('100%')
    .height(42)
    .padding({ left: 0, right: 16 })
  }
}
