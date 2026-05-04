import router from '@ohos.router';

// --- Data Models ---

interface BusinessCardData {
  title: string;
  rating: string;
  reviewCount: string;
  price: string;
  tags: string[];
  distance: string;
  badge: string;
  rank: string;
  imageColor: string;
}

// --- Mock Data ---

const MOCK_BUSINESS_LIST: BusinessCardData[] = [
  {
    title: '杨天歌冒菜·麻辣香锅 (仙林店)',
    rating: '3.8',
    reviewCount: '3435条',
    price: '¥85/人',
    tags: ['海鲜火锅', '仙林大学城'],
    distance: '4.6km',
    badge: '会员6.8折',
    rank: '仙林大学城火锅打卡人气榜 · 第2名',
    imageColor: '#FF8C42'
  },
  {
    title: '开云 (仙林美糖庄)',
    rating: '4.2',
    reviewCount: '3435条',
    price: '¥85/人',
    tags: ['海鲜火锅', '仙林大学城'],
    distance: '4.6km',
    badge: '会员6.8折',
    rank: '仙林大学城火锅打卡人气榜 · 第2名',
    imageColor: '#E8734A'
  },
  {
    title: '鮨鸟歡·烧鸟 yakitori',
    rating: '4.8',
    reviewCount: '1271条',
    price: '¥100/人',
    tags: ['日本料理', '仙林大学城'],
    distance: '4.7km',
    badge: '周末神券',
    rank: '栖霞区日式料理口味榜第1名',
    imageColor: '#D4523A'
  },
  {
    title: '海鸿兴·品味江南 (万达茂)',
    rating: '4.4',
    reviewCount: '1209条',
    price: '¥95/人',
    tags: ['淮扬菜', '万达茂'],
    distance: '806m',
    badge: '广告',
    rank: '栖霞区淮扬菜打卡人气榜第7名',
    imageColor: '#C44A3A'
  },
  {
    title: '丑吞 (仙林美糖店)',
    rating: '4.5',
    reviewCount: '892条',
    price: '¥120/人',
    tags: ['日式烤肉', '仙林大学城'],
    distance: '4.7km',
    badge: '热门榜第1名',
    rank: '仙林大学城烤肉打卡人气榜 · 第1名',
    imageColor: '#B84030'
  }
];

// --- Quick Action Data ---

interface QuickActionItem {
  label: string;
  icon: string;
}

const QUICK_ACTIONS: QuickActionItem[] = [
  { label: '附近', icon: '📍' },
  { label: '排行榜', icon: '🏆' },
  { label: '会员', icon: '👑' }
];

// --- Filter Data ---

interface FilterItem {
  label: string;
}

const FILTERS: FilterItem[] = [
  { label: '全城' },
  { label: '距离' },
  { label: '好评优先' },
  { label: '会员领券' }
];

// --- Main Component ---

@Entry
@Component
struct FoodList {
  @State activeFilterIndex: number = 0;

  build() {
    Column() {
      // --- Title Bar ---
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ left: 4, right: 12, top: 4, bottom: 4 })
          .onClick(() => {
            router.back();
          })

        Text('美食')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')

        Blank()

