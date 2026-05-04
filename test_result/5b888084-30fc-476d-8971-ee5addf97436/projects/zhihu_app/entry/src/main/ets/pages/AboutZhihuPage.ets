import { router } from '@kit.ArkUI';

interface AboutItem {
  label: string;
  route?: string;
}

@Entry
@Component
struct AboutZhihuPage {
  private items: AboutItem[] = [
    { label: '知乎协议', route: 'pages/ZhihuAgreementPage' },
    { label: '个人信息保护指引', route: 'pages/PrivacyGuidePage' },
    { label: '第三方信息数据共享', route: 'pages/ThirdPartyDataSharingPage' },
    { label: '证照中心', route: '' },
    { label: 'APP 备案编号', route: 'pages/AppFilingDetailPage' }
  ];

  onBack(): void {
    router.back();
  }

  onItemTap(item: AboutItem): void {
    if (item.route && item.route.length > 0) {
      router.pushUrl({ url: item.route });
    }
  }

  build() {
    Column() {
      // ── Top Navigation Bar ──
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor('#1A1A1A')
          .padding({ left: 4, right: 12, top: 8, bottom: 8 })
          .onClick(() => {
            this.onBack();
          })

        Text('关于知乎')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .layoutWeight(1)

        Text('⋯')
          .fontSize(22)
          .fontColor('#1A1A1A')
          .padding({ left: 12, right: 4, top: 8, bottom: 8 })
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#FFFFFF')
      .border({
        width: { bottom: 0.5 },
        color: '#E0E0E0'
      })

      // ── Content: List of items ──
      Scroll() {
        Column() {
          ForEach(this.items, (item: AboutItem, index: number) => {
            Row() {
              Text(item.label)
                .fontSize(16)
                .fontColor('#1A1A1A')
                .layoutWeight(1)

              Text('>')
                .fontSize(18)
                .fontColor('#C0C0C0')
            }
            .width('100%')
            .height(48)
            .padding({ left: 16, right: 16 })
            .backgroundColor('#FFFFFF')
            .onClick(() => {
              this.onItemTap(item);
            })

            if (index < this.items.length - 1) {
              Divider()
                .strokeWidth(0.5)
                .color('#E8E8E8')
                .margin({ left: 16 })
            }
          })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
