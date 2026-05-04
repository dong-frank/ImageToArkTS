import { router } from '@kit.ArkUI';

// ══════════════════════════════════════════
// Data types
// ══════════════════════════════════════════

interface QuickAction {
  icon: string;
  label: string;
  action: string;
}

interface ProductItem {
  id: string;
  title: string;
  price: string | null;
  badge: string | null;
  imageAlt: string;
}

// ══════════════════════════════════════════
// Data providers
// ══════════════════════════════════════════

function getCategoryTabs(): string[] {
  return ['全部', '知物咖啡', '图书'];
}

function getQuickActions(): QuickAction[] {
  return [
    { icon: '\uE8D0', label: '已购', action: '已购订单页' },
    { icon: '\uE8C1', label: '钱包', action: '钱包页' },
    { icon: '\uE8C7', label: '客服', action: '客服页' }
  ];
}

function getProducts(): ProductItem[] {
  return [
    {
      id: '1',
      title: '知乎知物定制玻璃杯400ml 刻度杯',
      price: '¥19.90',
      badge: null,
      imageAlt: '知乎知物定制玻璃杯400ml刻度杯'
    },
    {
      id: '2',
      title: '知乎知物 超浓缩水果风味咖啡液 荔枝风味330毫...',
      price: '¥39.90',
      badge: null,
      imageAlt: '知乎知物超浓缩水果风味咖啡液 荔枝风味330ml'
    },
    {
      id: '3',
      title: '知乎出品 知乎2023好问日历',
      price: null,
      badge: '火爆3年 全新再升级',
      imageAlt: '知乎2023好问日历'
    },
    {
      id: '4',
      title: '知乎出品 知乎版十万个为什么（全十册）',
      price: null,
      badge: null,
      imageAlt: '知乎版十万个为什么（全十册）'
    }
  ];
}

// ══════════════════════════════════════════
// Page component
// ══════════════════════════════════════════

@Entry
@Component
struct MallHomePage {
  @State selectedCategory: number = 0;
  private categories: string[] = getCategoryTabs();
  private quickActions: QuickAction[] = getQuickActions();
  private products: ProductItem[] = getProducts();

  build() {
    Column() {
      // ── Navigation Bar ──
      this.buildNavBar();

      // ── Breadcrumb ──
      this.buildBreadcrumb();

      // ── Quick Actions Row ──
      this.buildQuickActions();

      // ── Category Tabs ──
      this.buildCategoryTabs();

      // ── Scrollable Product Grid ──
      Scroll() {
        this.buildProductGrid();
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  // ─── Navigation Bar ───
  @Builder
  buildNavBar() {
    Row() {
      // Back button
      Row({ space: 4 }) {
        Text('\u2190')
          .fontSize(20)
          .fontColor('#333333')
      }
      .width(44)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        router.back();
      })

      // Title
      Text('知乎')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // Overflow menu
      Row({ space: 2 }) {
        Text('\u22EF')
          .fontSize(22)
          .fontColor('#333333')
      }
      .width(44)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        console.info('[MallHomePage] 三点菜单点击');
      })
    }
    .width('100%')
    .height(44)
    .padding({ left: 8, right: 8 })
    .backgroundColor('#F8F5F0')
    .alignItems(VerticalAlign.Center)
  }

  // ─── Breadcrumb ───
  @Builder
  buildBreadcrumb() {
    Row() {
      Text('商城')
        .fontSize(14)
        .fontColor('#999999')
        .padding({ left: 16, top: 8, bottom: 4 })
    }
    .width('100%')
  }

  // ─── Quick Actions Row ───
  @Builder
  buildQuickActions() {
    Row() {
      ForEach(this.quickActions, (item: QuickAction) => {
        Column({ space: 4 }) {
          // Icon
          Text(item.icon)
            .fontSize(24)
            .fontColor('#333333')

          // Label
          Text(item.label)
            .fontSize(12)
            .fontColor('#666666')
        }
        .width(80)
        .padding({ top: 16, bottom: 12 })
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          console.info('[MallHomePage] 快捷入口: ' + item.label + ' → ' + item.action);
        })
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
    .padding({ bottom: 8 })
  }

  // ─── Category Tabs ───
  @Builder
  buildCategoryTabs() {
    Row() {
      ForEach(this.categories, (category: string, index: number) => {
        Column({ space: 4 }) {
          Text(category)
            .fontSize(15)
            .fontWeight(this.selectedCategory === index ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(this.selectedCategory === index ? '#333333' : '#666666')

          // Active indicator
          if (this.selectedCategory === index) {
            Divider()
              .height(2)
              .width(24)
              .color('#FF6B00')
          } else {
            Divider()
              .height(2)
              .width(24)
              .color(Color.Transparent)
          }
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .onClick(() => {
          this.selectedCategory = index;
          console.info('[MallHomePage] 分类Tab切换: ' + category);
        })
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .padding({ top: 4, bottom: 8 })
    .border({
      width: { bottom: 1 },
      color: '#F0F0F0'
    })
  }

  // ─── Product Grid ───
  @Builder
  buildProductGrid() {
    Column() {
      // Row 1: products 0, 1
      Row() {
        ForEach(this.products.slice(0, 2), (product: ProductItem) => {
          Column() {
            this.buildProductCard(product)
          }
          .layoutWeight(1)
        })
      }
      .width('100%')

      // Row 2: products 2, 3
      Row() {
        ForEach(this.products.slice(2, 4), (product: ProductItem) => {
          Column() {
            this.buildProductCard(product)
          }
          .layoutWeight(1)
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 24 })
  }

  // ─── Product Card ───
  @Builder
  buildProductCard(product: ProductItem) {
    Column() {
      // Product image placeholder
      Stack() {
        Column() {
          Text('\uE8B0')
            .fontSize(48)
            .fontColor('#CCCCCC')
        }
        .width('100%')
        .height(140)
        .backgroundColor('#F5F5F5')
        .borderRadius({ topLeft: 8, topRight: 8 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // Badge overlay
        if (product.badge !== null) {
          Text(product.badge)
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF6B00')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
            .position({ left: 6, bottom: 6 })
        }
      }
      .width('100%')

      // Product info
      Column({ space: 6 }) {
        // Title
        Text(product.title)
          .fontSize(13)
          .fontColor('#333333')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(18)

        // Price row
        if (product.price !== null) {
          Text(product.price)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B00')
        } else {
          Row({ space: 4 }) {
            Text('\uE8C1')
              .fontSize(13)
              .fontColor('#999999')
            Text('查看详情')
              .fontSize(12)
              .fontColor('#999999')
          }
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 8, right: 8, top: 8, bottom: 10 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ bottomLeft: 8, bottomRight: 8 })
    }
    .margin(6)
    .borderRadius(8)
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 8,
      color: '#0D000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      console.info('[MallHomePage] 商品卡片点击: ' + product.title + ' → 商品详情页');
    })
  }
}
