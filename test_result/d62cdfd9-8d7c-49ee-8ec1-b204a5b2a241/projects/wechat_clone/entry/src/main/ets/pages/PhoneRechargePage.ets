import router from '@ohos.router';

interface AmountItem {
  label: string;
}

@Entry
@Component
struct PhoneRechargePage {
  @State phoneNumber: string = '';
  @State selectedAmount: string = '';

  private readonly amounts: AmountItem[] = [
    { label: '50元' },
    { label: '100元' },
    { label: '200元' },
    { label: '300元' },
    { label: '500元' }
  ];

  private handleBack(): void {
    router.back();
  }

  private handleMore(): void {
    console.info('[PhoneRechargePage] 更多菜单点击');
  }

  private handleCircleAction(): void {
    console.info('[PhoneRechargePage] 圆圈图标点击');
  }

  private handleAmountTap(label: string): void {
    this.selectedAmount = label;
    console.info(`[PhoneRechargePage] 选择金额: ${label}`);
  }

  private handleFlowPackageTap(): void {
    console.info('[PhoneRechargePage] 特惠流量包点击');
  }

  private handleMoreServices(): void {
    console.info('[PhoneRechargePage] 更多服务点击');
  }

  build() {
    Column() {
      // ===== Green Top Bar =====
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#FFFFFF')
          .width(40)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.handleBack();
          })

        Text('手机充值')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

        Row({ space: 16 }) {
          Text('⋯')
            .fontSize(22)
            .fontColor('#FFFFFF')
            .width(32)
            .height(44)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.handleMore();
            })

          Text('◎')
            .fontSize(20)
            .fontColor('#FFFFFF')
            .width(32)
            .height(44)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.handleCircleAction();
            })
        }
        .padding({ right: 4 })
      }
      .width('100%')
      .height(48)
      .padding({ left: 4, right: 8 })
      .backgroundColor('#27AE60')

      // ===== Scrollable Content =====
      Scroll() {
        Column() {
          // ===== Phone Input Card =====
          Column() {
            Row({ space: 8 }) {
              Text('📱')
                .fontSize(20)

              TextInput({ placeholder: '请输入手机号码', text: this.phoneNumber })
                .placeholderColor('#BBBBBB')
                .fontSize(16)
                .fontColor('#333333')
                .backgroundColor(Color.Transparent)
                .height(44)
                .layoutWeight(1)
                .border({ width: 0 })
                .onChange((value: string) => {
                  this.phoneNumber = value;
                })

              Text('✏️')
                .fontSize(18)
                .fontColor('#999999')
            }
            .width('100%')
            .height(48)
            .padding({ left: 16, right: 16 })

            // Green bottom border line
            Divider()
              .height(1)
              .color('#27AE60')
              .strokeWidth(1.5)
              .margin({ left: 16, right: 16 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .padding({ top: 8, bottom: 8 })

          // ===== Section: 充话费 =====
          Column() {
            // Section title
            Row() {
              Text('充话费')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#999999')
                .padding({ left: 4 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 20, bottom: 10 })

            // Amount grid in white card
            Column() {
              Grid() {
                ForEach(this.amounts, (item: AmountItem, index: number) => {
                  GridItem() {
                    Column() {
                      Text(item.label)
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.selectedAmount === item.label ? '#FFFFFF' : '#333333')
                    }
                    .width('100%')
                    .height(48)
                    .justifyContent(FlexAlign.Center)
                    .borderRadius(6)
                    .backgroundColor(this.selectedAmount === item.label ? '#27AE60' : '#F5F5F5')
                    .onClick(() => {
                      this.handleAmountTap(item.label);
                    })
                  }
                })
              }
              .columnsTemplate('1fr 1fr 1fr')
              .rowsGap(10)
              .columnsGap(10)
              .width('100%')
              .padding(12)
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .padding({ left: 16, right: 16 })
          }
          .width('100%')

          // ===== Section: 充流量 =====
          Column() {
            // Section title
            Row() {
              Text('充流量')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#999999')
                .padding({ left: 4 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 20, bottom: 10 })

            // Flow package card
            Column() {
              Row({ space: 12 }) {
                Column() {
                  Text('📦')
                    .fontSize(28)
                }
                .width(48)
                .height(48)
                .justifyContent(FlexAlign.Center)
                .borderRadius(8)
                .backgroundColor('#E8F5E9')

                Column({ space: 2 }) {
                  Text('特惠流量包')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')

                  Text('超值流量，即充即用')
                    .fontSize(12)
                    .fontColor('#999999')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding(12)
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .onClick(() => {
              this.handleFlowPackageTap();
            })
            .padding({ left: 16, right: 16 })
          }
          .width('100%')

          // ===== Bottom: More Services =====
          Row({ space: 6 }) {
            Text('⊞')
              .fontSize(18)
              .fontColor('#27AE60')

            Text('更多服务')
              .fontSize(14)
              .fontColor('#27AE60')
          }
          .width('100%')
          .height(48)
          .justifyContent(FlexAlign.Center)
          .margin({ top: 24, bottom: 24, left: 16, right: 16 })
          .borderRadius(8)
          .backgroundColor('#FFFFFF')
          .onClick(() => {
            this.handleMoreServices();
          })

          // Bottom safe area spacing
          Column()
            .height(32)
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
