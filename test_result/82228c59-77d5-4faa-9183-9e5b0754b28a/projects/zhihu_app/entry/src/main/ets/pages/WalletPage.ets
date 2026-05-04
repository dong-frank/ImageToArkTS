import router from '@ohos.router';

interface TransactionItem {
  title: string;
  date: string;
  amount: string;
  type: string;
}

@Entry
@Component
struct WalletPage {
  @State balance: string = '128.50';
  @State saltBalance: string = '2,350';

  transactionList: TransactionItem[] = [
    { title: '盐选会员月卡续费', date: '2025-04-23', amount: '-25.00', type: 'expense' },
    { title: '盐粒奖励发放', date: '2025-04-20', amount: '+50', type: 'salt_income' },
    { title: '付费咨询收入', date: '2025-04-18', amount: '+88.00', type: 'income' },
    { title: '购买电子书', date: '2025-04-15', amount: '-12.90', type: 'expense' },
    { title: '活动红包', date: '2025-04-10', amount: '+15.00', type: 'income' },
  ];

  build() {
    Column() {
      // Status bar
      Row() {
        Text('15:17')
          .fontSize(12)
          .fontColor('#333333')
        Blank()
        Text('56%')
          .fontSize(12)
          .fontColor('#333333')
      }
      .width('100%')
      .height(28)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F5F5F5')

      // Navigation bar
      Row() {
        Text('<')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ right: 12 })
          .onClick(() => {
            router.back();
          })
        Text('钱包')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Blank()
        Text('明细')
          .fontSize(14)
          .fontColor('#0066FF')
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // Balance card
          Column() {
            Text('账户余额（元）')
              .fontSize(13)
              .fontColor('#999999')
              .margin({ bottom: 8 })
            Text(this.balance)
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ bottom: 16 })

            Row() {
              Text('充值')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .width(90)
                .height(36)
                .backgroundColor('#0066FF')
                .borderRadius(18)
                .textAlign(TextAlign.Center)
                .margin({ right: 12 })

              Text('提现')
                .fontSize(14)
                .fontColor('#0066FF')
                .width(90)
                .height(36)
                .backgroundColor('#E8F0FE')
                .borderRadius(18)
                .textAlign(TextAlign.Center)
            }
          }
          .width('100%')
          .padding({ top: 28, bottom: 24 })
          .backgroundColor('#FFFFFF')
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 8 })

          // Salt balance card
          Row() {
            Column() {
              Text('盐粒')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
              Text('可用于兑换会员和商品')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text(this.saltBalance)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF6600')
              .margin({ right: 8 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Quick actions grid
          Column() {
            Text('钱包服务')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .padding({ left: 16, top: 16, bottom: 12 })

            Row() {
              this.WalletAction('💰', '余额充值')
              this.WalletAction('💳', '银行卡')
            }
            .width('100%')
            .padding({ left: 12, right: 12 })

            Row() {
              this.WalletAction('🎫', '优惠券')
              this.WalletAction('📋', '账单查询')
            }
            .width('100%')
            .padding({ left: 12, right: 12 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Recent transactions
          Column() {
            Text('最近交易')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .padding({ left: 16, top: 16, bottom: 12 })

            ForEach(this.transactionList, (item: TransactionItem) => {
              this.TransactionRow(item);
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 8, bottom: 16 })
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  WalletAction(icon: string, label: string) {
    Column() {
      Text(icon)
        .fontSize(28)
        .width(52)
        .height(52)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .textAlign(TextAlign.Center)
      Text(label)
        .fontSize(12)
        .fontColor('#666666')
        .margin({ top: 8 })
    }
    .layoutWeight(1)
    .padding({ top: 8, bottom: 8 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  TransactionRow(item: TransactionItem) {
    Row() {
      Text(item.type === 'salt_income' ? '🧂' : (item.type === 'income' ? '📥' : '📤'))
        .fontSize(20)
        .width(36)
        .height(36)
        .backgroundColor('#F5F5F5')
        .borderRadius(18)
        .textAlign(TextAlign.Center)

      Column() {
        Text(item.title)
          .fontSize(14)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.date)
          .fontSize(11)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)

      Text(item.amount)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.type === 'income' || item.type === 'salt_income' ? '#00AA66' : '#333333')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .border({ width: { bottom: 0.5 }, color: '#F5F5F5' })
  }
}
