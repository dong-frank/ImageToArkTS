import router from '@ohos.router';
import { BottomNavBar } from '../components/BottomNavBar';
import { MessageItem } from '../models/DataTypes';

@Entry
@Component
struct MessagePage {
  @State currentTab: number = 2;
  @State messages: MessageItem[] = [
    new MessageItem('1', '👤', '美食达人小王', '这家店真的超好吃！下次一起去吧', '10:32', 3),
    new MessageItem('2', '👤', '吃货小李', '好的，那就约明天中午', '09:15', 0),
    new MessageItem('3', '👤', '探店小分队', '[图片]', '昨天', 5),
    new MessageItem('4', '👤', '美食推荐官', '本周热门榜单已更新，快来看看吧', '昨天', 1),
    new MessageItem('5', '👤', '甜品控小张', '那家新开的蛋糕店评价不错', '周一', 0),
    new MessageItem('6', '👤', '火锅爱好者群', '周末聚餐有人报名吗？', '周日', 8),
    new MessageItem('7', '👤', '系统通知', '您的订单已确认，预计30分钟内送达', '周六', 0),
    new MessageItem('8', '👤', '优惠助手', '您有一张满100减20的优惠券即将过期', '周五', 0),
  ];

  build() {
    Column() {
      // Header
      Row() {
        Text('消息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Text('全部已读')
          .fontSize(14)
          .fontColor('#FF6600')
          .onClick(() => {
            const updated: MessageItem[] = [];
            for (let i = 0; i < this.messages.length; i++) {
              const msg = this.messages[i];
              updated.push(new MessageItem(msg.id, msg.avatar, msg.name, msg.lastMessage, msg.time, 0));
            }
            this.messages = updated;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // Search bar
      Row() {
        Text('🔍')
          .fontSize(16)
          .margin({ right: 6 })
        Text('搜索消息')
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .height(36)
      .backgroundColor('#F5F5F5')
      .borderRadius(18)
      .padding({ left: 12 })
      .margin({ left: 16, right: 16, bottom: 8 })

      // Message list
      List() {
        ForEach(this.messages, (item: MessageItem) => {
          ListItem() {
            Row() {
              // Avatar
              Text(item.avatar)
                .fontSize(28)
                .width(48)
                .height(48)
                .backgroundColor('#F0F0F0')
                .borderRadius(24)
                .textAlign(TextAlign.Center)

              // Content
              Column() {
                Row() {
                  Text(item.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Blank()

                  Text(item.time)
                    .fontSize(12)
                    .fontColor('#999999')
                }
                .width('100%')

                Row() {
                  Text(item.lastMessage)
                    .fontSize(13)
                    .fontColor('#999999')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)

                  if (item.unreadCount > 0) {
                    Text(item.unreadCount.toString())
                      .fontSize(11)
                      .fontColor('#FFFFFF')
                      .backgroundColor('#FF6600')
                      .borderRadius(10)
                      .padding({ left: 6, right: 6, top: 1, bottom: 1 })
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
            .onClick(() => {
              // Navigate to chat detail (placeholder)
            })
          }
          .border({
            width: { bottom: 0.5 },
            color: '#F0F0F0'
          })
        }, (item: MessageItem) => item.id)
      }
      .layoutWeight(1)
      .width('100%')

      // Bottom navigation
      BottomNavBar({ currentTab: $currentTab })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
