import router from '@ohos.router';

interface ServiceItem {
  name: string;
  icon: string;
  route?: string;
}

@Entry
@Component
struct ServiceHomePage {
  @State selectedCity: string = '深圳';

  build() {
    Column() {
      // Header
      Row() {
        Text(this.selectedCity)
          .fontSize(17)
          .fontColor('#333333')
        Text('▼')
          .fontSize(10)
          .fontColor('#999999')
          .margin({ left: 4 })

        Blank()

        Text('服务')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Row().width(50)
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#EDEDED')

      // Scrollable content
      Scroll() {
        Column() {
          // Search bar
          Row() {
            Text('🔍')
              .fontSize(16)
              .margin({ left: 12 })
            Text('搜索服务')
              .fontSize(15)
              .fontColor('#B2B2B2')
              .margin({ left: 6 })
          }
          .width('100%')
          .height(36)
          .borderRadius(6)
          .backgroundColor('#EDEDED')
          .margin({ top: 12, left: 16, right: 16 })

          // Financial Services Section
          this.SectionTitle('金融理财')
          this.ServiceGrid([
            { name: '手机充值', icon: '💳', route: 'pages/PhoneRechargePage' } as ServiceItem,
            { name: '理财通', icon: '📈' } as ServiceItem,
            { name: '信用卡还款', icon: '💳' } as ServiceItem,
            { name: '微粒贷借钱', icon: '💰' } as ServiceItem,
            { name: '保险服务', icon: '🛡️' } as ServiceItem,
            { name: '京东购物', icon: '🛒' } as ServiceItem,
            { name: '美团外卖', icon: '🍱' } as ServiceItem,
            { name: '电影演出', icon: '🎬' } as ServiceItem,
          ])

          // Life Services Section
          this.SectionTitle('生活服务')
          this.ServiceGrid([
            { name: '生活缴费', icon: '💡', route: 'pages/LifePaymentPage' } as ServiceItem,
            { name: '城市服务', icon: '🏙️' } as ServiceItem,
            { name: '医疗健康', icon: '🏥' } as ServiceItem,
            { name: '交通出行', icon: '🚇' } as ServiceItem,
            { name: '汽车服务', icon: '🚗' } as ServiceItem,
            { name: '政务综合', icon: '📋' } as ServiceItem,
            { name: '义工旅行', icon: '✈️' } as ServiceItem,
            { name: '教育服务', icon: '📚' } as ServiceItem,
          ])

          // Featured Services Section
          this.SectionTitle('精选推荐')
          Column() {
            this.FeaturedItem('微信支付有优惠', '每周领取优惠福利', '🟢')
            Divider().margin({ left: 76 })
            this.FeaturedItem('微信豆', '直播打赏、内容付费', '💎')
            Divider().margin({ left: 76 })
            this.FeaturedItem('ETC助手', '高速通行不停车', '🚙')
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 16, right: 16, top: 8 })

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
  SectionTitle(title: string) {
    Text(title)
      .fontSize(15)
      .fontColor('#999999')
      .fontWeight(FontWeight.Medium)
      .margin({ left: 16, top: 20, bottom: 10 })
  }

  @Builder
  ServiceGrid(items: ServiceItem[]) {
    Grid() {
      ForEach(items, (item: ServiceItem, index: number) => {
        GridItem() {
          Column() {
            Text(item.icon)
              .fontSize(30)
              .width(44)
              .height(44)
              .borderRadius(10)
              .backgroundColor('#F0F0F0')
              .textAlign(TextAlign.Center)
            Text(item.name)
              .fontSize(12)
              .fontColor('#333333')
              .margin({ top: 6 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding({ top: 10, bottom: 6 })
          .onClick(() => {
            if (item.route) {
              router.pushUrl({ url: item.route });
            }
          })
        }
      })
    }
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .rowsGap(8)
    .columnsGap(0)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .padding({ top: 4, bottom: 4 })
    .margin({ left: 16, right: 16 })
  }

  @Builder
  FeaturedItem(title: string, desc: string, icon: string) {
    Row() {
      Text(icon)
        .fontSize(32)
        .width(44)
        .height(44)
        .borderRadius(10)
        .backgroundColor('#F0F0F0')
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
    .height(56)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }
}

