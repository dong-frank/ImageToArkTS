import router from '@ohos.router';

interface PaymentCategory {
  icon: string;
  label: string;
}

@Entry
@Component
struct LifePaymentPage {
  private readonly paymentCategories: PaymentCategory[] = [
    { icon: '💧', label: '水费' },
    { icon: '⚡', label: '电费' },
    { icon: '🔥', label: '燃气费' },
    { icon: '📞', label: '固话' },
    { icon: '📡', label: '宽带' }
  ];

  private handleBack(): void {
    router.back();
  }

  private handleMore(): void {
    console.info('[LifePaymentPage] 更多菜单点击');
  }

  private handleCityTap(): void {
    console.info('[LifePaymentPage] 城市切换点击，当前：北京');
  }

  private handleAddPayment(): void {
    console.info('[LifePaymentPage] 新增缴费点击');
  }

  private handleQueryPayment(): void {
    console.info('[LifePaymentPage] 查询缴费点击');
  }

  private handleCategoryTap(category: PaymentCategory): void {
    console.info(`[LifePaymentPage] 缴费类型点击: ${category.label}`);
  }

  private handleAutoPayManage(): void {
    console.info('[LifePaymentPage] 自动缴费管理点击');
  }

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('<')
          .fontSize(20)
          .fontColor('#191919')
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.handleBack();
          })

        Row({ space: 4 }) {
          Text('北京')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#191919')
          Text('▼')
            .fontSize(10)
            .fontColor('#999999')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.handleCityTap();
        })

        Text('⋯')
          .fontSize(22)
          .fontColor('#191919')
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.handleMore();
          })
      }
      .width('100%')
      .height(44)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#EDEDED')

      Scroll() {
        Column() {
          // Hero banner
          Column({ space: 4 }) {
            Text('生活缴费')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text('足不出户，轻松缴费')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.85)')
          }
          .width('100%')
          .height(120)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#07C160')
          .borderRadius(0)

          // Quick actions section
          Column({ space: 12 }) {
            // 新增缴费 card
            Column() {
              Row({ space: 12 }) {
                Text('➕')
                  .fontSize(20)
                  .fontColor('#07C160')
                Text('新增缴费')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#191919')
                  .layoutWeight(1)
                Text('〉')
                  .fontSize(14)
                  .fontColor('#C0C0C0')
              }
              .width('100%')
              .height(48)
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                this.handleAddPayment();
              })

              Divider()
                .color('#F0F0F0')
                .strokeWidth(1)
                .margin({ left: 16, right: 16 })

              // Category grid
              Grid() {
                ForEach(this.paymentCategories, (item: PaymentCategory) => {
                  GridItem() {
                    Column({ space: 6 }) {
                      Text(item.icon)
                        .fontSize(28)
                      Text(item.label)
                        .fontSize(12)
                        .fontColor('#666666')
                    }
                    .width('100%')
                    .padding({ top: 12, bottom: 12 })
                    .justifyContent(FlexAlign.Center)
                    .onClick(() => {
                      this.handleCategoryTap(item);
                    })
                  }
                })
              }
              .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
              .rowsGap(4)
              .columnsGap(4)
              .padding({ top: 8, bottom: 8, left: 8, right: 8 })
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(12)

            // 查询缴费 card
            Row({ space: 12 }) {
              Text('🔍')
                .fontSize(20)
              Column({ space: 2 }) {
                Text('查询缴费')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#191919')
                Text('输入户号')
                  .fontSize(12)
                  .fontColor('#999999')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text('〉')
                .fontSize(14)
                .fontColor('#C0C0C0')
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .onClick(() => {
              this.handleQueryPayment();
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 12 })

          // Auto payment section
          Column() {
            // Section header
            Row() {
              Text('自动缴费')
                .fontSize(13)
                .fontColor('#999999')
                .padding({ left: 16, right: 16 })
            }
            .width('100%')
            .padding({ top: 16, bottom: 8 })

            // 自动缴费管理 entry
            Row({ space: 12 }) {
              Text('自动缴费管理')
                .fontSize(16)
                .fontColor('#191919')
                .layoutWeight(1)
              Text('〉')
                .fontSize(14)
                .fontColor('#C0C0C0')
            }
            .width('100%')
            .height(48)
            .padding({ left: 16, right: 16 })
            .backgroundColor('#FFFFFF')
            .onClick(() => {
              this.handleAutoPayManage();
            })
          }
          .width('100%')

          // Bottom spacing
          Column()
            .height(24)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
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
