/**
 * ImportantContactsPage - Empty state for important contacts
 * Based on: Draft 8 (success)
 */
import router from '@ohos.router';

@Entry
@Component
struct ImportantContactsPage {
  handleBackTap(): void {
    router.back();
  }

  handleAddContact(): void {
    // Placeholder: would open contact picker or add flow
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

        Text('重要联系人')
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

      // Empty state content - centered
      Column() {
        Column() {
          // Envelope icon with bookmark
          Text('✉️')
            .fontSize(48)
            .margin({ bottom: 16 })

          Text('快速查看重要联系人的来信')
            .fontSize(15)
            .fontColor('#666666')
            .margin({ bottom: 16 })

          Text('添加重要联系人')
            .fontSize(16)
            .fontColor('#4A90D9')
            .fontWeight(FontWeight.Medium)
            .onClick(() => { this.handleAddContact(); })
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
