import router from '@ohos.router';

@Entry
@Component
struct SettingsPage {
  @State notificationBadge: boolean = true;

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor('#333333')
          .onClick(() => { router.back(); })
        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        Blank()
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#EDEDED')

      // Scrollable content
      Scroll() {
        Column() {
          Column() {
            // Section 1: Account & Security
            this.SettingsItem('账号与安全', '', true, () => {
              router.pushUrl({ url: 'pages/AccountSecurityPage' });
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            // Section 2: Interface & Notifications
            this.SettingsItem('消息通知', '', true, () => {
              // Placeholder for future page
            })
            this.SettingsItem('界面与显示', '', true, () => {
              router.pushUrl({ url: 'pages/InterfaceDisplayPage' });
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            // Section 3: Privacy
            this.SettingsItem('朋友权限', '', true, () => {
              router.pushUrl({ url: 'pages/FriendPermissionPage' });
            })
            this.SettingsItem('个人信息与权限', '', true, () => {
              // Placeholder for future page
            })
            this.SettingsItem('个人信息收集清单', '', true, () => {
              // Placeholder for future page
            })
            this.SettingsItem('第三方信息共享清单', '', true, () => {
              // Placeholder for future page
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            // Section 4: General
            this.SettingsItem('通用', '', true, () => {
              router.pushUrl({ url: 'pages/MoreSettingsPage' });
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            // Section 5: Help & About
            this.SettingsItem('帮助与反馈', '', true, () => {
              router.pushUrl({ url: 'pages/HelpFeedbackPage' });
            })
            this.SettingsItem('关于微信', '', true, () => {
              router.pushUrl({ url: 'pages/AboutWeChatPage' });
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            // Section 6: Plugins
            this.SettingsItem('功能', '', true, () => {
              router.pushUrl({ url: 'pages/FeatureIntroPage' });
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          // Section 7: Switch Account / Logout
          Column() {
            this.PlainActionItem('切换账号', '#576B95', () => {
              // Placeholder
            })
            this.PlainActionItem('退出', '#FA5151', () => {
              // Placeholder
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16, bottom: 16 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#EDEDED')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  SettingsItem(title: string, subtitle: string, showArrow: boolean, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#333333')
      Blank()
      if (subtitle !== '') {
        Text(subtitle)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ right: 4 })
      }
      if (showArrow) {
        Text('›')
          .fontSize(18)
          .fontColor('#CCCCCC')
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      onClick();
    })
    .border({
      width: { bottom: 0.5 },
      color: '#F1F1F1'
    })
  }

  @Builder
  PlainActionItem(title: string, color: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(color)
    }
    .width('100%')
    .height(48)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      onClick();
    })
    .border({
      width: { bottom: 0.5 },
      color: '#F1F1F1'
    })
  }
}
