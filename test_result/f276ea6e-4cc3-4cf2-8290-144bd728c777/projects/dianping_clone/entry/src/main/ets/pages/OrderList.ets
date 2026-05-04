import router from '@ohos.router';

// --- Data Models ---

interface OrderItem {
  name: string;
  quantity: string;
}

interface OrderCardData {
  merchant: string;
  status: string;
  amount: string;
  items: OrderItem[];
  actions: string[];
  statusColor: string;
}

interface StatusTabItem {
  label: string;
  selected: boolean;
}

// --- Mock Data ---

const STATUS_TABS: StatusTabItem[] = [
  { label: '全部订单', selected: true },
  { label: '待付款', selected: false },
  { label: '可使用', selected: false },
  { label: '退款', selected: false },
  { label: '售后', selected: false }
];

const MOCK_ORDERS: OrderCardData[] = [
  {
    merchant: '王和李·海鲜火锅大排档 (美糖广场店)',
    status: '待付款',
    amount: '¥298',
    items: [{ name: '海鲜火锅套餐', quantity: '×1' }],
    actions: ['去支付', '取消订单'],
    statusColor: '#FF6B35'
  },
  {
    merchant: '开云 (仙林美糖庄)',
    status: '已完成',
    amount: '¥156',
    items: [{ name: '双人下午茶', quantity: '×1' }],
    actions: ['再来一单', '评价'],
    statusColor: '#999999'
  },
  {
    merchant: '杨天歌冒菜·麻辣香锅 (仙林店)',
    status: '已完成',
    amount: '¥85',
    items: [{ name: '冒菜双人套餐', quantity: '×1' }],
    actions: ['再来一单', '评价'],
    statusColor: '#999999'
  },
  {
    merchant: '鮨鸟歡·烧鸟 yakitori',
    status: '已完成',
    amount: '¥177',
    items: [{ name: '烧鸟套餐', quantity: '×1' }],
    actions: ['再来一单', '评价'],
    statusColor: '#999999'
  },
  {
    merchant: '海鸿兴·品味江南 (万达茂)',
    status: '退款中',
    amount: '¥95',
    items: [{ name: '淮扬菜套餐', quantity: '×1' }],
    actions: ['查看详情'],
    statusColor: '#FF6B35'
  }
];

// --- Component ---

@Entry
@Component
struct OrderList {
  @State selectedTabIndex: number = 0;
  @State categoryExpanded: boolean = false;
  @State currentCategory: string = '全部订单';
  @State orderList: OrderCardData[] = MOCK_ORDERS;

