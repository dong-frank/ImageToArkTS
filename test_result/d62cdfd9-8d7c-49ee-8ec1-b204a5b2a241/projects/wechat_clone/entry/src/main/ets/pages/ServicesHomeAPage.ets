import router from '@ohos.router';

interface ServiceItemData {
  icon: string;
  label: string;
  route?: string;
}

interface CategorySectionData {
  header: string;
  items: ServiceItemData[];
}

@Entry
@Component
struct ServicesHomeAPage {
  private readonly financeItems: ServiceItemData[] = [
    { icon: '💳', label: '信用卡还款' },
    { icon: '💰', label: '微粒贷借钱' },
    { icon: '📈', label: '理财通' },
    { icon: '🛡️', label: '保险服务' }
  ];

  private readonly lifeItems: ServiceItemData[] = [
    { icon: '📱', label: '手机充值', route: 'pages/PhoneRechargePage' },
    { icon: '💡', label: '生活缴费', route: 'pages/LifePaymentPage' },
    { icon: '🎮', label: 'Q币充值' },
    { icon: '🏙️', label: '城市服务' },
    { icon: '❤️', label: '腾讯公益' },
    { icon: '🏥', label: '医疗健康' }
  ];

  private readonly travelItems: ServiceItemData[] = [
    { icon: '🚗', label: '出行服务' },
    { icon: '🚄', label: '火车票机票' },
    { icon: '🚕', label: '滴滴出行' },
    { icon: '🏨', label: '酒店民宿' }
  ];

  private readonly categories: CategorySectionData[] = [
    { header: '金融理财', items: this.financeItems },
    { header: '生活服务', items: this.lifeItems },
    { header: '交通出行', items: this.travelItems }
  ];

  private handleBack(): void {
    router.back();
  }

  private handleMore(): void {
    console.info('[ServicesHomeAPage] 更多菜单点击');
  }

  private handleWalletTap(): void {
    router.pushUrl({ url: 'pages/WalletPage' });
  }

  private handleServiceItemTap(item: ServiceItemData): void {
    if (item.route) {
      router.pushUrl({ url: item.route });
    } else {
      console.info(`[ServicesHomeAPage] 点击服务项: ${item.label}`);
    }
  }

  build() {
    Column() {
      // Top bar
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

        Text('服务')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#191919')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

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
          // Green QuickActionCard
          Row() {
            // 收付款
            Column({ space: 8 }) {
              Text('⊕')
                .fontSize(28)
                .fontColor('#FFFFFF')
              Text('收付款')
                .fontSize(13)
                .fontColor('#FFFFFF')
            }
            .width('50%')
            .height(80)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              console.info('[ServicesHomeAPage] 收付款点击');
            })

            // Divider line
            Divider()
              .vertical(true)
              .height(40)
              .color('rgba(255,255,255,0.3)')
              .strokeWidth(1)

            // 钱包
            Column({ space: 4 }) {
              Text('👛')
                .fontSize(28)
              Text('钱包')
                .fontSize(13)
                .fontColor('#FFFFFF')
              Text('¥319.07')
                .fontSize(11)
                .fontColor('rgba(255,255,255,0.7)')
            }
            .width('50%')
            .height(80)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.handleWalletTap();
            })
          }
          .width('100%')
          .height(100)
          .borderRadius(12)
          .backgroundColor('#27AE60')
          .margin({ left: 16, right: 16, top: 12, bottom: 4 })
          .padding({ left: 12, right: 12 })

          // Category sections
          ForEach(this.categories, (category: CategorySectionData) => {
            this.CategorySection(category)
          })

          // Bottom spacing
          Column()
            .height(16)
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

  @Builder
  CategorySection(category: CategorySectionData) {
    Column() {
      // Section header
      Row() {
        Text(category.header)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#666666')
          .padding({ left: 4, right: 4 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      // Grid items in white card
      Column() {
        Grid() {
          ForEach(category.items, (item: ServiceItemData, index: number) => {
            GridItem() {
              this.ServiceGridItem(item)
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .rowsGap(12)
        .columnsGap(8)
        .padding({ top: 16, bottom: 16, left: 8, right: 8 })
        .width('100%')
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .padding({ left: 8, right: 8 })
      .margin({ left: 16, right: 16, top: 0, bottom: 8 })
    }
    .width('100%')
  }

  @Builder
  ServiceGridItem(item: ServiceItemData) {
    Column({ space: 8 }) {
      Text(item.icon)
        .fontSize(24)
      Text(item.label)
        .fontSize(12)
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.handleServiceItemTap(item);
    })
  }
}
