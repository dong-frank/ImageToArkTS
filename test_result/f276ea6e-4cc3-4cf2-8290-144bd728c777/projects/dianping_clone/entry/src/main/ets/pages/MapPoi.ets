import router from '@ohos.router';
import { BottomNavBar } from '../common/components/BottomNavBar';

interface PoiMarker {
  label: string;
  score: string;
  x: number;
  y: number;
}

interface PoiCard {
  title: string;
  rating: string;
  reviewCount: string;
  price: string;
  tags: string[];
  distance: string;
  badge: string;
  rankInfo: string;
}

interface CategoryTab {
  label: string;
  badge: string;
  selected: boolean;
}

interface ActionButton {
  label: string;
  badge: string;
}

@Entry
@Component
struct MapPoi {
  @State selectedCategory: string = '推荐';
  @State categories: CategoryTab[] = [
    { label: '推荐', badge: '🔥', selected: true },
    { label: '美食', badge: '', selected: false },
    { label: '玩乐', badge: '', selected: false },
    { label: '景点', badge: '', selected: false },
    { label: '购物', badge: '', selected: false }
  ];

  @State poiMarkers: PoiMarker[] = [
    { label: '九乡河生态公园', score: '4.2分', x: 48, y: 22 },
    { label: '杨天歌冒菜·麻辣香锅', score: '3.8分', x: 18, y: 26 },
    { label: '羊山湖公园', score: '4.3分', x: 32, y: 34 },
    { label: '江苏省中医药博物馆', score: '3.8分', x: 38, y: 42 },
    { label: '山林美糖广场', score: '4.8分', x: 8, y: 47 },
    { label: '江宴·仙林山房', score: '4.8分', x: 24, y: 52 },
    { label: '外婆人家融合淮扬菜', score: '3.9分', x: 78, y: 62 },
    { label: '必胜客', score: '4.0分', x: 68, y: 26 },
    { label: '美术馆', score: '3.7分', x: 82, y: 29 },
    { label: '邓廷桢墓', score: '3.5分', x: 6, y: 61 }
  ];

  @State actionButtons: ActionButton[] = [
    { label: '赏花', badge: '' },
    { label: '必吃榜', badge: '🔥' },
    { label: '收藏', badge: '' },
    { label: '定位', badge: '' }
  ];

  @State poiCards: PoiCard[] = [
    {
      title: '王和李·海鲜火锅大排档 (美糖广场店)',
      rating: '4.2',
      reviewCount: '3435条',
      price: '¥85/人',
      tags: ['海鲜火锅', '仙林大学城'],
      distance: '4.6km',
      badge: '会员6.8折',
      rankInfo: '仙林大学城火锅打卡人气榜 · 第2名'
    },
    {
      title: '开云 (仙林美糖庄)',
      rating: '',
      reviewCount: '',
      price: '',
      tags: [],
      distance: '',
      badge: '',
      rankInfo: ''
    }
  ];

  handleCategoryTap(label: string): void {
    const newCategories = this.categories.map((cat: CategoryTab): CategoryTab => {
      return {
        label: cat.label,
        badge: cat.badge,
        selected: cat.label === label
      };
    });
    this.categories = newCategories;
    this.selectedCategory = label;
  }

  handleActionButtonTap(label: string): void {
    if (label === '定位') {
      console.info('定位按钮：重置地图中心至当前位置');
    } else if (label === '必吃榜') {
      console.info('必吃榜按钮：跳转榜单页（目标页未实现）');
    } else if (label === '赏花') {
      console.info('赏花按钮：筛选赏花类POI');
    } else if (label === '收藏') {
      console.info('收藏按钮：查看收藏列表');
    }
  }

  handlePoiMarkerTap(marker: PoiMarker): void {
    console.info('POI标记点击：' + marker.label + '（POI详情页未实现）');
  }

  handlePoiCardTap(card: PoiCard): void {
    console.info('POI卡片点击：' + card.title + '（POI详情页未实现）');
  }

  handleSearchTap(): void {
    console.info('搜索栏点击：搜索地点/美食/景点（搜索结果页未实现）');
  }

  handleOverlayTrigger(): void {
    console.info('底部+按钮：触发action_hub_overlay（overlay未实现）');
  }