  build() {
    Column() {
      // --- Title Bar ---
      Row() {
        // Back button
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ left: 4, right: 12, top: 4, bottom: 4 })
          .onClick(() => {
            router.back();
          })

        // Title
        Text('全部订单')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .layoutWeight(1)

        // Search icon
        Text('🔍')
          .fontSize(20)
          .padding({ left: 12, right: 4, top: 4, bottom: 4 })
          .onClick(() => {
            // Search orders - unresolved target, placeholder
            console.info('[OrderList] Search tapped - search order');
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // --- Category Dropdown ---
      Row() {
        Text(this.currentCategory)
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)

        Text(this.categoryExpanded ? '▲' : '▼')
          .fontSize(10)
          .fontColor('#999999')
          .margin({ left: 4 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor('#FFFFFF')
      .onClick(() => {
        // Same-page filter toggle - not navigation
        this.categoryExpanded = !this.categoryExpanded;
        console.info('[OrderList] Category dropdown toggled');
      })

      // Divider
      Divider()
        .height(1)
        .color('#F0F0F0')

      // --- Status Tab Bar ---
      Scroll() {
        Row({ space: 0 }) {
          ForEach(STATUS_TABS, (tab: StatusTabItem, index: number) => {
            Column() {
              Text(tab.label)
                .fontSize(14)
                .fontWeight(this.selectedTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selectedTabIndex === index ? '#FF6B35' : '#666666')
                .padding({ left: 16, right: 16, top: 12, bottom: 10 })

              // Active indicator
              if (this.selectedTabIndex === index) {
                Divider()
                  .height(3)
                  .width(24)
                  .color('#FF6B35')
                  .margin({ bottom: 0 })
              } else {
                Divider()
                  .height(3)
                  .width(24)
                  .color(Color.Transparent)
                  .margin({ bottom: 0 })
              }
            }
            .onClick(() => {
              // Same-page state change - not navigation
              this.selectedTabIndex = index;
              console.info('[OrderList] Tab selected: ' + tab.label);
            })
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .backgroundColor('#FFFFFF')

      // Divider
      Divider()
        .height(1)
        .color('#F0F0F0')

      // --- Promo Banner ---
      Row() {
        Text('🎁')
          .fontSize(18)
          .margin({ right: 8 })

        Column() {
          Text('春日礼遇 下单抽奖赢好礼')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('去抽奖 >')
          .fontSize(13)
          .fontColor('#FF6B35')
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            // Unresolved target - placeholder
            console.info('[OrderList] Promo banner tapped - lottery page not covered');
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFF8F0')
      .margin({ top: 8, left: 12, right: 12 })
      .borderRadius(8)

      // --- Order Card List ---
      Scroll() {
        Column({ space: 10 }) {
          ForEach(this.orderList, (order: OrderCardData, orderIndex: number) => {
            Column() {
              // Merchant name + status
              Row() {
                Text(order.merchant)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#222222')
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(order.status)
                  .fontSize(12)
                  .fontColor(order.statusColor)
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  .border({ width: 1, color: order.statusColor, radius: 4 })
              }
              .width('100%')

              // Items
              Column() {
                ForEach(order.items, (item: OrderItem) => {
                  Row() {
                    Text(item.name)
                      .fontSize(13)
                      .fontColor('#666666')
                      .layoutWeight(1)

                    Text(item.quantity)
                      .fontSize(13)
                      .fontColor('#999999')
                  }
                  .width('100%')
                  .margin({ top: 4 })
                })
              }
              .width('100%')
              .margin({ top: 8 })

              // Amount + Actions
              Row() {
                Text(order.amount)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FF6B35')
                  .layoutWeight(1)

                Row({ space: 8 }) {
                  ForEach(order.actions, (action: string) => {
                    Text(action)
                      .fontSize(12)
                      .fontColor(action === '去支付' ? '#FFFFFF' : '#FF6B35')
                      .fontWeight(FontWeight.Medium)
                      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                      .borderRadius(14)
                      .backgroundColor(action === '去支付' ? '#FF6B35' : '#FFF0E8')
                      .border({
                        width: action === '去支付' ? 0 : 1,
                        color: '#FF6B35',
                        radius: 14
                      })
                      .onClick(() => {
                        this.handleOrderAction(action, order);
                      })
                  })
                }
              }
              .width('100%')
              .margin({ top: 12 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
          })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // --- Action Handlers ---

  handleOrderAction(action: string, order: OrderCardData) {
    if (action === '去支付') {
      // Unresolved target: payment page not covered
      console.info('[OrderList] Pay action tapped for order: ' + order.merchant);
    } else if (action === '取消订单') {
      // Overlay: cancel confirmation dialog - not navigation
      console.info('[OrderList] Cancel order tapped for: ' + order.merchant);
    } else if (action === '再来一单') {
      // Unresolved target: reorder page not covered
      console.info('[OrderList] Reorder tapped for: ' + order.merchant);
    } else if (action === '评价') {
      // Unresolved target: review page not covered
      console.info('[OrderList] Review tapped for: ' + order.merchant);
    } else if (action === '查看详情') {
      // Unresolved target: order detail page not covered
      console.info('[OrderList] View detail tapped for: ' + order.merchant);
    }
  }
}
