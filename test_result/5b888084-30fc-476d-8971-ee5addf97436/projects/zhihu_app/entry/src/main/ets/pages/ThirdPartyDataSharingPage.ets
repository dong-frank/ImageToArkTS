import { router } from '@kit.ArkUI';

interface TableRowData {
  companyName: string;
  productType: string;
  sharedInfo: string;
  purpose: string;
  scenario: string;
  sharingMethod: string;
  privacyRuleText: string;
}

@Entry
@Component
struct ThirdPartyDataSharingPage {
  private tableRows: TableRowData[] = [
    {
      companyName: '中国移动通信集团有限公司',
      productType: '中国移动认证精准触达SDK',
      sharedInfo: '网络类型、网络地址（ip地址）、运营商类型、本机号码信息；设备类型（型号）、操作系统、硬件',
      purpose: '移动手机号码一键登录、移动用户活跃',
      scenario: '在用户使用移动手机号码登录时使用',
      sharingMethod: 'SDK本机采集',
      privacyRuleText: '认证服务：https://wap.cmpassport.com/resources/html/contract.html\n精准触达：https://wap.cmpassport.com/resources'
    }
  ];

  onBack(): void {
    router.back();
  }

  onOverflowMenu(): void {
    // Overflow menu placeholder: could show share / copy / feedback options
  }

  onUrlTap(url: string): void {
    // External link - open in browser/WebView
    console.info('URL tapped: ' + url);
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

        Text('与第三方共享个人信息清单')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('⋯')
          .fontSize(22)
          .fontColor('#1A1A1A')
          .padding({ left: 12, right: 4, top: 8, bottom: 8 })
          .onClick(() => {
            this.onOverflowMenu();
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#FFFFFF')
      .border({
        width: { bottom: 0.5 },
        color: '#E0E0E0'
      })

      // ── Scrollable Content ──
      Scroll() {
        Column() {
          // ── Section Header ──
          Text('与第三方共享个人信息清单')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .margin({ top: 24, bottom: 20 })

          // ── Data Table (horizontally scrollable for 7 columns) ──
          Scroll() {
            Column() {
              // Table header row
              Row() {
                Text('第三方公司名称')
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#666666')
                  .width(90)
                  .textAlign(TextAlign.Center)
                Text('产品/类型')
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#666666')
                  .width(80)
                  .textAlign(TextAlign.Center)
                Text('共享信息名称')
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#666666')
                  .width(100)
                  .textAlign(TextAlign.Center)
                Text('使用目的')
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#666666')
                  .width(80)
                  .textAlign(TextAlign.Center)
                Text('使用场景')
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#666666')
                  .width(80)
                  .textAlign(TextAlign.Center)
                Text('共享方式')
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#666666')
                  .width(70)
                  .textAlign(TextAlign.Center)
                Text('第三方个人信息\n处理规则')
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#666666')
                  .width(120)
                  .textAlign(TextAlign.Center)
              }
              .padding({ top: 12, bottom: 12 })
              .backgroundColor('#F5F5F5')
              .border({
                width: { top: 1, bottom: 1 },
                color: '#E0E0E0'
              })

              // Table data rows
              ForEach(this.tableRows, (row: TableRowData, rowIndex: number) => {
                Row() {
                  Text(row.companyName)
                    .fontSize(12)
                    .fontColor('#1A1A1A')
                    .width(90)
                    .padding(4)
                  Text(row.productType)
                    .fontSize(12)
                    .fontColor('#1A1A1A')
                    .width(80)
                    .padding(4)
                  Text(row.sharedInfo)
                    .fontSize(12)
                    .fontColor('#1A1A1A')
                    .width(100)
                    .padding(4)
                  Text(row.purpose)
                    .fontSize(12)
                    .fontColor('#1A1A1A')
                    .width(80)
                    .padding(4)
                  Text(row.scenario)
                    .fontSize(12)
                    .fontColor('#1A1A1A')
                    .width(80)
                    .padding(4)
                  Text(row.sharingMethod)
                    .fontSize(12)
                    .fontColor('#1A1A1A')
                    .width(70)
                    .padding(4)
                    .textAlign(TextAlign.Center)
                  Column() {
                    Text(row.privacyRuleText)
                      .fontSize(12)
                      .fontColor('#0055CC')
                      .width('100%')
                  }
                  .width(120)
                  .padding(4)
                  .onClick(() => {
                    this.onUrlTap(row.privacyRuleText);
                  })
                }
                .padding({ top: 10, bottom: 10 })
                .backgroundColor('#FFFFFF')
                .alignItems(VerticalAlign.Top)

                // Row divider
                if (rowIndex < this.tableRows.length - 1) {
                  Divider()
                    .strokeWidth(0.5)
                    .color('#E8E8E8')
                }
              })
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.On)
          .border({
            width: { bottom: 1 },
            color: '#E0E0E0'
          })
          .margin({ bottom: 32 })

          // ── Subsection "内嵌 SDK 名单" ──
          Text('内嵌 SDK 名单')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .margin({ bottom: 16 })

          // SDK list items
          ForEach(this.tableRows, (row: TableRowData, rowIndex: number) => {
            Column() {
              Row() {
                Text('•  ')
                  .fontSize(14)
                  .fontColor('#1A1A1A')
                Text(row.productType)
                  .fontSize(14)
                  .fontColor('#1A1A1A')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 8 })

              Row() {
                Text('  公司：')
                  .fontSize(13)
                  .fontColor('#666666')
                Text(row.companyName)
                  .fontSize(13)
                  .fontColor('#1A1A1A')
              }
              .width('100%')
              .margin({ bottom: 4 })

              Row() {
                Text('  共享信息：')
                  .fontSize(13)
                  .fontColor('#666666')
                Text(row.sharedInfo)
                  .fontSize(13)
                  .fontColor('#1A1A1A')
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 4 })

              Row() {
                Text('  使用目的：')
                  .fontSize(13)
                  .fontColor('#666666')
                Text(row.purpose)
                  .fontSize(13)
                  .fontColor('#1A1A1A')
              }
              .width('100%')
              .margin({ bottom: 4 })

              Row() {
                Text('  使用场景：')
                  .fontSize(13)
                  .fontColor('#666666')
                Text(row.scenario)
                  .fontSize(13)
                  .fontColor('#1A1A1A')
              }
              .width('100%')
              .margin({ bottom: 4 })

              Row() {
                Text('  共享方式：')
                  .fontSize(13)
                  .fontColor('#666666')
                Text(row.sharingMethod)
                  .fontSize(13)
                  .fontColor('#1A1A1A')
              }
              .width('100%')
              .margin({ bottom: 4 })

              Text('  处理规则：')
                .fontSize(13)
                .fontColor('#666666')
                .width('100%')
                .margin({ bottom: 2 })
              Text(row.privacyRuleText)
                .fontSize(13)
                .fontColor('#0055CC')
                .width('100%')
                .margin({ bottom: 2 })
                .onClick(() => {
                  this.onUrlTap(row.privacyRuleText);
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FAFAFA')
            .borderRadius(8)
            .border({
              width: 0.5,
              color: '#E8E8E8'
            })
            .margin({ bottom: 16 })
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 32 })
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
