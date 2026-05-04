import router from '@ohos.router';

@Entry
@Component
struct SettingsPage {
  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })
        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        // Placeholder for symmetry
        Row()
          .width(22)
          .height(22)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // Settings list
      Scroll() {
        Column() {
          // Section: Account & Profile
          this.SettingItem('个人资料', '', '', true)
          this.SettingsDivider()
          this.SettingItem('账号与安全', '', '', true)
          this.SettingsDivider()

          // Section: Notifications & Privacy
          this.SettingItem('消息通知设置', '', '', true)
          this.SettingsDivider()
          this.SettingItem('隐私管理', '', '', true)
          this.SettingsDivider()

          // Section: General
          this.SettingItem('通用', '', '', true)
          this.SettingsDivider()

          // Section: Accessibility
          this.SettingItem('长辈版', '字大看得清，使用更简单', '未开启', true)
          this.SettingsDivider()
          this.SettingItemWithBadge('未成年人模式', '新功能', '未开启', true)
          this.SettingsDivider()

          // Section: Language & Storage
          this.SettingItem('多语言', '', '', true)
          this.SettingsDivider()
          this.SettingItemWithBadge('存储空间', '新功能', '1.2 GB', true)
          this.SettingsDivider()

          // Section: Diagnostics
          this.SettingItem('诊断网络', '', '', true)
          this.SettingsDivider()

          // Section: Legal & Compliance
          this.SettingItem('隐私政策', '', '', true)
          this.SettingsDivider()
          this.SettingItem('个人信息收集清单', '', '', true)
          this.SettingsDivider()
          this.SettingItem('第三方信息数据共享', '', '', true)
          this.SettingsDivider()

          // Section: Feedback
          this.SettingItem('意见反馈', '', '', true)
          this.SettingsDivider()

          // Section: About
          this.SettingItem('关于我们', '', '', true)
          this.SettingsDivider()

          // Section: Contact
          this.SettingItem('热线电话', '', '10100011', false)

          // Logout button
          Column() {
            Text('退出登录')
              .fontSize(16)
              .fontColor('#FF4444')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 14, bottom: 14 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ top: 20, bottom: 30 })
          .onClick(() => {
            // Handle logout
          })
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
  SettingItem(label: string, subtitle: string, status: string, hasArrow: boolean) {
    Row() {
      Column() {
        Text(label)
          .fontSize(16)
          .fontColor('#333333')
        if (subtitle !== '') {
          Text(subtitle)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (status !== '') {
        Text(status)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ right: 8 })
      }

      if (hasArrow) {
        Text('>')
          .fontSize(16)
          .fontColor('#CCCCCC')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      this.handleItemClick(label);
    })
  }

  @Builder
  SettingItemWithBadge(label: string, badge: string, status: string, hasArrow: boolean) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#333333')

      Text(badge)
        .fontSize(10)
        .fontColor('#FFFFFF')
        .backgroundColor('#FF4444')
        .borderRadius(4)
        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
        .margin({ left: 6 })

      Blank()

      if (status !== '') {
        Text(status)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ right: 8 })
      }

      if (hasArrow) {
        Text('>')
          .fontSize(16)
          .fontColor('#CCCCCC')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      this.handleItemClick(label);
    })
  }

  @Builder
  SettingsDivider() {
    Divider()
      .strokeWidth(0.5)
      .color('#F0F0F0')
      .margin({ left: 16 })
  }

  handleItemClick(label: string): void {
    const routeMap: Record<string, string> = {
      '个人资料': 'pages/PersonalInfoPage',
      '账号与安全': 'pages/AccountSecurityPage',
      '消息通知设置': 'pages/NotificationSettingsPage',
      '隐私管理': 'pages/PrivacyManagementPage',
      '通用': 'pages/GeneralSettingsPage',
      '多语言': 'pages/LanguagePage',
      '存储空间': 'pages/StoragePage',
      '隐私政策': 'pages/PrivacyPolicyPage',
      '个人信息收集清单': 'pages/PrivacyPolicyPage',
      '第三方信息数据共享': 'pages/SDKListPage',
      '意见反馈': 'pages/FeedbackPage',
      '关于我们': 'pages/AboutPage',
    };

    const route = routeMap[label];
    if (route) {
      router.pushUrl({ url: route });
    }
  }
}
