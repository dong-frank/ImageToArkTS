import router from '@ohos.router';
import { BottomNavBar } from '../components/BottomNavBar';

@Entry
@Component
struct MessagesPage {
  @State messageFilter: number = 0;
  filterTabs: string[] = ['全部', '私信', '评论', '赞同', '关注'];

  build() {
    Column() {
      // Status bar
      Row() {
        Text('15:17')
          .fontSize(12)
          .fontColor('#333333')
        Blank()
        Text('56%')
          .fontSize(12)
          .fontColor('#333333')
      }
      .width('100%')
      .height(28)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F5F5F5')

      // Header
      Row() {
        Text('消息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Blank()
        Text('\u{1F4AC}')
          .fontSize(20)
          .margin({ right: 12 })
        Text('\u{2699}')
          .fontSize(20)
          .onClick(() => {
            router.pushUrl({ url: 'pages/MessageSettingsPage' });
          })
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Filter tabs
      Scroll() {
        Row() {
          ForEach(this.filterTabs, (tab: string, index: number) => {
            Text(tab)
              .fontSize(14)
              .fontColor(this.messageFilter === index ? '#0066FF' : '#666666')
              .fontWeight(this.messageFilter === index ? FontWeight.Bold : FontWeight.Normal)
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .onClick(() => {
                this.messageFilter = index;
              })
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(40)
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })

      if (this.messageFilter === 0) {
        this.AllMessagesContent()
      } else if (this.messageFilter === 1) {
        this.PrivateMessagesContent()
      } else if (this.messageFilter === 2) {
        this.CommentsContent()
      } else if (this.messageFilter === 3) {
        this.UpvotesContent()
      } else {
        this.FollowsContent()
      }

      BottomNavBar({ currentTab: 2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  AllMessagesContent() {
    Scroll() {
      Column() {
        // Unread section
        Row() {
          Text('未读消息')
            .fontSize(14)
            .fontColor('#333333')
            .fontWeight(FontWeight.Bold)
          Blank()
          Text('全部已读')
            .fontSize(12)
            .fontColor('#0066FF')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        this.MessageItem(
          '\u{1F44D}',
          '赞同与喜欢',
          '知乎小管家赞了你的回答',
          '2分钟前',
          true
        )
        this.MessageItem(
          '\u{1F4AC}',
          '评论和回复',
          '有 3 条新评论',
          '5分钟前',
          true
        )
        this.MessageItem(
          '\u{1F465}',
          '新增关注',
          '李教授、张工 等 5 人关注了你',
          '18分钟前',
          true
        )

        // Earlier messages
        Row() {
          Text('更早的消息')
            .fontSize(14)
            .fontColor('#333333')
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 8 })

        this.MessageItem(
          '\u{1F4E2}',
          '系统通知',
          '知乎 2025 年度活动开始啦！',
          '2小时前',
          false
        )
        this.MessageItem(
          '\u{2B50}',
          '收藏通知',
          '你的回答被加入 3 个收藏夹',
          '昨天',
          false
        )
        this.MessageItem(
          '\u{1F48C}',
          '私信',
          '小王：关于那个技术问题...',
          '昨天',
          false
        )
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  @Builder
  PrivateMessagesContent() {
    Scroll() {
      Column() {
        this.ChatItem('小王', '关于那个技术问题，我还有些疑问...', '昨天 18:30', true)
        this.ChatItem('李教授', '你的论文我看了，很有想法', '昨天 14:20', false)
        this.ChatItem('张工', '下周的项目会议你参加吗？', '前天', false)
        this.ChatItem('知乎小助手', '欢迎使用知乎私信功能', '3天前', false)
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  @Builder
  CommentsContent() {
    Scroll() {
      Column() {
        this.NotificationItem('CommentMan', '评论了你的回答：「很有道理，但是我觉得还有另一种思路...」', '5分钟前')
        this.NotificationItem('新用户123', '回复了你的评论：「确实如此，感谢分享」', '1小时前')
        this.NotificationItem('资深读者', '评论了你的文章：「写得很好，已收藏」', '3小时前')
        this.NotificationItem('路边社记者', '评论了你的想法：「这个观点很新颖」', '昨天')
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  @Builder
  UpvotesContent() {
    Scroll() {
      Column() {
        this.NotificationItem('知乎小管家', '赞同了你的回答', '2分钟前')
        this.NotificationItem('李教授', '赞同了你的文章', '30分钟前')
        this.NotificationItem('张工', '喜欢了你的评论', '1小时前')
        this.NotificationItem('小王', '赞同了你的回答', '昨天')
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  @Builder
  FollowsContent() {
    Scroll() {
      Column() {
        this.FollowItem('李教授', '计算机科学博士，大学教授', '18分钟前')
        this.FollowItem('张工', '高级工程师，科技爱好者', '25分钟前')
        this.FollowItem('码农小陈', '热爱编程的年轻人', '1小时前')
        this.FollowItem('设计达人', 'UI/UX 设计师', '昨天')
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  @Builder
  MessageItem(icon: string, title: string, desc: string, time: string, isUnread: boolean) {
    Row() {
      Text(icon)
        .fontSize(28)
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(isUnread ? '#E8F0FE' : '#F5F5F5')
        .textAlign(TextAlign.Center)
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor('#333333')
          .fontWeight(isUnread ? FontWeight.Bold : FontWeight.Normal)
        Text(desc)
          .fontSize(13)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 3 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
      Column() {
        Text(time)
          .fontSize(11)
          .fontColor('#CCCCCC')
        if (isUnread) {
          Text('●')
            .fontSize(8)
            .fontColor('#FF4500')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#F5F5F5' })
  }

  @Builder
  ChatItem(name: string, lastMsg: string, time: string, hasDot: boolean) {
    Row() {
      Text('\u{1F464}')
        .fontSize(28)
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor('#E0E0E0')
        .textAlign(TextAlign.Center)
      Column() {
        Text(name)
          .fontSize(15)
          .fontColor('#333333')
          .fontWeight(FontWeight.Bold)
        Text(lastMsg)
          .fontSize(13)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 3 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
      Column() {
        Text(time)
          .fontSize(11)
          .fontColor('#CCCCCC')
        if (hasDot) {
          Text('●')
            .fontSize(8)
            .fontColor('#FF4500')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#F5F5F5' })
    .onClick(() => {
      router.pushUrl({ url: 'pages/MessagesPage' });
    })
  }

  @Builder
  NotificationItem(name: string, content: string, time: string) {
    Row() {
      Text('\u{1F464}')
        .fontSize(28)
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('#E0E0E0')
        .textAlign(TextAlign.Center)
      Column() {
        Row() {
          Text(name)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text(time)
            .fontSize(11)
            .fontColor('#CCCCCC')
            .margin({ left: 8 })
        }
        Text(content)
          .fontSize(13)
          .fontColor('#666666')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 3 })
      }
      .layoutWeight(1)
      .margin({ left: 10 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#F5F5F5' })
  }

  @Builder
  FollowItem(name: string, bio: string, time: string) {
    Row() {
      Text('\u{1F464}')
        .fontSize(28)
        .width(44)
        .height(44)
        .borderRadius(22)
        .backgroundColor('#E0E0E0')
        .textAlign(TextAlign.Center)
      Column() {
        Text(name)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Text(bio)
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
      Column() {
        Text('+ 关注')
          .fontSize(12)
          .fontColor('#0066FF')
          .border({ width: 1, color: '#0066FF' })
          .borderRadius(12)
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
        Text(time)
          .fontSize(11)
          .fontColor('#CCCCCC')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#F5F5F5' })
  }
}
