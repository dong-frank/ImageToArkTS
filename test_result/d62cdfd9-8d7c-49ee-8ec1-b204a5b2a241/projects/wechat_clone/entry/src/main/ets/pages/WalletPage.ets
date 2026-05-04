import router from '@ohos.router';

interface WalletListItemData {
  icon: string;
  primaryText: string;
  secondaryText: string;
  valueText: string;
  hasChevron: boolean;
}

@Entry
@Component
struct WalletPage {
  @State selectedTabIndex: number = 0;
  private tabLabels: string[] = ['钱包', '账单'];

  private accountItems: WalletListItemData[] = [
    {
      icon: '\u20BD',
      primaryText: '零钱',
      secondaryText: '',
      valueText: '\u00A5319.07',
      hasChevron: true
    },
    {
      icon: '\u25C7',
      primaryText: '零钱通',
      secondaryText: '\u6536\u76CA\u73871.00%',
      valueText: '\u00A50.00',
      hasChevron: true
    },
    {
      icon: '\u25A1',
      primaryText: '银行卡',
      secondaryText: '',
      valueText: '',
      hasChevron: true
    },
    {
      icon: '\u2661',
      primaryText: '亲属卡',
      secondaryText: '',
      valueText: '',
      hasChevron: true
    }
  ];

  private serviceItems: WalletListItemData[] = [
    {
      icon: '\u25B3',
      primaryText: '分付',
      secondaryText: '\u6D88\u8D39\u8F6C\u8D26\u53EF\u7528\uFF0C\u9996\u7B14\u514D\u606F45\u5929',
      valueText: '',
      hasChevron: true
    },
    {
      icon: '\u00A5',
      primaryText: '数字人民币',
      secondaryText: '',
      valueText: '',
      hasChevron: true
    },
    {
      icon: '\u2605',
      primaryText: '支付分',
      secondaryText: '',
      valueText: '',
      hasChevron: true
    },
    {
      icon: '\u266A',
      primaryText: '客服中心',
      secondaryText: '',
      valueText: '',
      hasChevron: true
    }
  ];

  private handleBack(): void {
    router.back();
  }

  private handleTabSwitch(index: number): void {
    if (index === this.selectedTabIndex) {
      return;
    }
    if (index === 0) {
      this.selectedTabIndex = index;
    } else if (index === 1) {
      this.selectedTabIndex = index;
    }
  }

  private handleItemTap(item: WalletListItemData): void {
    console.info(`[WalletPage] 点击列表项: ${item.primaryText}`);
  }

  private handleFooterLinkTap(label: string): void {
    console.info(`[WalletPage] 点击底部链接: ${label}`);
  }

  build() {
    Column() {
      // Header / Navigation Bar
      Row() {
        // Back button
        Text('<')
          .fontSize(20)
          .fontColor('#191919')
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.handleBack();
          })

        // Title
        Text('钱包')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#191919')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      }
      .width('100%')
      .height(44)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#EDEDED')

      // Tab Switcher
      Row() {
        ForEach(this.tabLabels, (label: string, index: number) => {
          Column({ space: 4 }) {
            Text(label)
              .fontSize(15)
              .fontWeight(this.selectedTabIndex === index ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.selectedTabIndex === index ? '#191919' : '#888888')
              .textAlign(TextAlign.Center)

            if (this.selectedTabIndex === index) {
              Divider()
                .width(24)
                .height(2)
                .color('#27AE60')
                .strokeWidth(2)
            } else {
              Divider()
                .width(24)
                .height(2)
                .color('transparent')
                .strokeWidth(2)
            }
          }
          .layoutWeight(1)
          .padding({ top: 8, bottom: 4 })
          .onClick(() => {
            this.handleTabSwitch(index);
          })
        })
      }
      .width('100%')
      .backgroundColor('#EDEDED')
      .padding({ left: 40, right: 40 })

      // Scrollable Content
      Scroll() {
        Column() {
          // Account section
          Column() {
            ForEach(this.accountItems, (item: WalletListItemData, index: number) => {
              this.ListItemRow(item)
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .padding({ top: 4, bottom: 4 })

          // Section divider
          Divider()
            .height(8)
            .color('#F5F5F5')
            .strokeWidth(8)

          // Service section
          Column() {
            ForEach(this.serviceItems, (item: WalletListItemData, index: number) => {
              this.ListItemRow(item)
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .padding({ top: 4, bottom: 4 })

          Divider()
            .height(8)
            .color('#F5F5F5')
            .strokeWidth(8)

          // Bottom spacer
          Column()
            .height(20)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')

      // Footer Links
      Row({ space: 0 }) {
        Text('身份信息')
          .fontSize(14)
          .fontColor('#576B95')
          .onClick(() => {
            this.handleFooterLinkTap('身份信息');
          })

        Text(' | ')
          .fontSize(14)
          .fontColor('#CCCCCC')

        Text('支付设置')
          .fontSize(14)
          .fontColor('#576B95')
          .onClick(() => {
            this.handleFooterLinkTap('支付设置');
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 12, bottom: 20 })
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  ListItemRow(item: WalletListItemData) {
    Row({ space: 12 }) {
      // Leading icon
      Text(item.icon)
        .fontSize(22)
        .fontColor('#4A4A4A')
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .backgroundColor('#F0F0F0')
        .borderRadius(4)

      // Text content
      Column({ space: 2 }) {
        Text(item.primaryText)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#191919')
          .maxLines(1)

        if (item.secondaryText && item.secondaryText.length > 0) {
          Text(item.secondaryText)
            .fontSize(13)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // Value text (right aligned)
      if (item.valueText && item.valueText.length > 0) {
        Text(item.valueText)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#191919')
          .maxLines(1)
      }

      // Chevron
      if (item.hasChevron) {
        Text('>')
          .fontSize(16)
          .fontColor('#CCCCCC')
          .width(16)
          .height(16)
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      this.handleItemTap(item);
    })
  }
}
