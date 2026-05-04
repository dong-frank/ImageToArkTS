import router from '@ohos.router';

@Entry
@Component
struct NotificationNewMail {
  // --- Navigation stubs ---
  // back → returns to pages/SettingsRoot

  goBack() {
    router.back()
  }

  build() {
    Column() {
      // --- Navigation Bar ---
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#007AFF')
          .padding({ left: 8, right: 12, top: 4, bottom: 4 })
          .onClick(() => { this.goBack() })

        Text('新邮件提醒')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row()
          .width(28)
          .height(28)
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 16 })
      .alignItems(VerticalAlign.Center)

      Divider()
        .color('#E5E5E5')
        .strokeWidth(0.5)

      // --- Content placeholder (from partial draft recovery) ---
      Column({ space: 12 }) {
        Text('新邮件提醒开关')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Text('请在系统设置中修改通知样式')
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
