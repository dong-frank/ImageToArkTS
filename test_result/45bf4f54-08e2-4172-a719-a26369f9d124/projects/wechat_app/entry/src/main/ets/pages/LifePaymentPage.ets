import router from '@ohos.router';

@Entry
@Component
struct LifePaymentPage {
  @State cityName: string = '南京市';
  @State userName: string = '香*';
  @State recentCategory: string = '燃气费';
  @State recentAccount: string = '蒋** 20***';

  build() {
    Column() {
      // Top Navigation Bar
      Row() {
        Row() {
          Text('个人中心')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .opacity(0.9)
        }
        .onClick(() => {
          router.back();
        })

        Blank()

        Text('生活缴费')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')

        Blank()

        Text('⋯')
          .fontSize(22)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#07C160')

      // Scrollable Content
      Scroll() {
        Column() {
          // User Info Section
          Row() {
            Text(this.userName)
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')

            Blank()

            // Avatar placeholder
            Text('👤')
              .fontSize(22)
              .width(36)
              .height(36)
              .borderRadius(18)
              .backgroundColor('#E0E0E0')
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 12 })

          // Recent Payment Card
          Column() {
            Row() {
              // Category icon - flame/orange
              Text('🔥')
                .fontSize(28)
                .margin({ right: 12 })

              Column() {
                Text(this.recentCategory)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#333333')

                Text('轻触查询详情')
                  .fontSize(12)
                  .fontColor('#999999')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              Column() {
                Text(this.recentAccount)
                  .fontSize(12)
                  .fontColor('#999999')
                  .margin({ bottom: 4 })

                Text('›')
                  .fontSize(18)
                  .fontColor('#CCCCCC')
              }
              .alignItems(HorizontalAlign.End)
            }
            .width('100%')
            .padding(16)
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .padding({ left: 0, right: 0 })
          .margin({ left: 16, right: 16, top: 8, bottom: 8 })

          // Divider gap
          Row()
            .width('100%')
            .height(8)
            .backgroundColor('#F5F5F5')

          // New Payment Section
          Column() {
            // Section Header with city selector
            Row() {
              Text('新增缴费')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')

              Blank()

              Row() {
                Text(this.cityName)
                  .fontSize(13)
                  .fontColor('#666666')

                Text('▼')
                  .fontSize(8)
                  .fontColor('#666666')
                  .margin({ left: 2 })
              }
              .onClick(() => {
                // City selection logic placeholder
              })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 12 })

            // Payment Grid - 2 rows x 3 columns
            Grid() {
              GridItem() {
                this.PaymentItem('⚡', '电费')
              }

              GridItem() {
                this.PaymentItem('💧', '水费')
              }

              GridItem() {
                this.PaymentItem('🔥', '燃气费')
              }

              GridItem() {
                this.PaymentItem('📞', '固话费')
              }

              GridItem() {
                this.PaymentItem('📶', '宽带费')
              }

              GridItem() {
                this.PaymentItem('📺', '有线电视')
              }
            }
            .columnsTemplate('1fr 1fr 1fr')
            .rowsGap(0)
            .columnsGap(0)
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 16 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 16, right: 16, top: 8 })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  PaymentItem(icon: string, label: string) {
    Column() {
      Text(icon)
        .fontSize(32)
        .margin({ bottom: 8 })

      Text(label)
        .fontSize(13)
        .fontColor('#333333')
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      // Navigate to specific payment detail page
    })
  }
}
