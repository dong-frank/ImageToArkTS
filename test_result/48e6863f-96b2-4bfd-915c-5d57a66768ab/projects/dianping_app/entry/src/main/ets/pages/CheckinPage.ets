import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { StreakReward } from '../models/DataTypes';

class CheckinDay {
  day: number;
  checked: boolean;
  isToday: boolean;
  reward: string;

  constructor(day: number, checked: boolean, isToday: boolean, reward: string) {
    this.day = day;
    this.checked = checked;
    this.isToday = isToday;
    this.reward = reward;
  }
}

@Entry
@Component
struct CheckinPage {
  @State currentStreak: number = 5;
  @State totalCheckins: number = 23;
  @State checkedToday: boolean = false;
  @State showReward: boolean = false;
  @State rewardPoints: number = 0;

  // Current month: December 2025
  private monthLabel: string = '2025年12月';
  private weekDays: string[] = ['日', '一', '二', '三', '四', '五', '六'];

  // Calendar data for December 2025 (starts on Monday)
  // 1=Mon, 2=Tue, ..., 31=Wed
  private calendarDays: CheckinDay[] = [
    new CheckinDay(1, true, false, '+5'),
    new CheckinDay(2, true, false, '+5'),
    new CheckinDay(3, true, false, '+5'),
    new CheckinDay(4, true, false, '+5'),
    new CheckinDay(5, true, false, '+10'),
    new CheckinDay(6, false, false, '+5'),
    new CheckinDay(7, false, false, '+5'),
    new CheckinDay(8, false, false, '+5'),
    new CheckinDay(9, false, false, '+5'),
    new CheckinDay(10, false, false, '+5'),
    new CheckinDay(11, false, false, '+10'),
    new CheckinDay(12, false, false, '+5'),
    new CheckinDay(13, false, false, '+5'),
    new CheckinDay(14, false, false, '+5'),
    new CheckinDay(15, false, false, '+5'),
    new CheckinDay(16, false, false, '+5'),
    new CheckinDay(17, false, false, '+10'),
    new CheckinDay(18, false, false, '+5'),
    new CheckinDay(19, false, false, '+5'),
    new CheckinDay(20, false, false, '+5'),
    new CheckinDay(21, false, false, '+5'),
    new CheckinDay(22, false, false, '+5'),
    new CheckinDay(23, false, false, '+10'),
    new CheckinDay(24, false, false, '+5'),
    new CheckinDay(25, false, false, '+5'),
    new CheckinDay(26, false, false, '+5'),
    new CheckinDay(27, false, false, '+5'),
    new CheckinDay(28, false, false, '+5'),
    new CheckinDay(29, false, false, '+10'),
    new CheckinDay(30, false, false, '+5'),
    new CheckinDay(31, false, false, '+5'),
  ];

  // 7-day streak rewards
  private streakRewards: StreakReward[] = [
    new StreakReward(1, '🎫', 5, '5积分', true),
    new StreakReward(2, '⭐', 10, '10积分', true),
    new StreakReward(3, '🎁', 15, '15积分', true),
    new StreakReward(4, '💎', 20, '20积分', true),
    new StreakReward(5, '🎯', 25, '25积分', true),
    new StreakReward(6, '🏆', 50, '50积分', false),
    new StreakReward(7, '👑', 100, '100积分+优惠券', false),
  ];

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

