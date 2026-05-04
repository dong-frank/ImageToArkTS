import router from '@ohos.router';

@Entry
@Component
struct MessagePageSettingsPage {
  @State activityMessagesEnabled: boolean = true;
  @State serviceUpdatesEnabled: boolean = true;
  @State violationNoticeEnabled: boolean = true;
  @State creditScoreEnabled: boolean = true;
  @State creditExpressEnabled: boolean = true;
  @State reviewStatusEnabled: boolean = true;
  @State imageReviewEnabled: boolean = true;
  @State complaintFeedbackEnabled: boolean = true;
  @State friendUpdateReminderEnabled: boolean = true;
  @State myUpdateRemindFriendsEnabled: boolean = true;

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('<')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })

        Text('消息页设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row()
          .width(44)
          .height(44)
      }
      .width('100%')
      .height(48)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#FFFFFF')

      // Scrollable content
      Scroll() {
        Column() {
          // Section: 消息设置
          this.SectionHeader('消息设置')

          Column() {
            this.ToggleItem('🚩', '活动消息', this.activityMessagesEnabled, (value: boolean) => {
              this.activityMessagesEnabled = value;
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 48 })

            this.ToggleItem('📄', '服务动态', this.serviceUpdatesEnabled, (value: boolean) => {
              this.serviceUpdatesEnabled = value;
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 48 })

            this.ToggleItem('⚠️', '违规通知', this.violationNoticeEnabled, (value: boolean) => {
              this.violationNoticeEnabled = value;
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 48 })

            this.ToggleItem('💳', '诚信分', this.creditScoreEnabled, (value: boolean) => {
              this.creditScoreEnabled = value;
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 48 })

            this.ToggleItem('🛡️', '诚信直通车', this.creditExpressEnabled, (value: boolean) => {
              this.creditExpressEnabled = value;
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 48 })

            this.ToggleItem('🔔', '点评状态变更通知', this.reviewStatusEnabled, (value: boolean) => {
              this.reviewStatusEnabled = value;
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 48 })

            this.ToggleItem('🖼️', '图片审核', this.imageReviewEnabled, (value: boolean) => {
              this.imageReviewEnabled = value;
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 48 })

            this.ToggleItem('📝', '投诉反馈', this.complaintFeedbackEnabled, (value: boolean) => {
              this.complaintFeedbackEnabled = value;
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 12, right: 12 })

          // Section: 私信消息接收设置
          this.SectionHeader('私信消息接收设置')

          Column() {
            this.ToggleItem('👥', '好友动态更新提醒', this.friendUpdateReminderEnabled, (value: boolean) => {
              this.friendUpdateReminderEnabled = value;
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 48 })

            this.ToggleItem('📢', '我的动态更新后提醒好友', this.myUpdateRemindFriendsEnabled, (value: boolean) => {
              this.myUpdateRemindFriendsEnabled = value;
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 12, right: 12 })
        }
        .width('100%')
        .padding({ top: 10, bottom: 20 })
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
  SectionHeader(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor('#999999')
      .padding({ left: 28, top: 16, bottom: 8 })
      .width('100%')
  }

  @Builder
  ToggleItem(icon: string, label: string, isOn: boolean, onChange: (value: boolean) => void) {
    Row() {
      Text(icon)
        .fontSize(20)
        .margin({ right: 12 })

      Text(label)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor('#FF6600')
        .onChange((value: boolean) => {
          onChange(value);
        })
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
  }
}
