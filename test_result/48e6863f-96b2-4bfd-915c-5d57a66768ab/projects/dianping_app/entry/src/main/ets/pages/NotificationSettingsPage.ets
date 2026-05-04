import router from '@ohos.router';

@Entry
@Component
struct NotificationSettingsPage {
  @State systemNotificationEnabled: boolean = false;
  @State bannerReminderEnabled: boolean = true;
  @State marketingPopupEnabled: boolean = true;
  @State splashAdEnabled: boolean = true;

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

        Text('消息通知设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Placeholder for right side balance
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
          // Section: 大众点评未打开时
          this.SectionHeader('大众点评未打开时')

          Column() {
            this.NavigationSettingItem(
              '系统通知',
              '排队/订单动态、推荐内容等通知',
              this.systemNotificationEnabled ? '已开启' : '已关闭',
              () => {
                // Navigate to system notification settings
              }
            )
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 12, right: 12 })

          // Section: 大众点评打开时
          this.SectionHeader('大众点评打开时')

          Column() {
            this.ToggleSettingItem(
              'App顶部横幅提醒',
              '',
              this.bannerReminderEnabled,
              (value: boolean) => {
                this.bannerReminderEnabled = value;
              }
            )

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.ToggleSettingItem(
              'App首页营销弹窗',
              '',
              this.marketingPopupEnabled,
              (value: boolean) => {
                this.marketingPopupEnabled = value;
              }
            )

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.ToggleSettingItem(
              'App开屏广告',
              '',
              this.splashAdEnabled,
              (value: boolean) => {
                this.splashAdEnabled = value;
              }
            )
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 12, right: 12 })

          // Message page settings entry
          Column() {
            this.NavigationSettingItem(
              '消息页设置',
              '',
              '',
              () => {
                router.pushUrl({ url: 'pages/MessagePageSettingsPage' });
              }
            )
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 12, right: 12, top: 10 })
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
  NavigationSettingItem(
    label: string,
    description: string,
    trailingText: string,
    onClick: () => void
  ) {
    Row() {
      Column() {
        Text(label)
          .fontSize(15)
          .fontColor('#333333')
        if (description !== '') {
          Text(description)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (trailingText !== '') {
        Text(trailingText)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ right: 4 })
      }

      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      onClick();
    })
  }

  @Builder
  ToggleSettingItem(
    label: string,
    description: string,
    isOn: boolean,
    onChange: (value: boolean) => void
  ) {
    Row() {
      Column() {
        Text(label)
          .fontSize(15)
          .fontColor('#333333')
        if (description !== '') {
          Text(description)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor('#FF6600')
        .onChange((value: boolean) => {
          onChange(value);
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
  }
}
