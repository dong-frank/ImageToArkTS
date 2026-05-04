import router from '@ohos.router';

interface ServiceItemData {
  icon: string;
  label: string;
  route?: string;
}

@Entry
@Component
struct ServicesHomeBPage {
  // 生活服务 (6 items)
  private lifeServiceItems: ServiceItemData[] = [
    { icon: '\u{1F4F1}', label: '手机充值', route: 'pages/PhoneRechargePage' },
    { icon: '\u{1F4A1}', label: '生活缴费', route: 'pages/LifePaymentPage' },
    { icon: '\u{1F427}', label: 'Q币充值' },
    { icon: '\u{1F3D9}', label: '城市服务' },
    { icon: '\u{1F338}', label: '腾讯公益' },
    { icon: '\u{1F3E5}', label: '医疗健康' },
  ];

  // 交通出行 (4 items)
  private travelServiceItems: ServiceItemData[] = [
    { icon: '\u{1F9ED}', label: '出行服务' },
    { icon: '\u{1F684}', label: '火车票机票' },
    { icon: '\u{1F697}', label: '滴滴出行' },
    { icon: '\u{1F3E8}', label: '酒店民宿' },
  ];

  // 购物消费 (8 items)
  private shoppingServiceItems: ServiceItemData[] = [
    { icon: '\u{1F6CD}', label: '品牌发现' },
    { icon: '\u{1F436}', label: '京东购物' },
    { icon: '\u{1F430}', label: '美团外卖' },
    { icon: '\u{1F3AC}', label: '电影演出玩乐' },
    { icon: '\u{1F7E0}', label: '美团团购' },
    { icon: '\u{1F4E6}', label: '拼多多' },
    { icon: '\u{1F497}', label: '唯品会特卖' },
    { icon: '\u{1F504}', label: '转转二手' },
  ];

  build() {
    Column() {
      // Navigation header bar
      Row() {
        // Back button
        Text('\u{2190}')
          .fontSize(22)
          .fontColor('#191919')
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.back();
          })

        // Title
        Text('服务')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#191919')
          .textAlign(TextAlign.Center)
          .flexGrow(1)

        // More menu button
        Text('\u{22EF}')
          .fontSize(22)
          .fontColor('#191919')
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            // More options menu - placeholder
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#EDEDED')

      // Scrollable content area
      Scroll() {
        Column({ space: 12 }) {
          // 生活服务 category
          this.CategorySection('生活服务', this.lifeServiceItems)

          // 交通出行 category
          this.CategorySection('交通出行', this.travelServiceItems)

          // 购物消费 category
          this.CategorySection('购物消费', this.shoppingServiceItems)

          // Bottom spacer
          Column()
            .height(16)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 14, bottom: 14 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  CategorySection(title: string, items: ServiceItemData[]) {
    Column() {
      // Category header
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#999999')
        .width('100%')
        .padding({ left: 4, bottom: 10 })

      // Service items grid (2 columns)
      Grid() {
        ForEach(items, (item: ServiceItemData, index: number) => {
          GridItem() {
            this.ServiceCell(item)
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(0)
      .rowsGap(0)
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
    }
    .width('100%')
  }

  @Builder
  ServiceCell(item: ServiceItemData) {
    Row({ space: 10 }) {
      // Service icon
      Text(item.icon)
        .fontSize(22)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(6)
        .backgroundColor('#F0F0F0')

      // Service label
      Text(item.label)
        .fontSize(14)
        .fontColor('#191919')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(56)
    .padding({ left: 14, right: 8 })
    .onClick(() => {
      if (item.route) {
        router.pushUrl({ url: item.route });
      }
    })
  }
}
