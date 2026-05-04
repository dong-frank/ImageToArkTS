import router from '@ohos.router';

@Entry
@Component
struct PrivacyPolicyPage {
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
        Text('详情')
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

      Scroll() {
        Column() {
          // Title
          Text('大众点评隐私政策')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')
            .padding({ left: 16, right: 16, top: 20 })
            .textAlign(TextAlign.Center)

          // Metadata
          Column() {
            this.MetaItem('发布日期：', '2026年03月02日')
            this.MetaItem('更新日期：', '2026年3月2日')
            this.MetaItem('生效日期：', '2026年3月9日')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })

          // Subtitle
          Text('隐私政策')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 12 })

          // Introduction paragraph
          Text('大众点评（以下或称"我们"）非常注重保护用户（"您"）的个人信息及隐私，我们深知个人信息对您的重要性，并将按照法律法规要求和业界成熟的安全标准，采取相应的安全保护措施来保护您的个人信息。我们希望通过本隐私政策向您清晰地介绍，在您使用我们的产品/服务时，我们如何处理您的个人信息，以及我们为您提供的访问、更正、删除和保护这些信息的方式。')
            .fontSize(14)
            .fontColor('#666666')
            .lineHeight(22)
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 16 })

          // Table of contents
          Text('本政策将帮助您了解以下内容：')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 12 })

          Column() {
            this.TocItem('1.', '我们如何收集和使用您的个人信息')
            this.TocItem('2.', '我们如何使用Cookie和同类技术')
            this.TocItem('3.', '我们如何共享、转让、公开披露您的个人信息')
            this.TocItem('4.', '我们如何保护您的个人信息')
            this.TocItem('5.', '您的权利')
            this.TocItem('6.', '我们如何处理儿童的个人信息')
            this.TocItem('7.', '您的个人信息如何在全球范围转移')
            this.TocItem('8.', '本政策如何更新')
            this.TocItem('9.', '如何联系我们')
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 40 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  MetaItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor('#999999')
      Text(value)
        .fontSize(13)
        .fontColor('#666666')
    }
    .width('100%')
    .margin({ bottom: 4 })
  }

  @Builder
  TocItem(index: string, title: string) {
    Row() {
      Text(index)
        .fontSize(14)
        .fontColor('#FF6600')
        .margin({ right: 8 })
      Text(title)
        .fontSize(14)
        .fontColor('#333333')
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
  }
}
