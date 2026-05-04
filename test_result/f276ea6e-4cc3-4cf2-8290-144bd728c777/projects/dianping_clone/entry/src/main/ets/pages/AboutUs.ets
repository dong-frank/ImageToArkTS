import router from '@ohos.router';

// Settings item data model
interface AboutItemData {
  label: string;
  trailingText?: string;
  isUnresolved: boolean;
}

@Entry
@Component
struct AboutUs {
  // 6 items: 检查新版本/喜欢我们打分鼓励/帮助商户/协议与声明/营业执照/举报信息
  private aboutItems: AboutItemData[] = [
    { label: '检查新版本', trailingText: '新版本已发布，立即升级', isUnresolved: false },
    { label: '喜欢我们，打分鼓励', isUnresolved: false },
    { label: '帮助商户', isUnresolved: true },
    { label: '协议与声明', isUnresolved: true },
    { label: '营业执照', isUnresolved: true },
    { label: '举报信息', isUnresolved: true }
  ];

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ left: 16, right: 8, top: 12, bottom: 12 })
          .onClick(() => {
            router.back();
          })

        Text('关于我们')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })

      // Scrollable content area
      Scroll() {
        Column() {
          // Logo section
          Column() {
            // App logo placeholder - orange circle with "点评" text
            Text('大众点评')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF6600')
              .width(80)
              .height(80)
              .borderRadius(16)
              .backgroundColor('#FFF5EB')
              .textAlign(TextAlign.Center)

            // Version text
            Text('V11.61.13')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 12 })
          }
          .width('100%')
          .padding({ top: 40, bottom: 32 })
          .alignItems(HorizontalAlign.Center)

          // Settings list
          Column() {
            ForEach(this.aboutItems, (item: AboutItemData, index: number) => {
              Column() {
                Row() {
                  Text(item.label)
                    .fontSize(16)
                    .fontColor('#333333')

                  Blank()

                  if (item.trailingText) {
                    Text(item.trailingText)
                      .fontSize(13)
                      .fontColor('#FF6600')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ right: 6 })
                  }

                  Text('>')
                    .fontSize(16)
                    .fontColor('#CCCCCC')
                }
                .width('100%')
                .height(52)
                .padding({ left: 16, right: 16 })
                .backgroundColor('#FFFFFF')
                .alignItems(VerticalAlign.Center)
                .onClick(() => {
                  if (item.isUnresolved) {
                    // Unresolved targets: 协议与声明/营业执照/举报信息/帮助商户
                    // These pages are not covered in the current page set.
                    // Show a toast placeholder instead of creating fake routes.
                    console.info(`[AboutUs] Unresolved navigation: ${item.label}`);
                  } else if (item.label === '检查新版本') {
                    // Same-page action or system dialog - placeholder
                    console.info('[AboutUs] Check update triggered');
                  } else if (item.label === '喜欢我们，打分鼓励') {
                    // External App Store jump - placeholder
                    console.info('[AboutUs] Rate us triggered');
                  }
                })

                if (index < this.aboutItems.length - 1) {
                  Divider()
                    .strokeWidth(0.5)
                    .color('#F0F0F0')
                    .margin({ left: 16 })
                }
              }
            })
          }
          .width('100%')
          .borderRadius(0)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
