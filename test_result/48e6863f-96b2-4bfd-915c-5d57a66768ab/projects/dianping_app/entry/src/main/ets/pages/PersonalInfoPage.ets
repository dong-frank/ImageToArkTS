import router from '@ohos.router';

@Entry
@Component
struct PersonalInfoPage {
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
        Text('个人信息查看与管理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Row()
          .width(22)
          .height(22)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // Content list
      Column() {
        this.NavItem('账号资料', () => {
          // Navigate to account profile
        })

        Divider()
          .strokeWidth(0.5)
          .color('#F0F0F0')
          .margin({ left: 16 })

        this.NavItem('当前设备信息', () => {
          router.pushUrl({ url: 'pages/DeviceInfoPage' });
        })

        Divider()
          .strokeWidth(0.5)
          .color('#F0F0F0')
          .margin({ left: 16 })

        this.NavItem('应用相关信息', () => {
          router.pushUrl({ url: 'pages/AppInfoPage' });
        })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .margin({ top: 10 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  NavItem(label: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)

      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      onClick();
    })
  }
}
