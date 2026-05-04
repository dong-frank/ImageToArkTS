import router from '@ohos.router';

@Entry
@Component
struct AuxiliaryFeaturesPage {
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
        Text('辅助功能')
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
          // Section: 已启用的功能
          Column() {
            this.SectionHeader('已启用的功能')
            this.FeatureItem('QQ邮箱提醒', () => {
              // Placeholder for future page
            })
            this.FeatureItem('群发助手', () => {
              // Placeholder for future page
            })
            this.FeatureItem('微信支付', () => {
              // Placeholder for future page
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          // Section: 未启用的功能
          Column() {
            this.SectionHeader('未启用的功能')
            this.FeatureItem('腾讯新闻', () => {
              // Placeholder for future page
            })
            this.FeatureItem('微信运动', () => {
              // Placeholder for future page
            })
            this.FeatureItem('微信游戏', () => {
              // Placeholder for future page
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
  SectionHeader(title: string) {
    Row() {
      Text(title)
        .fontSize(13)
        .fontColor('#999999')
    }
    .width('100%')
    .height(36)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F5F5F5')
  }

  @Builder
  FeatureItem(title: string, onClick: () => void) {
    Row() {
      // Icon placeholder
      Circle()
        .width(32)
        .height(32)
        .fill('#E0E0E0')

      Text(title)
        .fontSize(16)
        .fontColor('#333333')
        .margin({ left: 12 })

      Blank()

      Text('›')
        .fontSize(18)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      onClick();
    })
    .border({
      width: { bottom: 0.5 },
      color: '#F1F1F1'
    })
  }
}
