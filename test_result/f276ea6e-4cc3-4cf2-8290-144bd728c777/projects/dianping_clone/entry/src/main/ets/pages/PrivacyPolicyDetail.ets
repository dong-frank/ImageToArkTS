import router from '@ohos.router';

interface ClauseItem {
  index: number;
  title: string;
}

interface MetaInfoItem {
  label: string;
  value: string;
}

@Entry
@Component
struct PrivacyPolicyDetail {
  private metaInfo: MetaInfoItem[] = [
    { label: '发布日期', value: '2025-12-24' },
    { label: '更新日期', value: '2025-12-24' },
    { label: '生效日期', value: '2025-12-24' }
  ];

  private introText: string =
    '大众点评（以下简称"我们"）深知个人信息对您的重要性，并会尽全力保护您的个人信息安全可靠。' +
    '我们致力于维持您对我们的信任，恪守以下原则，保护您的个人信息：权责一致原则、目的明确原则、' +
    '选择同意原则、最少够用原则、确保安全原则、主体参与原则、公开透明原则等。同时，我们承诺，' +
    '我们将按业界成熟的安全标准，采取相应的安全保护措施来保护您的个人信息。';

  private clauseItems: ClauseItem[] = [
    { index: 1, title: '我们如何收集和使用您的个人信息' },
    { index: 2, title: '我们如何使用Cookie和同类技术' },
    { index: 3, title: '我们如何共享、转让、公开披露您的个人信息' },
    { index: 4, title: '我们如何保护您的个人信息' },
    { index: 5, title: '您的权利' },
    { index: 6, title: '我们如何处理未成年人的个人信息' },
    { index: 7, title: '您的个人信息如何在全球范围转移' },
    { index: 8, title: '本政策如何更新' }
  ];

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ left: 4, right: 12, top: 4, bottom: 4 })
          .onClick(() => {
            router.back();
          })

        Text('大众点评隐私政策')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Spacer to balance the back button
        Row()
          .width(40)
          .height(1)
      }
      .width('100%')
      .height(48)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')

      // Divider
      Divider()
        .color('#F0F0F0')
        .strokeWidth(0.5)

      // Scrollable content body
      Scroll() {
        Column() {
          // Main title
          Text('大众点评隐私政策')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 24, bottom: 20 })

          // Meta info section
          Column() {
            ForEach(this.metaInfo, (item: MetaInfoItem) => {
              Row() {
                Text(item.label)
                  .fontSize(14)
                  .fontColor('#999999')
                  .width(70)

                Text(item.value)
                  .fontSize(14)
                  .fontColor('#333333')
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ top: 6, bottom: 6 })
            })
          }
          .width('100%')
          .padding({ left: 4, right: 4, top: 4, bottom: 16 })

          // Divider
          Divider()
            .color('#F0F0F0')
            .strokeWidth(0.5)
            .margin({ bottom: 16 })

          // Intro paragraph
          Text(this.introText)
            .fontSize(15)
            .fontColor('#555555')
            .lineHeight(24)
            .width('100%')
            .padding({ bottom: 20 })

          // Section heading
          Text('本政策将帮助您了解以下内容：')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width('100%')
            .padding({ bottom: 16 })

          // Numbered clause list
          Column() {
            ForEach(this.clauseItems, (item: ClauseItem, index: number) => {
              Row() {
                Text(`${item.index}、`)
                  .fontSize(15)
                  .fontColor('#333333')
                  .fontWeight(FontWeight.Medium)

                Text(item.title)
                  .fontSize(15)
                  .fontColor('#333333')
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .onClick(() => {
                // Same-page anchor navigation - unresolved, keep as placeholder
                // In a full implementation, this would scroll to the corresponding section
                console.info(`Navigate to clause: ${item.title}`);
              })

              if (index < this.clauseItems.length - 1) {
                Divider()
                  .color('#F5F5F5')
                  .strokeWidth(0.5)
              }
            })
          }
          .width('100%')
          .padding({ bottom: 32 })
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
