import router from '@ohos.router';

// SDK data model
interface SdkItem {
  company: string;
  sdkName: string;
  personalInfo: string;
  purpose: string;
  sharingMethod: string;
  privacyLink: string;
}

@Entry
@Component
struct ThirdPartySdkList {
  private introText: string =
    '为保障大众点评App相关功能的实现与应用的稳定运行，我们可能会接入由第三方提供的软件开发包（SDK）以实现相关目的。' +
    '不同设备系统（如IOS、Android、HarmonyOS等）的第三方SDK会有所不同，一般包括一键登录类、第三方账号登录类、' +
    '推送通知消息类、第三方支付类、地图导航类、厂商推送类、分享类、统计类等。' +
    '我们会对合作方获取信息的软件工具开发包（SDK）进行严格的安全监测，以保障数据安全。' +
    '您可以通过以下链接查看第三方的数据使用和保护规则。';

  private sdkItems: SdkItem[] = [
    {
      company: '中移互联网有限公司',
      sdkName: '号码认证SDK',
      personalInfo: '网络类型、网络地址（ip地址）、运营商类型、本机号码信息、SIM卡状态、手机设备类型、手机操作系统、硬件厂商',
      purpose: '根据用户选择，为用户提供一键登录功能',
      sharingMethod: 'SDK本机采集',
      privacyLink: 'https://wap.cmppassport.com/resource/html/contract.html'
    }
  ];

  // Table column headers
  private columns: string[] = [
    '第三方公司名称',
    'SDK名称',
    '涉及个人信息',
    '使用目的',
    '共享方式',
    '第三方链接'
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

        Text('大众点评与第三方共享个人信息清单')
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
          // Sub-heading
          Text('大众点评App内嵌SDK名单')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .padding({ top: 20, bottom: 12, left: 16, right: 16 })

          // Intro paragraph
          Text(this.introText)
            .fontSize(14)
            .fontColor('#666666')
            .lineHeight(22)
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 20 })

          // SDK Table
          Column() {
            // Table header row
            Row() {
              ForEach(this.columns, (col: string, colIndex: number) => {
                Text(col)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#999999')
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
                  .padding({ top: 10, bottom: 10, left: 4, right: 4 })
              })
            }
            .width('100%')
            .backgroundColor('#F5F5F5')

            // Divider after header
            Divider()
              .color('#E8E8E8')
              .strokeWidth(0.5)

            // Table data rows
            ForEach(this.sdkItems, (item: SdkItem, rowIndex: number) => {
              Column() {
                Row() {
                  Text(item.company)
                    .fontSize(12)
                    .fontColor('#333333')
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                    .padding({ top: 10, bottom: 10, left: 4, right: 4 })

                  Text(item.sdkName)
                    .fontSize(12)
                    .fontColor('#333333')
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                    .padding({ top: 10, bottom: 10, left: 4, right: 4 })

                  Text(item.personalInfo)
                    .fontSize(11)
                    .fontColor('#333333')
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                    .padding({ top: 10, bottom: 10, left: 4, right: 4 })
                    .maxLines(4)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(item.purpose)
                    .fontSize(12)
                    .fontColor('#333333')
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                    .padding({ top: 10, bottom: 10, left: 4, right: 4 })

                  Text(item.sharingMethod)
                    .fontSize(12)
                    .fontColor('#333333')
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                    .padding({ top: 10, bottom: 10, left: 4, right: 4 })

                  Text('隐私政策 >')
                    .fontSize(12)
                    .fontColor('#2B7BD6')
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                    .padding({ top: 10, bottom: 10, left: 4, right: 4 })
                    .onClick(() => {
                      // External privacy policy link - target page not covered in current page set
                      // Log for now; unresolved navigation action per design
                      console.info('[ThirdPartySdkList] 隐私政策链接被点击: ' + item.privacyLink);
                    })
                }
                .width('100%')

                // Row divider
                if (rowIndex < this.sdkItems.length - 1) {
                  Divider()
                    .color('#F0F0F0')
                    .strokeWidth(0.5)
                }
              }
              .width('100%')
            })
          }
          .width('100%')
          .margin({ left: 16, right: 16 })
          .border({ width: 0.5, color: '#E8E8E8' })
          .borderRadius(4)
          .clip(true)

          // Bottom spacing
          Column()
            .height(24)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
