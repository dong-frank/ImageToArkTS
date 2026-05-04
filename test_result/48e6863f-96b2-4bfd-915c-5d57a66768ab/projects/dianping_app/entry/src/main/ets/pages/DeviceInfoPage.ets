import router from '@ohos.router';

@Entry
@Component
struct DeviceInfoPage {
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
        Text('当前设备信息')
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

      // Device info list
      Column() {
        this.InfoItem('设备操作系统', 'HarmonyOS')
        this.ItemDivider()
        this.InfoItem('设备系统版本', '5.0.0')
        this.ItemDivider()
        this.InfoItem('屏幕分辨率', '1179*2556')
        this.ItemDivider()
        this.InfoItem('设备语言', '简体中文')
        this.ItemDivider()
        this.InfoItem('地区', '中国')
        this.ItemDivider()
        this.InfoItem('时区', 'Asia/Shanghai')
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
  InfoItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)

      Text(value)
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }

  @Builder
  ItemDivider() {
    Divider()
      .strokeWidth(0.5)
      .color('#F0F0F0')
      .margin({ left: 16 })
  }
}