        Text('每日签到')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('规则')
          .fontSize(14)
          .fontColor('#FF6600')
          .onClick(() => {
            promptAction.showToast({ message: '连续签到7天可获得100积分+优惠券大礼包！', duration: 2000 });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // Stats header card
          this.StatsHeader()

          // Check-in button
          this.CheckinButton()

          // 7-day streak rewards
          this.StreakRewards()

          // Monthly calendar
          this.MonthlyCalendar()

          // Check-in history summary
          this.CheckinHistory()
        }
        .width('100%')
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
  StatsHeader() {
    Column() {
      // Top stats row
      Row() {
        // Current streak
        Column() {
          Text(this.currentStreak.toString())
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6600')
          Text('连续签到(天)')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .layoutWeight(1)

        // Divider
        Column() {
          Divider()
            .vertical(true)
            .height(40)
            .color('#E0E0E0')
        }
        .padding({ left: 8, right: 8 })

        // Total checkins
        Column() {
          Text(this.totalCheckins.toString())
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text('累计签到(天)')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .layoutWeight(1)

        // Divider
        Column() {
          Divider()
            .vertical(true)
            .height(40)
            .color('#E0E0E0')
        }
        .padding({ left: 8, right: 8 })

        // Total points
        Column() {
          Text('358')
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6600')
          Text('累计积分')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 8 })
  }

  @Builder
  CheckinButton() {
    Column() {
      if (this.checkedToday) {
        // Already checked in
        Column() {
          Text('✅')
            .fontSize(40)
          Text('今日已签到')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6600')
            .margin({ top: 8 })
          Text('已连续签到 ' + this.currentStreak + ' 天，继续加油！')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .width('100%')
        .padding({ top: 20, bottom: 20 })
      } else {
        // Not checked in yet
        Column() {
          Text('📅')
            .fontSize(40)
          Text('点击签到')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ top: 8 })
          Text('签到可获得积分奖励')
            .fontSize(13)
            .fontColor('rgba(255,255,255,0.8)')
            .margin({ top: 4 })
        }
        .width('100%')
        .padding({ top: 20, bottom: 20 })
        .backgroundColor('#FF6600')
        .borderRadius(12)
        .onClick(() => {
          this.doCheckin();
        })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .margin({ top: 8 })
  }

  @Builder
  StreakRewards() {
    Column() {
      Row() {
        Text('连续签到奖励')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Text('已签 ' + this.currentStreak + '/7 天')
          .fontSize(12)
          .fontColor('#FF6600')
      }
      .width('100%')
      .margin({ bottom: 12 })

      Row() {
        ForEach(this.streakRewards, (reward: StreakReward, index: number) => {
          Column() {
            // Connector line
            if (index > 0) {
              Divider()
                .width('100%')
                .height(2)
                .color(reward.achieved ? '#FF6600' : '#E0E0E0')
                .margin({ bottom: 8 })
            }

            // Reward circle
            Column() {
              Text(reward.icon)
                .fontSize(22)
            }
            .width(44)
            .height(44)
            .backgroundColor(reward.achieved ? '#FFF0E6' : '#F5F5F5')
            .borderRadius(22)
            .border({ width: 2, color: reward.achieved ? '#FF6600' : '#E0E0E0' })
            .justifyContent(FlexAlign.Center)

            Text(reward.label)
              .fontSize(10)
              .fontColor(reward.achieved ? '#FF6600' : '#CCCCCC')
              .margin({ top: 4 })

            Text('第' + reward.day + '天')
              .fontSize(9)
              .fontColor('#CCCCCC')
              .margin({ top: 1 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 8 })
  }

  @Builder
  MonthlyCalendar() {
    Column() {
      // Month header
      Row() {
        Text('◀')
          .fontSize(14)
          .fontColor('#999999')

        Text(this.monthLabel)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 16, right: 16 })

        Text('▶')
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 12 })

      // Week day headers
      Row() {
        ForEach(this.weekDays, (day: string) => {
          Text(day)
            .fontSize(12)
            .fontColor('#999999')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        })
      }
      .width('100%')
      .margin({ bottom: 8 })

      // Calendar grid - December 2025 starts on Monday
      // We need to offset: Dec 1 is Monday, so Sunday (index 0) is empty
      Grid() {
        // Empty cell for Sunday before Dec 1
        GridItem() {
          Column() {}
            .width('100%')
            .height(40)
        }

        ForEach(this.calendarDays, (day: CheckinDay) => {
          GridItem() {
            Column() {
              Text(day.day.toString())
                .fontSize(13)
                .fontColor(this.getDayColor(day))
                .fontWeight(day.isToday ? FontWeight.Bold : FontWeight.Normal)

              if (day.checked) {
                Text('✓')
                  .fontSize(10)
                  .fontColor('#FF6600')
              } else if (day.isToday) {
                Text('今')
                  .fontSize(10)
                  .fontColor('#FF6600')
              } else {
                Text(day.reward)
                  .fontSize(9)
                  .fontColor('#CCCCCC')
              }
            }
            .width('100%')
            .height(44)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(day.isToday ? '#FFF0E6' : 'transparent')
            .borderRadius(day.isToday ? 8 : 0)
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsGap(2)
      .columnsGap(2)
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 8 })
  }

  @Builder
  CheckinHistory() {
    Column() {
      Text('签到记录')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start)

      this.HistoryItem('12月5日', '已签到', '+10积分', true)
      this.HistoryItem('12月4日', '已签到', '+5积分', true)
      this.HistoryItem('12月3日', '已签到', '+5积分', true)
      this.HistoryItem('12月2日', '已签到', '+5积分', true)
      this.HistoryItem('12月1日', '已签到', '+5积分', true)

      Text('查看更多记录 ›')
        .fontSize(13)
        .fontColor('#FF6600')
        .margin({ top: 8 })
        .onClick(() => {
          promptAction.showToast({ message: '加载更多签到记录...', duration: 1500 });
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 24 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 8 })
  }

  @Builder
  HistoryItem(date: string, status: string, reward: string, isLast: boolean) {
    Row() {
      Column() {
        Text(date)
          .fontSize(14)
          .fontColor('#333333')
        Text(status)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(reward)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF6600')
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .border({ width: { bottom: isLast ? 0 : 0.5 }, color: '#F0F0F0' })
  }

  getDayColor(day: CheckinDay): string {
    if (day.isToday) {
      return '#FF6600';
    }
    if (day.checked) {
      return '#333333';
    }
    return '#CCCCCC';
  }

  doCheckin() {
    this.checkedToday = true;
    this.currentStreak += 1;
    this.totalCheckins += 1;
    this.rewardPoints = this.currentStreak >= 7 ? 100 : (this.currentStreak * 5);

    promptAction.showToast({
      message: '签到成功！获得 ' + this.rewardPoints + ' 积分 🎉',
      duration: 2000
    });
  }
}
