import router from '@ohos.router';

class OrderData {
  statusTag: string = '';
  productIcon: string = '';
  title: string = '';
  priceInfo: string = '';
  time: string = '';
  subtext: string = '';
  actions: string[] = [];

  constructor(statusTag: string, productIcon: string, title: string, priceInfo: string, time: string, subtext: string, actions: string[]) {
    this.statusTag = statusTag;
    this.productIcon = productIcon;
    this.title = title;
    this.priceInfo = priceInfo;
    this.time = time;
    this.subtext = subtext;
    this.actions = actions;
  }
}

@Entry
@Component
struct OrderListPage {
  @State selectedTab: number = 0;
  @State showPromoBanner: boolean = true;
  private tabs: string[] = ['全部订单', '待付款', '可使用', '退款/售后'];

  private orders: OrderData[] = [
    new OrderData('已成交', '🎫', '100元代金券', '1张 | 实付 ¥78.0', '下单时间：2025-12-05 19:17', '', ['删除', '再来一单', '发笔记']),
    new OrderData('已成交', '🎫', '矮子馅饼混合12个装9种口味选6种', '1张 | 实付 ¥13.8', '下单时间：2025-11-30 15:59', '', ['删除', '再来一单', '发笔记']),
    new OrderData('已就餐', '🍽️', '岭南说粥底火锅 (万达茂店)', '', '2025-11-23(星期日)17:29', 'B37|3人就餐', ['删除']),
    new OrderData('支付成功', '🍣', '鮨鸟歡・烧鸟yakitori', '消费 ¥206.00 实付 ¥177.00', '10-24 17:32', '', []),
  ];

  build() {
    Column() {
      // Top bar
      this.TopBar()

      // Tab bar
      this.TabBar()

      // Promo banner
      if (this.showPromoBanner) {
        this.PromoBanner()
      }

      // Order list
      List() {
        ForEach(this.orders, (order: OrderData, index: number) => {
          ListItem() {
            this.OrderCard(order)
          }
          .margin({ top: index === 0 ? 0 : 8 })
        })
      }
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  TopBar() {
    Row() {
      Text('←')
        .fontSize(22)
        .fontColor('#333333')
        .onClick(() => {
          router.back();
        })

      // Search bar
      Row() {
        Text('🔍')
          .fontSize(14)
          .fontColor('#999999')
        Text('搜索我的订单')
          .fontSize(14)
          .fontColor('#CCCCCC')
          .margin({ left: 6 })
      }
      .layoutWeight(1)
      .height(32)
      .backgroundColor('#F0F0F0')
      .borderRadius(16)
      .padding({ left: 12 })
      .margin({ left: 10, right: 10 })

      // Dropdown
      Row() {
        Text('全部分类')
          .fontSize(13)
          .fontColor('#666666')
        Text('▼')
          .fontSize(10)
          .fontColor('#999999')
          .margin({ left: 4 })
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  TabBar() {
    Row() {
      ForEach(this.tabs, (tab: string, index: number) => {
        Text(tab)
          .fontSize(14)
          .fontColor(this.selectedTab === index ? '#FF6600' : '#666666')
          .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Normal)
          .padding({ bottom: 8 })
          .border({
            width: { bottom: this.selectedTab === index ? 2 : 0 },
            color: this.selectedTab === index ? '#FF6600' : 'transparent'
          })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.selectedTab = index;
          })
      })
    }
    .width('100%')
    .height(44)
    .backgroundColor('#FFFFFF')
    .padding({ left: 8, right: 8 })
  }

  @Builder
  PromoBanner() {
    Row() {
      Column() {
        Text('免费领神券')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6600')
        Text('吃喝玩乐都能用 下单一省再省')
          .fontSize(12)
          .fontColor('#FF9966')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('立即领取')
        .fontSize(13)
        .fontColor('#FFFFFF')
        .backgroundColor('#FF6600')
        .borderRadius(14)
        .padding({ left: 14, right: 14, top: 6, bottom: 6 })

      Text('✕')
        .fontSize(16)
        .fontColor('#CCCCCC')
        .margin({ left: 10 })
        .onClick(() => {
          this.showPromoBanner = false;
        })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
    .backgroundColor('#FFF8F0')
    .margin({ top: 1 })
  }

  @Builder
  OrderCard(order: OrderData) {
    Column() {
      // Status tag row
      Row() {
        Text(order.statusTag)
          .fontSize(13)
          .fontColor('#FF6600')
          .fontWeight(FontWeight.Medium)

        Blank()

        if (order.actions.length > 0) {
          ForEach(order.actions, (action: string) => {
            Text(action)
              .fontSize(12)
              .fontColor('#666666')
              .border({
                width: 0.5,
                color: '#DDDDDD',
                radius: 12
              })
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ left: 8 })
          })
        }
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12 })

      // Order content
      Row() {
        Text(order.productIcon)
          .fontSize(36)
          .width(56)
          .height(56)
          .textAlign(TextAlign.Center)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)

        Column() {
          Text(order.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (order.priceInfo !== '') {
            Text(order.priceInfo)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 4 })
          }

          if (order.subtext !== '') {
            Text(order.subtext)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 2 })
          }

          Text(order.time)
            .fontSize(11)
            .fontColor('#BBBBBB')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 10 })
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 14 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }
}