        Row() {
          Text('高科荣境')
            .fontSize(13)
            .fontColor('#666666')
          Text(' ⌵')
            .fontSize(12)
            .fontColor('#999999')
        }
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
      }
      .width('100%')
      .height(48)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#FFFFFF')

      // --- Search Bar ---
      Row() {
        Text('🔍')
          .fontSize(16)
          .margin({ right: 8 })
        Text('搜索美食、餐厅等')
          .fontSize(14)
          .fontColor('#B0B0B0')
        Blank()
        Text('搜索')
          .fontSize(13)
          .fontColor('#FF6600')
          .padding({ left: 12, right: 12, top: 5, bottom: 5 })
          .border({ width: 1, color: '#FF6600', radius: 12 })
      }
      .width('100%')
      .height(40)
      .padding({ left: 14, right: 10 })
      .backgroundColor('#F7F7F7')
      .borderRadius(20)
      .margin({ left: 12, right: 12, top: 8, bottom: 4 })

      // --- Quick Action Row ---
      Row({ space: 0 }) {
        ForEach(QUICK_ACTIONS, (item: QuickActionItem, index: number) => {
          Row() {
            Text(item.icon)
              .fontSize(18)
            Text(item.label)
              .fontSize(13)
              .fontColor('#333333')
              .margin({ left: 4 })
          }
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .backgroundColor('#F8F8F8')
          .borderRadius(16)
          .margin({ right: 10 })
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 4 })

      // --- Filter Bar ---
      Row() {
        ForEach(FILTERS, (item: FilterItem, index: number) => {
          Row() {
            Text(item.label)
              .fontSize(13)
              .fontColor(index === this.activeFilterIndex ? '#FF6600' : '#555555')
              .fontWeight(index === this.activeFilterIndex ? FontWeight.Medium : FontWeight.Normal)
            Text(' ⌵')
              .fontSize(10)
              .fontColor(index === this.activeFilterIndex ? '#FF6600' : '#AAAAAA')
          }
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .onClick(() => {
            this.activeFilterIndex = index;
          })
          .margin({ right: 4 })
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor('#FFFFFF')

      // --- Divider ---
      Divider()
        .height(1)
        .color('#F0F0F0')

      // --- Business Card List (Scrollable) ---
      Scroll() {
        Column() {
          ForEach(MOCK_BUSINESS_LIST, (item: BusinessCardData, index: number) => {
            Column() {
              // Card content
              Row() {
                // Left: image placeholder
                Column() {
                  Text('🍽️')
                    .fontSize(28)
                }
                .width(90)
                .height(90)
                .backgroundColor(item.imageColor)
                .borderRadius(8)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)

                // Right: info
                Column() {
                  // Title row
                  Row() {
                    Text(item.title)
                      .fontSize(15)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#222222')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)

                    if (item.badge.length > 0) {
                      Text(item.badge)
                        .fontSize(10)
                        .fontColor('#FF6600')
                        .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                        .border({ width: 0.5, color: '#FF6600', radius: 3 })
                    }
                  }
                  .width('100%')
                  .margin({ bottom: 4 })

                  // Rating row
                  Row() {
                    Text('★ ' + item.rating)
                      .fontSize(12)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FF6600')
                    Text('  ' + item.reviewCount)
                      .fontSize(11)
                      .fontColor('#999999')
                    Text('  ' + item.price)
                      .fontSize(11)
                      .fontColor('#999999')
                  }
                  .margin({ bottom: 4 })

                  // Tags row
                  Row() {
                    ForEach(item.tags, (tag: string) => {
                      Text(tag)
                        .fontSize(10)
                        .fontColor('#888888')
                        .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                        .backgroundColor('#F5F5F5')
                        .borderRadius(3)
                        .margin({ right: 4 })
                    })
                    Text('  ' + item.distance)
                      .fontSize(11)
                      .fontColor('#AAAAAA')
                  }
                  .margin({ bottom: 4 })

                  // Rank row
                  Row() {
                    Text('🏅 ' + item.rank)
                      .fontSize(10)
                      .fontColor('#B8860B')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                }
                .layoutWeight(1)
                .margin({ left: 10 })
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding({ top: 12, bottom: 12, left: 12, right: 12 })
              .alignItems(VerticalAlign.Top)

              // Divider between cards
              if (index < MOCK_BUSINESS_LIST.length - 1) {
                Divider()
                  .height(1)
                  .color('#F5F5F5')
                  .margin({ left: 114 })
              }
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .onClick(() => {
              // Business card tap - target page not yet covered, placeholder
              console.info('Business card tapped: ' + item.title);
            })
          })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }
}