  build() {
    Column() {
      // Search bar
      Row() {
        Text('🔍')
          .fontSize(16)
          .margin({ right: 8 })
        Text('搜索地点、美食、景点等')
          .fontSize(14)
          .fontColor('#999999')
          .layoutWeight(1)
      }
      .width('100%')
      .height(40)
      .backgroundColor('#F5F5F5')
      .borderRadius(20)
      .padding({ left: 14, right: 14 })
      .margin({ left: 12, right: 12, top: 8, bottom: 4 })
      .onClick(() => {
        this.handleSearchTap();
      })

      // Category tabs
      Row({ space: 0 }) {
        ForEach(this.categories, (cat: CategoryTab, index: number) => {
          Row({ space: 2 }) {
            if (cat.badge !== '') {
              Text(cat.badge)
                .fontSize(12)
            }
            Text(cat.label)
              .fontSize(13)
              .fontColor(cat.selected ? '#FF6600' : '#333333')
              .fontWeight(cat.selected ? FontWeight.Bold : FontWeight.Regular)
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(cat.selected ? '#FFF3E6' : '#FFFFFF')
          .borderRadius(16)
          .border({
            width: cat.selected ? 1 : 0,
            color: cat.selected ? '#FF6600' : 'transparent'
          })
          .margin({ right: index < this.categories.length - 1 ? 8 : 0 })
          .onClick(() => {
            this.handleCategoryTap(cat.label);
          })
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 4, bottom: 8 })
      .justifyContent(FlexAlign.Start)

      // Map area with POI markers
      Stack() {
        // Map background
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#E8F4E8')

        // Map placeholder with grid pattern
        Column() {
          Text('美团地图')
            .fontSize(14)
            .fontColor('#AAAAAA')
            .opacity(0.6)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // POI markers
        ForEach(this.poiMarkers, (marker: PoiMarker, index: number) => {
          Column({ space: 2 }) {
            // Score badge
            Row({ space: 2 }) {
              Text('⭐')
                .fontSize(9)
              Text(marker.score)
                .fontSize(9)
                .fontColor('#FFFFFF')
            }
            .backgroundColor('#FF6600')
            .borderRadius(8)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })

            // Marker dot
            Column()
              .width(8)
              .height(8)
              .backgroundColor('#FF6600')
              .borderRadius(4)
              .border({ width: 2, color: '#FFFFFF' })

            // Label
            Text(marker.label)
              .fontSize(10)
              .fontColor('#333333')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .backgroundColor('#FFFFFF')
              .borderRadius(4)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .shadow({ radius: 2, color: '#00000020', offsetX: 0, offsetY: 1 })
          }
          .alignItems(HorizontalAlign.Center)
          .position({ x: marker.x + '%', y: marker.y + '%' })
          .onClick(() => {
            this.handlePoiMarkerTap(marker);
          })
        })

        // Right action buttons
        Column({ space: 8 }) {
          ForEach(this.actionButtons, (btn: ActionButton, index: number) => {
            Column({ space: 2 }) {
              if (btn.badge !== '') {
                Text(btn.badge)
                  .fontSize(10)
              }
              Text(btn.label)
                .fontSize(11)
                .fontColor('#333333')
            }
            .width(48)
            .height(48)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .shadow({ radius: 3, color: '#00000015', offsetX: 0, offsetY: 1 })
            .onClick(() => {
              this.handleActionButtonTap(btn.label);
            })
          })
        }
        .position({ right: 12, bottom: 16 })
      }
      .width('100%')
      .layoutWeight(1)

      // POI card list (bottom sheet area)
      Column() {
        // Drag handle
        Row() {
          Row()
            .width(36)
            .height(4)
            .backgroundColor('#DDDDDD')
            .borderRadius(2)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8, bottom: 4 })

        // Card list
        Scroll() {
          Column({ space: 10 }) {
            ForEach(this.poiCards, (card: PoiCard, index: number) => {
              Column() {
                Row({ space: 10 }) {
                  // Left image placeholder
                  Column()
                    .width(80)
                    .height(80)
                    .backgroundColor('#E8E8E8')
                    .borderRadius(8)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)

                  // Right content
                  Column({ space: 4 }) {
                    // Title
                    Text(card.title)
                      .fontSize(15)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#222222')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    if (card.rating !== '') {
                      // Rating row
                      Row({ space: 6 }) {
                        Row({ space: 2 }) {
                          Text('⭐')
                            .fontSize(11)
                          Text(card.rating)
                            .fontSize(13)
                            .fontWeight(FontWeight.Bold)
                            .fontColor('#FF6600')
                        }
                        Text(card.reviewCount)
                          .fontSize(11)
                          .fontColor('#999999')
                        Text(card.price)
                          .fontSize(11)
                          .fontColor('#999999')
                      }

                      // Tags row
                      Row({ space: 6 }) {
                        if (card.tags.length > 0) {
                          ForEach(card.tags, (tag: string) => {
                            Text(tag)
                              .fontSize(10)
                              .fontColor('#FF6600')
                              .backgroundColor('#FFF3E6')
                              .borderRadius(3)
                              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                          })
                        }
                        Text(card.distance)
                          .fontSize(11)
                          .fontColor('#999999')
                      }

                      // Badge
                      if (card.badge !== '') {
                        Row({ space: 4 }) {
                          Text(card.badge)
                            .fontSize(10)
                            .fontColor('#FFFFFF')
                            .backgroundColor('#FF4444')
                            .borderRadius(3)
                            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                        }
                      }

                      // Rank info
                      if (card.rankInfo !== '') {
                        Row({ space: 4 }) {
                          Text('🏆')
                            .fontSize(11)
                          Text(card.rankInfo)
                            .fontSize(11)
                            .fontColor('#FF6600')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                      }
                    }
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .padding(10)
              }
              .width('100%')
              .backgroundColor('#FFFFFF')
              .borderRadius(10)
              .onClick(() => {
                this.handlePoiCardTap(card);
              })
            })
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 8 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
      .width('100%')
      .height(220)
      .backgroundColor('#F8F8F8')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .shadow({ radius: 8, color: '#00000015', offsetX: 0, offsetY: -2 })

      // Bottom navigation bar (shared component)
      BottomNavBar({ activeTab: '地图', onOverlayTrigger: this.handleOverlayTrigger })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }
}
