import router from '@ohos.router';

@Entry
@Component
struct FeatureIntroPage {
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
        Text('功能介绍')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
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
          this.VersionItem('微信 8.0.71 主要更新', '2026-04-15', () => {
            // Placeholder for detail page
          })
          this.VersionItem('微信 8.0.70 主要更新', '2026-03-21', () => {
            // Placeholder for detail page
          })
          this.VersionItem('微信 8.0.69 主要更新', '2026-02-10', () => {
            // Placeholder for detail page
          })
          this.VersionItem('微信 8.0.68 主要更新', '2026-01-05', () => {
            // Placeholder for detail page
          })
          this.VersionItem('微信 8.0.67 主要更新', '2025-12-18', () => {
            // Placeholder for detail page
          })
          this.VersionItem('微信 8.0.66 主要更新', '2025-11-22', () => {
            // Placeholder for detail page
          })
          this.VersionItem('微信 8.0.65 主要更新', '2025-10-15', () => {
            // Placeholder for detail page
          })
          this.VersionItem('微信 8.0.64 主要更新', '2025-09-08', () => {
            // Placeholder for detail page
          })
          this.VersionItem('微信 8.0.63 主要更新', '2025-08-01', () => {
            // Placeholder for detail page
          })
          this.VersionItem('微信 8.0.62 主要更新', '2025-07-12', () => {
            // Placeholder for detail page
          })
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .margin({ top: 16, bottom: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#EDEDED')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  VersionItem(versionTitle: string, date: string, onClick: () => void) {
    Row() {
      Column() {
        Text(versionTitle)
          .fontSize(16)
          .fontColor('#333333')
        Text(date)
          .fontSize(12)
          .fontColor('#B3B3B3')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(18)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      onClick();
    })
    .border({
      width: { bottom: 0.5 },
      color: '#F1F1F1'
    })
  }
}
