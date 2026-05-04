import router from '@ohos.router';

interface AmountItem {
  value: number;
  price: number;
}

@Entry
@Component
struct PhoneRechargePage {
  @State phoneNumber: string = '';
  @State selectedAmount: number = 50;
  @State selectedIndex: number = 0;

  private amounts: AmountItem[] = [
    { value: 30, price: 29.8 } as AmountItem,
    { value: 50, price: 49.6 } as AmountItem,
    { value: 100, price: 99.3 } as AmountItem,
    { value: 200, price: 198.8 } as AmountItem,
  ];

  private recentNumbers: string[] = ['138****8888', '139****6666'];

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

        Text('手机充值')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('记录')
          .fontSize(14)
          .fontColor('#07C160')
          .margin({ right: 8 })
      }
      .width('100%')
      .height(44)
      .padding({ left: 8, right: 16 })
      .backgroundColor('#EDEDED')

      // Scrollable content
      Scroll() {
        Column() {
          // Phone number input area
          Column() {
            Text('手机号码')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 24 })

            Row() {
              TextInput({ placeholder: '请输入手机号码', text: this.phoneNumber })
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .maxLength(11)
                .type(InputType.PhoneNumber)
                .placeholderColor('#CCCCCC')
                .placeholderFont({ size: 20, weight: FontWeight.Normal })
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
                .onChange((value: string) => {
                  this.phoneNumber = value;
                })

              Text('👤')
                .fontSize(22)
                .margin({ right: 8 })
            }
            .width('100%')
            .margin({ top: 12 })

            Divider()
              .width('100%')
              .color('#E0E0E0')
              .margin({ top: 8 })
          }
          .width('100%')
          .padding({ left: 24, right: 24 })
          .backgroundColor(Color.White)

          // Recent numbers
          if (this.recentNumbers.length > 0) {
            Column() {
              Text('最近充值')
                .fontSize(13)
                .fontColor('#999999')
                .margin({ left: 24, top: 12, bottom: 8 })

              ForEach(this.recentNumbers, (num: string) => {
                Row() {
                  Text(num)
                    .fontSize(15)
                    .fontColor('#333333')
                    .layoutWeight(1)

                  Text('充值')
                    .fontSize(13)
                    .fontColor('#07C160')
                    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                    .border({ width: 1, color: '#07C160', style: BorderStyle.Solid })
                    .borderRadius(12)
                }
                .width('100%')
                .padding({ left: 24, right: 24, top: 10, bottom: 10 })
                .onClick(() => {
                  this.phoneNumber = num;
                })
              })
            }
            .width('100%')
            .backgroundColor(Color.White)
          }

          // Recharge Amount Selection
          Column() {
            Text('选择面额')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ left: 24, top: 16, bottom: 12 })

            Grid() {
              ForEach(this.amounts, (item: AmountItem, index: number) => {
                GridItem() {
                  Column() {
                    Text('¥' + item.value.toString())
                      .fontSize(22)
                      .fontColor(this.selectedIndex === index ? '#FFFFFF' : '#333333')
                      .fontWeight(FontWeight.Bold)
                    Text('售价 ¥' + item.price.toFixed(1))
                      .fontSize(11)
                      .fontColor(this.selectedIndex === index ? 'rgba(255,255,255,0.8)' : '#999999')
                      .margin({ top: 4 })
                  }
                  .width('100%')
                  .height(70)
                  .justifyContent(FlexAlign.Center)
                  .borderRadius(8)
                  .backgroundColor(this.selectedIndex === index ? '#07C160' : '#F7F7F7')
                  .border({
                    width: this.selectedIndex === index ? 0 : 1,
                    color: '#E8E8E8',
                    style: BorderStyle.Solid
                  })
                  .onClick(() => {
                    this.selectedIndex = index;
                    this.selectedAmount = item.value;
                  })
                }
              })
            }
            .columnsTemplate('1fr 1fr')
            .rowsGap(10)
            .columnsGap(10)
            .width('100%')
            .padding({ left: 24, right: 24 })
          }
          .width('100%')
          .backgroundColor(Color.White)
          .padding({ bottom: 16 })

          // Special Offers
          Column() {
            Text('专属优惠')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ left: 24, top: 16, bottom: 10 })

            Row() {
              Column() {
                Text('🎁')
                  .fontSize(32)
                Text('首充立减')
                  .fontSize(12)
                  .fontColor('#333333')
                  .margin({ top: 4 })
                Text('新用户专享')
                  .fontSize(10)
                  .fontColor('#999999')
              }
              .width('45%')
              .height(80)
              .justifyContent(FlexAlign.Center)
              .borderRadius(8)
              .backgroundColor('#FFF7E6')

              Column() {
                Text('🎫')
                  .fontSize(32)
                Text('满100减5')
                  .fontSize(12)
                  .fontColor('#333333')
                  .margin({ top: 4 })
                Text('限时优惠')
                  .fontSize(10)
                  .fontColor('#999999')
              }
              .width('45%')
              .height(80)
              .justifyContent(FlexAlign.Center)
              .borderRadius(8)
              .backgroundColor('#E6F7FF')
              .margin({ left: 10 })
            }
            .width('100%')
            .padding({ left: 24, right: 24 })
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .width('100%')
          .backgroundColor(Color.White)
          .padding({ bottom: 16 })

          // Spacer
          Column().height(100)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')

      // Bottom Pay Button
      Row() {
        Column() {
          Text('合计')
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.8)')
          Text('¥' + this.amounts[this.selectedIndex].price.toFixed(1))
            .fontSize(20)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
        }
        .margin({ left: 20 })

        Blank()

        Text('立即充值')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
          .width(160)
          .height(44)
          .textAlign(TextAlign.Center)
          .borderRadius(22)
          .backgroundColor('rgba(255, 255, 255, 0.3)')
          .margin({ right: 20 })
          .onClick(() => {
            if (this.phoneNumber.length === 0) {
              // Would show toast in real app
              return;
            }
            // Payment flow would go here
          })
      }
      .width('100%')
      .height(64)
      .backgroundColor('#07C160')
    }
    .width('100%')
    .height('100%')
  }
}
