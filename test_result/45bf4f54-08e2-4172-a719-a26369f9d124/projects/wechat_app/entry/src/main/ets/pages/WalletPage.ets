import router from '@ohos.router';

@Entry
@Component
struct WalletPage {
  @State balance: string = '0.00';

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

        Text('钱包')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row() {
          Text('⋯')
            .fontSize(20)
            .fontColor('#333333')
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height(44)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#EDEDED')

      // Scrollable content
      Scroll() {
        Column() {
          // Balance Card
          Column() {
            Text('零钱')
              .fontSize(14)
              .fontColor('rgba(255, 255, 255, 0.8)')
            Text('¥ ' + this.balance)
              .fontSize(40)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
              .margin({ top: 12 })

            Row() {
              this.ActionChip('充值', () => {
                router.pushUrl({ url: 'pages/PhoneRechargePage' });
              })
              this.ActionChip('提现', () => {})
            }
            .margin({ top: 20 })
          }
          .width('100%')
          .height(200)
          .justifyContent(FlexAlign.Center)
          .borderRadius(12)
          .margin({ left: 16, right: 16, top: 16 })
          .linearGradient({
            angle: 135,
            colors: [
              ['#07C160', 0.0],
              ['#06AD56', 1.0]
            ]
          })

          // Quick Actions Grid
          Grid() {
            GridItem() {
              this.WalletActionItem('收付款', '💸')
            }
            GridItem() {
              this.WalletActionItem('零钱通', '🏦')
            }
            GridItem() {
              this.WalletActionItem('银行卡', '💳')
            }
            GridItem() {
              this.WalletActionItem('亲属卡', '👨‍👩‍👧')
            }
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .rowsGap(0)
          .columnsGap(0)
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ left: 16, right: 16, top: 16 })

          // Payment Services
          Column() {
            this.ListItem('支付分', '了解我的信用', '🟢')
            Divider().margin({ left: 56 })
            this.ListItem('支付设置', '管理支付方式', '⚙️')
            Divider().margin({ left: 56 })
            this.ListItem('实名认证', '已认证', '✅')
            Divider().margin({ left: 56 })
            this.ListItem('数字人民币', '开通数字钱包', '🪙')
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ left: 16, right: 16, top: 16 })

          // Financial Services
          Column() {
            this.ListItem('理财通', '余额+，工资理财', '📈')
            Divider().margin({ left: 56 })
            this.ListItem('微粒贷', '周转就找微粒贷', '💰')
            Divider().margin({ left: 56 })
            this.ListItem('保险服务', '健康意外险', '🛡️')
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ left: 16, right: 16, top: 16 })

          // Security
          Column() {
            this.ListItem('安全保障', '百万保障中', '🔒')
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ left: 16, right: 16, top: 16 })

          // Spacer
          Column().height(20)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ActionChip(label: string, onClick: () => void) {
    Text(label)
      .fontSize(14)
      .fontColor('#FFFFFF')
      .fontWeight(FontWeight.Medium)
      .width(80)
      .height(32)
      .textAlign(TextAlign.Center)
      .borderRadius(16)
      .backgroundColor('rgba(255, 255, 255, 0.25)')
      .margin({ left: 8, right: 8 })
      .onClick(() => {
        onClick();
      })
  }

  @Builder
  WalletActionItem(label: string, icon: string) {
    Column() {
      Text(icon)
        .fontSize(28)
        .width(48)
        .height(48)
        .borderRadius(10)
        .backgroundColor('#F7F7F7')
        .textAlign(TextAlign.Center)
      Text(label)
        .fontSize(13)
        .fontColor('#333333')
        .margin({ top: 8 })
    }
    .width('100%')
    .padding({ top: 16, bottom: 12 })
  }

  @Builder
  ListItem(title: string, desc: string, icon: string) {
    Row() {
      Text(icon)
        .fontSize(24)
        .width(40)
        .height(40)
        .borderRadius(10)
        .backgroundColor('#F7F7F7')
        .textAlign(TextAlign.Center)

      Column() {
        Text(title)
          .fontSize(15)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
        Text(desc)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      Blank()

      Text('›')
        .fontSize(18)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }
}
