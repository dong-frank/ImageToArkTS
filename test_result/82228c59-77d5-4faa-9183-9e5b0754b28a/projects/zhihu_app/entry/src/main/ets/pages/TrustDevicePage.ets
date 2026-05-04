import router from '@ohos.router';

@Entry
@Component
struct TrustDevicePage {
  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('\u2190')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => { router.back(); })
        Text('信任设备')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Status banner
      Row() {
        Text('\u2139')
          .fontSize(16)
          .fontColor('#999999')
          .margin({ right: 8 })
        Text('暂无信任设备')
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F5F5F5')
      .margin({ top: 8, left: 12, right: 12 })
      .borderRadius(8)

      // Main action area
      Column() {
        Text('\u{1F4BB}')
          .fontSize(64)
          .margin({ top: 60 })

        Text('将本机设置为信任设备')
          .fontSize(16)
          .fontColor('#0066FF')
          .margin({ top: 20 })
          .onClick(() => {
            // Set as trusted device
          })

        Text('设置成功后，在此设备上登录和使用知乎就会被视为安全使用，无需进行安全验证。')
          .fontSize(13)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
          .width('80%')
          .margin({ top: 16 })
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
