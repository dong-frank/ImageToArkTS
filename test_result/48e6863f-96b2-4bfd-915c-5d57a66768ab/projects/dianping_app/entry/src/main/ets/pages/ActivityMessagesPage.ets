import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';

class ActivityMessage {
  id: string;
  icon: string;
  title: string;
  content: string;
  time: string;
  isRead: boolean;
  type: string; // 'promo', 'system', 'order', 'interact'

  constructor(id: string, icon: string, title: string, content: string, time: string, isRead: boolean, type: string) {
    this.id = id;
    this.icon = icon;
    this.title = title;
    this.content = content;
    this.time = time;
    this.isRead = isRead;
    this.type = type;
  }
}

@Entry
@Component
struct ActivityMessagesPage {
  @State selectedTab: number = 0; // 0=全部, 1=优惠, 2=互动, 3=系统
  @State messages: ActivityMessage[] = [
    new ActivityMessage('1', '🎫', '限时优惠', '您有一张满100减20的优惠券即将过期，快去使用吧！', '10分钟前', false, 'promo'),
    new ActivityMessage('2', '🔥', '热门活动', '周末探店打卡挑战赛火热进行中，参与赢取大奖！', '30分钟前', false, 'promo'),
    new ActivityMessage('3', '⭐', '评价邀请', '您在「海底捞火锅」的消费已完成，写评价可抽奖哦～', '1小时前', false, 'interact'),
    new ActivityMessage('4', '👥', '好友动态', '美食达人小王收藏了你推荐的「西贝莜面村」', '2小时前', true, 'interact'),
    new ActivityMessage('5', '🎁', '积分到账', '恭喜！您获得了120积分奖励，可前往积分商城兑换好礼', '3小时前', true, 'system'),
    new ActivityMessage('6', '📋', '订单提醒', '您的订单已确认，预计30分钟内送达', '5小时前', true, 'order'),
    new ActivityMessage('7', '🏆', '排行榜更新', '本周美食达人TOP10已更新，看看你排第几！', '昨天', true, 'promo'),
    new ActivityMessage('8', '💬', '评论回复', '探店小分队回复了你的笔记：「这家确实不错！」', '昨天', true, 'interact'),
    new ActivityMessage('9', '🔔', '系统通知', '大众点评App已更新至最新版本 v8.2.0', '2天前', true, 'system'),
    new ActivityMessage('10', '🎯', '任务提醒', '您还有3项任务未完成，完成后可领取奖励', '3天前', true, 'promo'),
    new ActivityMessage('11', '🍽️', '预约提醒', '您预约的「大董烤鸭」明天12:00，别忘了哦', '3天前', true, 'order'),
    new ActivityMessage('12', '🎉', '活动结束', '美食节狂欢活动已结束，感谢您的参与！', '1周前', true, 'promo'),
  ];

  private tabs: string[] = ['全部', '优惠', '互动', '系统'];

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })

        Text('活动消息')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('全部已读')
          .fontSize(14)
          .fontColor('#FF6600')
          .onClick(() => {
            this.markAllRead();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor('#FFFFFF')

      // Tab bar
      this.TabBar()

      // Message list
      List() {
        ForEach(this.getFilteredMessages(), (msg: ActivityMessage, index: number) => {
          ListItem() {
            this.MessageCard(msg)
          }
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  TabBar() {
    Row() {
      ForEach(this.tabs, (tab: string, index: number) => {
        Column() {
          Text(tab)
            .fontSize(14)
            .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedTab === index ? '#FF6600' : '#666666')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })

          // Active indicator
          if (this.selectedTab === index) {
            Divider()
              .width(24)
              .height(2)
              .color('#FF6600')
              .margin({ top: -2 })
          }
        }
        .onClick(() => {
          this.selectedTab = index;
        })
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
    .backgroundColor('#FFFFFF')
    .padding({ bottom: 4 })
  }

  @Builder
  MessageCard(msg: ActivityMessage) {
    Row() {
      // Icon
      Row() {
        Text(msg.icon)
          .fontSize(24)
      }
      .width(44)
      .height(44)
      .backgroundColor('#FFF0E6')
      .borderRadius(22)
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      // Content
      Column() {
        Row() {
          Text(msg.title)
            .fontSize(15)
            .fontWeight(msg.isRead ? FontWeight.Normal : FontWeight.Bold)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Blank()

          Text(msg.time)
            .fontSize(11)
            .fontColor('#CCCCCC')
        }
        .width('100%')

        Text(msg.content)
          .fontSize(13)
          .fontColor('#999999')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // Unread dot
      if (!msg.isRead) {
        Circle()
          .width(8)
          .height(8)
          .fill('#FF6600')
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 1 })
    .onClick(() => {
      this.markAsRead(msg);
      promptAction.showToast({ message: '查看详情: ' + msg.title, duration: 1500 });
    })
  }

  getFilteredMessages(): ActivityMessage[] {
    if (this.selectedTab === 0) {
      return this.messages;
    }

    const typeMap: Record<number, string> = {
      1: 'promo',
      2: 'interact',
      3: 'system'
    };

    const targetType = typeMap[this.selectedTab];
    const filtered: ActivityMessage[] = [];
    for (let i = 0; i < this.messages.length; i++) {
      if (this.messages[i].type === targetType) {
        filtered.push(this.messages[i]);
      }
    }
    return filtered;
  }

  markAsRead(msg: ActivityMessage) {
    const updated: ActivityMessage[] = [];
    for (let i = 0; i < this.messages.length; i++) {
      const m = this.messages[i];
      if (m.id === msg.id) {
        updated.push(new ActivityMessage(m.id, m.icon, m.title, m.content, m.time, true, m.type));
      } else {
        updated.push(m);
      }
    }
    this.messages = updated;
  }

  markAllRead() {
    const updated: ActivityMessage[] = [];
    for (let i = 0; i < this.messages.length; i++) {
      const m = this.messages[i];
      updated.push(new ActivityMessage(m.id, m.icon, m.title, m.content, m.time, true, m.type));
    }
    this.messages = updated;
    promptAction.showToast({ message: '已全部标记为已读', duration: 1500 });
  }
}
