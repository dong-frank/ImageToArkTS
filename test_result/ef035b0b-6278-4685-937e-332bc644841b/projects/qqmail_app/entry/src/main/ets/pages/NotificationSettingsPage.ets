/**
 * NotificationSettingsPage - New mail notification settings
 * Based on: Draft 7 (partial, raw recovery - rich structure)
 */
import router from '@ohos.router';

@Entry
@Component
struct NotificationSettingsPage {
  @State notificationEnabled: boolean = false;

  handleBackTap(): void {
    router.back();
  }

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('<')
          .fontSize(20)
          .fontColor('#4A90D9')
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.handleBackTap(); })

        Text('新邮件提醒')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Column().width(40)
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')

      // Main setting item with toggle
      Row() {
        Text('新邮件提醒')
          .fontSize(16)
          .fontColor('#1A1A1A')

        Blank()

        Toggle({ type: ToggleType.Switch, isOn: this.notificationEnabled })
          .onChange((isOn: boolean) => {
            this.notificationEnabled = isOn;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor('#FFFFFF')
      .margin({ top: 12 })

      // Instruction text
      Text('更改通知样式，请在iPhone的"设置"-"通知"功能中，找到"QQ邮箱"程序进行修改。')
        .fontSize(13)
        .fontColor('#999999')
        .lineHeight(18)
        .width('100%')
        .padding({ left: 16, right: 16, top: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
