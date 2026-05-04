import router from '@ohos.router';

@Entry
@Component
struct SettingsPage {
  build() {
    Column() {
      // Top bar
      Row() {
        Text('\u{2190}')
          .fontSize(20)
          .fontColor('#333333')
          .padding(12)
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
          .width(44)
          .height(44)
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })

      Scroll() {
        Column() {
          // Account section
          this.SectionHeader('账号与绑定')
          this.SettingItem('\u{1F464}', '账号与安全', '', () => {
            router.pushUrl({ url: 'pages/PersonalInfoGuidePage' });
          })
          this.SettingItem('\u{1F4F1}', '手机号', '186****5678', () => {
            // Phone binding
          })
          this.SettingItem('\u{2709}', '邮箱', 'zh****@example.com', () => {
            // Email binding
          })
          this.SettingItem('\u{1F517}', '第三方账号绑定', '', () => {
            router.pushUrl({ url: 'pages/ThirdPartySharePage' });
          })

          // Display section
          this.SectionHeader('通用')
          this.SettingItem('\u{1F30D}', '语言', '简体中文', () => {
            // Language settings
          })
          this.SettingItem('\u{1F310}', '字体大小', '中', () => {
            // Font size settings
          })
          this.SettingItem('\u{1F4F1}', '深色模式', '跟随系统', () => {
            // Dark mode settings
          })
          this.SettingItem('\u{1F4F6}', '视频自动播放', '', () => {
            router.pushUrl({ url: 'pages/VideoAutoPlayPage' });
          })

          // Notification section
          this.SectionHeader('通知与推送')
          this.SettingItem('\u{1F514}', '消息通知', '', () => {
            router.pushUrl({ url: 'pages/MessageSettingsPage' });
          })
          this.SettingItem('\u{1F4E2}', '推送通知', '', () => {
            router.pushUrl({ url: 'pages/PushSettingsPage' });
          })

          // Privacy section
          this.SectionHeader('隐私与安全')
          this.SettingItem('\u{1F512}', '隐私设置', '', () => {
            router.pushUrl({ url: 'pages/PrivacyPage' });
          })
          this.SettingItem('\u{1F6E1}', '黑名单管理', '', () => {
            // Blacklist management
          })
          this.SettingItem('\u{1F510}', '青少年模式', '', () => {
            router.pushUrl({ url: 'pages/MinorModePage' });
          })

          // Storage section
          this.SectionHeader('存储与缓存')
          this.SettingItem('\u{1F4BE}', '清理缓存', '128 MB', () => {
            // Clear cache
          })
          this.SettingItem('\u{1F4C2}', '数据管理', '', () => {
            // Data management
          })

          // About section
          this.SectionHeader('其他')
          this.SettingItem('\u{2139}', '关于知乎', '', () => {
            router.pushUrl({ url: 'pages/AboutPage' });
          })
          this.SettingItem('\u{1F4C4}', '用户协议', '', () => {
            router.pushUrl({ url: 'pages/TermsPage' });
          })
          this.SettingItem('\u{1F6A8}', 'ICP备案', '', () => {
            router.pushUrl({ url: 'pages/IcpRecordPage' });
          })
          this.SettingItem('\u{2753}', '帮助与反馈', '', () => {
            router.pushUrl({ url: 'pages/HelpCenterPage' });
          })

          // Logout button
          Button('退出登录')
            .fontSize(16)
            .fontColor('#FF3333')
            .backgroundColor('#FFFFFF')
            .width('90%')
            .height(44)
            .borderRadius(22)
            .margin({ top: 24, bottom: 32 })
            .onClick(() => {
              // Logout action
            })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(12)
      .fontColor('#999999')
      .padding({ left: 16, top: 20, bottom: 8 })
      .width('100%')
  }

  @Builder
  SettingItem(icon: string, title: string, value: string, onClick: () => void) {
    Row() {
      Text(icon)
        .fontSize(18)
      Text(title)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
        .margin({ left: 10 })
      if (value !== '') {
        Text(value)
          .fontSize(13)
          .fontColor('#999999')
      }
      Text('>')
        .fontSize(14)
        .fontColor('#CCCCCC')
        .margin({ left: 6 })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 12 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
    .onClick(onClick)
  }
}
