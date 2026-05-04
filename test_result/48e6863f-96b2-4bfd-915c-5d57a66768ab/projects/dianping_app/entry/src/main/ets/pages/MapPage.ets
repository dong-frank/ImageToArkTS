import { BottomNavBar } from '../components/BottomNavBar';
import { POIMarker, POICard } from '../models/DataTypes';

@Entry
@Component
struct MapPage {
  @State currentTab: number = 1; // 0=首页, 1=地图, 2=消息, 3=我的
  @State selectedCategory: number = 0; // 0=推荐, 1=美食, 2=玩乐, 3=景点, 4=购物
  @State searchText: string = '';

  private categories: string[] = ['推荐', '美食', '玩乐', '景点', '购物'];
  private categoryIcons: string[] = ['🔥', '🍽️', '🎮', '🏞️', '🛍️'];

  private poiMarkers: POIMarker[] = [
    new POIMarker('九乡河生态公园', '4.2分', '🌳', 48, 22),
    new POIMarker('羊山湖公园', '4.3分', '🌳', 32, 34),
    new POIMarker('杨天歌冒菜·麻辣香锅', '3.8分', '🍽️', 18, 26),
    new POIMarker('必胜客', '4.0分', '🍽️', 68, 25),
    new POIMarker('美术馆', '3.7分', '🎨', 82, 29),
    new POIMarker('山林美糖广场', '4.8分', '🛍️', 8, 47),
    new POIMarker('江宴·仙林山房', '4.8分', '🍽️', 22, 53),
    new POIMarker('外婆人家融合淮扬菜', '3.9分', '🍽️', 78, 62),
    new POIMarker('邓廷桢墓', '3.5分', '🌳', 6, 61),
    new POIMarker('江苏省中医药博物馆', '3.8分', '🏛️', 38, 42),
  ];

  private poiCards: POICard[] = [
    new POICard('王和李·海鲜火锅大排档 (美糖广场店)', '4.2', '3435条', '¥85/人',
      ['海鲜火锅', '仙林大学城'], '4.6km', '会员6.8折', '仙林大学城火锅打卡人气榜 · 第2名'),
    new POICard('开云 (仙林美糖庄)', '4.0', '1280条', '¥120/人',
      ['粤菜', '仙林'], '5.2km', '新店', '仙林粤菜好评榜 · 第5名'),
  ];

  build() {
    Column() {
      // Search Bar
      this.SearchBar();

      // Category Tabs
      this.CategoryTabs();

      // Map Area with POI markers
      this.MapArea();

      // Right side action buttons
      this.RightSideActions();

      // POI Card List at bottom
      this.POICardList();

      // Bottom Navigation Bar
      BottomNavBar({ currentTab: $currentTab });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // Search Bar
  @Builder
  SearchBar() {
    Row() {
      Row() {
        Text('🔍')
          .fontSize(16)
          .margin({ left: 12 })
        Text('搜索地点、美食、景点等')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ left: 6 })
      }
      .width('100%')
      .height(40)
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  // Category Tabs
  @Builder
  CategoryTabs() {
    Row() {
      ForEach(this.categories, (category: string, index: number) => {
        Column() {
          Text(this.categoryIcons[index])
            .fontSize(18)
          Text(category)
            .fontSize(12)
            .fontColor(this.selectedCategory === index ? '#FF6600' : '#666666')
            .fontWeight(this.selectedCategory === index ? FontWeight.Bold : FontWeight.Normal)
            .margin({ top: 2 })
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(16)
        .backgroundColor(this.selectedCategory === index ? '#FFF5EB' : '#FFFFFF')
        .margin({ left: index === 0 ? 16 : 4, right: index === this.categories.length - 1 ? 16 : 4 })
        .onClick(() => {
          this.selectedCategory = index;
        })
      })
    }
    .width('100%')
    .padding({ top: 4, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  // Map Area
  @Builder
  MapArea() {
    Stack() {
      // Map placeholder background
      Column() {
        Text('🗺️')
          .fontSize(80)
          .opacity(0.15)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#E8F4E8')

      // POI Markers
      ForEach(this.poiMarkers, (marker: POIMarker) => {
        Column() {
          Column() {
            Text(marker.score)
              .fontSize(9)
              .fontColor('#FFFFFF')
              .backgroundColor('#FF6600')
              .borderRadius(4)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            Text(marker.icon)
              .fontSize(20)
              .margin({ top: 2 })
          }
          .padding(4)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.15)' })

          Text(marker.label)
            .fontSize(10)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width(80)
            .textAlign(TextAlign.Center)
            .margin({ top: 2 })
        }
        .position({ left: `${marker.x}%`, top: `${marker.y}%` })
        .alignItems(HorizontalAlign.Center)
      })
    }
    .width('100%')
    .layoutWeight(1)
  }

  // Right Side Actions
  @Builder
  RightSideActions() {
    Column() {
      this.ActionButton('🌸', '赏花')
      this.ActionButton('✓', '必吃榜')
      this.ActionButton('⭐', '收藏')
      this.ActionButton('◎', '定位')
    }
    .position({ right: 12, bottom: 220 })
    .zIndex(10)
  }

  @Builder
  ActionButton(icon: string, label: string) {
    Column() {
      Text(icon)
        .fontSize(20)
      Text(label)
        .fontSize(9)
        .fontColor('#666666')
        .margin({ top: 2 })
    }
    .width(44)
    .height(44)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)' })
    .margin({ bottom: 8 })
  }

  // POI Card List
  @Builder
  POICardList() {
    Column() {
      ForEach(this.poiCards, (card: POICard, index: number) => {
        this.POICardItem(card, index);
      })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.08)' })
  }

  @Builder
  POICardItem(card: POICard, index: number) {
    Row() {
      // Card image placeholder
      Column() {
        Text('📷')
          .fontSize(28)
          .opacity(0.3)
      }
      .width(80)
      .height(80)
      .backgroundColor('#F0F0F0')
      .borderRadius(8)

      // Card info
      Column() {
        Text(card.title)
          .fontSize(14)
          .fontColor('#1A1A1A')
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text(`⭐ ${card.rating}`)
            .fontSize(12)
            .fontColor('#FF6600')
            .fontWeight(FontWeight.Bold)
          Text(`${card.reviewCount}`)
            .fontSize(11)
            .fontColor('#999999')
            .margin({ left: 4 })
          Text(card.price)
            .fontSize(11)
            .fontColor('#999999')
            .margin({ left: 6 })
        }
        .margin({ top: 4 })

        Row() {
          ForEach(card.tags, (tag: string) => {
            Text(tag)
              .fontSize(10)
              .fontColor('#999999')
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ right: 4 })
          })
          Text(card.distance)
            .fontSize(10)
            .fontColor('#999999')
        }
        .margin({ top: 4 })

        Row() {
          Text(card.badge)
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF4444')
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
          Text(card.rankInfo)
            .fontSize(10)
            .fontColor('#FF6600')
            .margin({ left: 6 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .margin({ top: 4 })
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .border({
      width: { bottom: index < this.poiCards.length - 1 ? 0.5 : 0 },
      color: '#EEEEEE',
    })
  }
}
