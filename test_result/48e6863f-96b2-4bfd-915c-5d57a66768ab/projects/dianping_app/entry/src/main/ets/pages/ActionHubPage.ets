import router from '@ohos.router';
import { ActionHubItem } from '../models/DataTypes';

@Entry
@Component
struct ActionHubPage {
  @State activeActions: ActionHubItem[] = [
    new ActionHubItem('1', '🎫', '限时优惠', '3张可用优惠券', '3'),
    new ActionHubItem('2', '🔥', '热门活动', '周末探店打卡挑战', 'HOT'),
    new ActionHubItem('3', '🎁', '积分商城', '1200积分可兑换', ''),
    new ActionHubItem('4', '📋', '我的订单', '2笔进行中', '2'),
  ];

  @State recentActivities: ActionHubItem[] = [
    new ActionHubItem('5', '⭐', '收藏有礼', '收藏店铺赢取好礼', ''),
    new ActionHubItem('6', '📝', '写评价', '评价过的餐厅可抽奖', ''),
    new ActionHubItem('7', '👥', '邀请好友', '邀请好友注册各得10元券', ''),
    new ActionHubItem('8', '🏆', '排行榜', '本周美食达人TOP10', ''),
    new ActionHubItem('9', '📅', '每日签到', '连续签到7天领大礼包', ''),
    new ActionHubItem('10', '🎯', '任务中心', '完成3项任务可领奖励', 'NEW'),
  ];

  build() {
    Column() {
      // Header
      Row() {
        Text('活动中心')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // Banner
      Row() {
        Column() {
          Text('🎉 美食节狂欢')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text('全场低至5折，限时抢购')
            .fontSize(13)
            .fontColor('#FFFFFF')
            .opacity(0.9)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('立即参与 >')
          .fontSize(13)
          .fontColor('#FFFFFF')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#FFFFFF33')
          .borderRadius(14)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .borderRadius(12)
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [['#FF6600', 0.0], ['#FF8800', 1.0]]
      })
      .margin({ left: 16, right: 16, bottom: 16 })

      // Active actions section
      Column() {
        Text('进行中的活动')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 8 })

        Grid() {
          ForEach(this.activeActions, (item: ActionHubItem) => {
            GridItem() {
              Column() {
                Row() {
                  Text(item.icon)
                    .fontSize(24)
                  if (item.badge && item.badge.length > 0) {
                    Text(item.badge)
                      .fontSize(10)
                      .fontColor('#FFFFFF')
                      .backgroundColor('#FF6600')
                      .borderRadius(8)
                      .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                      .margin({ left: 4 })
                  }
                }

                Text(item.title)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#333333')
                  .margin({ top: 8 })

                Text(item.subtitle)
                  .fontSize(11)
                  .fontColor('#999999')
                  .margin({ top: 2 })
              }
              .width('100%')
              .padding({ top: 16, bottom: 16 })
              .borderRadius(10)
              .backgroundColor('#FFF8F2')
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                // Navigate to action detail (placeholder)
              })
            }
          }, (item: ActionHubItem) => item.id)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // Recent activities section
      Column() {
        Text('更多活动')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 8 })

        List() {
          ForEach(this.recentActivities, (item: ActionHubItem) => {
            ListItem() {
              Row() {
                Text(item.icon)
                  .fontSize(24)
                  .width(44)
                  .height(44)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(10)
                  .textAlign(TextAlign.Center)

                Column() {
                  Row() {
                    Text(item.title)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#333333')

                    if (item.badge && item.badge.length > 0) {
                      Text(item.badge)
                        .fontSize(10)
                        .fontColor('#FF6600')
                        .backgroundColor('#FFF0E6')
                        .borderRadius(4)
                        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                        .margin({ left: 6 })
                    }
                  }

                  Text(item.subtitle)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ left: 12 })
                .layoutWeight(1)

                Text('>')
                  .fontSize(16)
                  .fontColor('#CCCCCC')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .onClick(() => {
                // Navigate to activity detail (placeholder)
              })
            }
            .border({
              width: { bottom: 0.5 },
              color: '#F5F5F5'
            })
          }, (item: ActionHubItem) => item.id)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
