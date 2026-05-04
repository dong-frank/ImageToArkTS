import router from '@ohos.router';

@Entry
@Component
struct AccountSecurityPage {
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
        Text('账号与安全')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        // Placeholder for symmetry with back arrow
        Row()
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#EDEDED')

      Scroll() {
        Column() {
          // Section 1: Account info
          Column() {
            this.MenuItem('微信号', 'WeChatID_***', true)
            this.MenuItem('手机号', '138****5678', true)
            this.MenuItem('更多信息', '', true, () => {
              // Placeholder
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          // Section 2: Security
          Column() {
            this.MenuItem('微信密码', '', true, () => {
              // Placeholder
            })
            this.MenuItem('声音锁', '', true, () => {
              // Placeholder
            })
            this.MenuItem('应急联系人', '', true, () => {
              // Placeholder
            })
            this.MenuItem('登录设备管理', '', true, () => {
              // Placeholder
            })
            this.MenuItem('安全中心', '', true, () => {
              router.pushUrl({ url: 'pages/SecurityCenterPage' });
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            this.MenuItem('微信安全中心', '', true, () => {
              // Placeholder for external link
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
  MenuItem(title: string, value: string, showArrow: boolean, onClick?: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#333333')
      Blank()
      if (value !== '') {
        Text(value)
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
      if (onClick) {
        onClick();
      }
    })
    .border({
      width: { bottom: 0.5 },
      color: '#F1F1F1'
    })
  }
}
