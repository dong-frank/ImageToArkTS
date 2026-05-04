import router from '@ohos.router';
import { BottomNavBar } from '../components/BottomNavBar';

@Entry
@Component
struct MallPage {
  @State bannerIndex: number = 0;
  @State categoryIndex: number = 0;
  banners: string[] = ['好物推荐', '限时特惠', '新品首发'];
  categories: string[] = ['推荐', '数码', '书籍', '生活', '文创'];

  build() {
    Column() {
      // Status bar
      Row() {
        Text('15:17')
          .fontSize(12)
          .fontColor('#333333')
        Blank()
        Text('56%')
          .fontSize(12)
          .fontColor('#333333')
      }
      .width('100%')
      .height(28)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F5F5F5')

      // Header with search
      Row() {
        Row() {
          Text('\u{1F50D}')
            .fontSize(16)
            .margin({ right: 6 })
          Text('搜索好物')
            .fontSize(14)
            .fontColor('#999999')
        }
        .layoutWeight(1)
        .height(34)
        .backgroundColor('#F5F5F5')
        .borderRadius(17)
        .padding({ left: 12 })
        .onClick(() => {
          // Search action
        })
        Text('\u{1F6CD}')
          .fontSize(22)
          .margin({ left: 12 })
        Text('购物车')
          .fontSize(13)
          .fontColor('#333333')
          .onClick(() => {
            // Cart action
          })
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Main scrollable content
      Scroll() {
        Column() {
          // Banner carousel area
          Column() {
            Row() {
              ForEach(this.banners, (banner: string, index: number) => {
                Text(banner)
                  .fontSize(13)
                  .fontColor(this.bannerIndex === index ? '#0066FF' : '#666666')
                  .fontWeight(this.bannerIndex === index ? FontWeight.Bold : FontWeight.Normal)
                  .margin({ right: 20 })
                  .onClick(() => {
                    this.bannerIndex = index;
                  })
              })
            }
            .width('100%')
            .padding({ left: 16, top: 10 })

            // Banner card
            Column() {
              Text('\u{1F389}')
                .fontSize(40)
              Text(this.banners[this.bannerIndex] + '专区')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 8 })
              Text('精选品质好物，限时折扣进行中')
                .fontSize(13)
                .fontColor('#FF6600')
                .margin({ top: 4 })
              Text('立即抢购 >')
                .fontSize(13)
                .fontColor('#FFFFFF')
                .backgroundColor('#FF6600')
                .borderRadius(14)
                .padding({ left: 16, right: 16, top: 6, bottom: 6 })
                .margin({ top: 10 })
            }
            .width('100%')
            .padding({ top: 20, bottom: 24 })
            .backgroundColor('#FFF3E0')
            .borderRadius(10)
            .margin({ left: 12, right: 12, top: 8 })
            .alignItems(HorizontalAlign.Center)
          }

          // Category icons
          Row() {
            this.CategoryIcon('\u{1F4F1}', '数码')
            this.CategoryIcon('\u{1F4DA}', '书籍')
            this.CategoryIcon('\u{1F3A7}', '耳机')
            this.CategoryIcon('\u{1F451}', '穿搭')
            this.CategoryIcon('\u{1F3AE}', '游戏')
          }
          .width('100%')
          .padding(16)
          .justifyContent(FlexAlign.SpaceAround)

          // Sub-category tabs
          Scroll() {
            Row() {
              ForEach(this.categories, (cat: string, index: number) => {
                Text(cat)
                  .fontSize(13)
                  .fontColor(this.categoryIndex === index ? '#0066FF' : '#666666')
                  .fontWeight(this.categoryIndex === index ? FontWeight.Bold : FontWeight.Normal)
                  .backgroundColor(this.categoryIndex === index ? '#E8F0FE' : '#F5F5F5')
                  .borderRadius(14)
                  .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                  .margin({ right: 10 })
                  .onClick(() => {
                    this.categoryIndex = index;
                  })
              })
            }
            .padding({ left: 16 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
          .height(40)

          // Product grid
          Row() {
            this.ProductCard('知乎盐选会员', '\u{2B50}', '¥19/月', '原价¥39', '已售 2.3w')
            this.ProductCard('知乎周边帆布包', '\u{1F392}', '¥59', '原价¥99', '已售 8,920')
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 8 })

          Row() {
            this.ProductCard('知乎 T恤 经典款', '\u{1F455}', '¥79', '原价¥139', '已售 5,670')
            this.ProductCard('知乎咖啡礼盒', '\u{2615}', '¥128', '原价¥198', '已售 3,450')
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 8 })

          // Hot deals section
          Row() {
            Text('限时特惠')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            Blank()
            Text('查看更多 >')
              .fontSize(12)
              .fontColor('#0066FF')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 8 })

          this.DealItem('知乎读书卡', '年卡', '¥198', '¥365', '热卖')
          this.DealItem('知乎Live 畅听包', '季卡', '¥68', '¥128', '限时')
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)

      BottomNavBar({ currentTab: 3 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  CategoryIcon(icon: string, label: string) {
    Column() {
      Text(icon)
        .fontSize(28)
        .width(48)
        .height(48)
        .borderRadius(12)
        .backgroundColor('#F0F4FF')
        .textAlign(TextAlign.Center)
      Text(label)
        .fontSize(11)
        .fontColor('#333333')
        .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      // Category click
    })
  }

  @Builder
  ProductCard(name: string, icon: string, price: string, original: string, sold: string) {
    Column() {
      Text(icon)
        .fontSize(36)
        .width('100%')
        .height(100)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .textAlign(TextAlign.Center)
      Text(name)
        .fontSize(13)
        .fontColor('#333333')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })
      Row() {
        Text(price)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF4500')
        Text(original)
          .fontSize(11)
          .fontColor('#CCCCCC')
          .decoration({ type: TextDecorationType.LineThrough })
          .margin({ left: 6 })
      }
      .width('100%')
      .margin({ top: 4 })
      Text(sold)
        .fontSize(11)
        .fontColor('#999999')
        .margin({ top: 2 })
        .width('100%')
    }
    .layoutWeight(1)
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ left: 4, right: 4 })
  }

  @Builder
  DealItem(name: string, tag: string, price: string, original: string, badgeText: string) {
    Row() {
      Text('\u{1F4E6}')
        .fontSize(32)
        .width(64)
        .height(64)
        .backgroundColor('#FFF8E1')
        .borderRadius(8)
        .textAlign(TextAlign.Center)
      Column() {
        Row() {
          Text(name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text(tag)
            .fontSize(10)
            .fontColor('#FF6600')
            .backgroundColor('#FFF3E0')
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .margin({ left: 6 })
        }
        Row() {
          Text(price)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF4500')
          Text(original)
            .fontSize(12)
            .fontColor('#CCCCCC')
            .decoration({ type: TextDecorationType.LineThrough })
            .margin({ left: 6 })
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
      Text(badgeText)
        .fontSize(10)
        .fontColor('#FFFFFF')
        .backgroundColor('#FF4500')
        .borderRadius(8)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .margin({ left: 12, right: 12, top: 4, bottom: 4 })
    .borderRadius(8)
  }
}
