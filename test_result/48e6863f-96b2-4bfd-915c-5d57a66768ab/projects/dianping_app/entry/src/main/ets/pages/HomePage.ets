import router from '@ohos.router';
import { BottomNavBar } from '../components/BottomNavBar';
import { CategoryItem, RecommendationItem } from '../models/DataTypes';

@Entry
@Component
struct HomePage {
  @State currentTab: number = 0;
  @State searchText: string = '';

  private categories: CategoryItem[] = [
    new CategoryItem('美食', '🍜', '#FF6B35'),
    new CategoryItem('火锅', '🫕', '#E74C3C'),
    new CategoryItem('烧烤', '🍖', '#F39C12'),
    new CategoryItem('日料', '🍣', '#E67E22'),
    new CategoryItem('韩料', '🥩', '#C0392B'),
    new CategoryItem('甜品', '🍰', '#FF69B4'),
    new CategoryItem('饮品', '🧋', '#8E44AD'),
    new CategoryItem('小吃', '🍢', '#D35400'),
    new CategoryItem('西餐', '🥩', '#7D3C98'),
    new CategoryItem('海鲜', '🦞', '#2980B9'),
    new CategoryItem('自助', '🍽️', '#27AE60'),
    new CategoryItem('更多', '⋯', '#7F8C8D'),
  ];

  // Recommended restaurants
  private recommendations: RecommendationItem[] = [
    new RecommendationItem('海底捞火锅', '4.8', '¥120/人', ['火锅', '服务好'], '🫕'),
    new RecommendationItem('西贝莜面村', '4.6', '¥85/人', ['西北菜', '面食'], '🍜'),
    new RecommendationItem('鼎泰丰', '4.7', '¥150/人', ['小笼包', '江浙菜'], '🥟'),
    new RecommendationItem('大董烤鸭', '4.9', '¥300/人', ['烤鸭', '京菜'], '🦆'),
  ];

  build() {
    Column() {
      // Header area
      this.HeaderSection()

      // Scrollable content
      Scroll() {
        Column() {
          // Search bar
          this.SearchBar()

          // Category grid
          this.CategoryGrid()

          // Banner / promotion
          this.PromotionBanner()

          // Recommended section
          this.RecommendedSection()

          // Nearby restaurants
          this.NearbySection()
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // Bottom navigation bar
      BottomNavBar({ currentTab: $currentTab })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  HeaderSection() {
    Row() {
      Text('大众点评')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      Blank()

      Text('📍 北京市')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ right: 12 })

      Text('📱')
        .fontSize(20)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  SearchBar() {
    Row() {
      Text('🔍')
        .fontSize(16)
        .margin({ left: 12, right: 8 })

      Text('搜索美食、餐厅、菜系')
        .fontSize(14)
        .fontColor('#999999')
        .layoutWeight(1)

      Text('筛选')
        .fontSize(12)
        .fontColor('#FF6600')
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .border({ width: 1, color: '#FF6600', radius: 10 })
        .margin({ right: 8 })
    }
    .width('100%')
    .height(40)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ left: 16, right: 16, top: 8, bottom: 12 })
    .onClick(() => {
      router.pushUrl({ url: 'pages/FoodListPage' });
    })
  }

  @Builder
  CategoryGrid() {
    Column() {
      Grid() {
        ForEach(this.categories, (item: CategoryItem, index: number) => {
          GridItem() {
            Column() {
              Text(item.icon)
                .fontSize(32)
                .margin({ bottom: 6 })

              Text(item.name)
                .fontSize(12)
                .fontColor('#333333')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              router.pushUrl({ url: 'pages/FoodListPage', params: { category: item.name } });
            })
          }
          .height(80)
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(4)
      .width('100%')
      .height(260)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .padding({ top: 12, bottom: 12, left: 8, right: 8 })
    .margin({ left: 16, right: 16, bottom: 12 })
  }

  @Builder
  PromotionBanner() {
    Row() {
      Column() {
        Text('🔥 限时特惠')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text('精选美食5折起')
          .fontSize(12)
          .fontColor('#FFFFFF')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('立即抢购 >')
        .fontSize(13)
        .fontColor('#FFFFFF')
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('#FF6600')
        .borderRadius(16)
    }
    .width('100%')
    .height(80)
    .padding({ left: 20, right: 20 })
    .borderRadius(12)
    .linearGradient({
      direction: GradientDirection.Right,
      colors: [['#FF6B35', 0.0], ['#FF4500', 1.0]]
    })
    .margin({ left: 16, right: 16, bottom: 12 })
  }

  @Builder
  RecommendedSection() {
    Column() {
      Row() {
        Text('🌟 为你推荐')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Text('更多 >')
          .fontSize(12)
          .fontColor('#999999')
          .onClick(() => {
            router.pushUrl({ url: 'pages/FoodListPage' });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      Scroll() {
        Row() {
          ForEach(this.recommendations, (item: RecommendationItem, index: number) => {
            Column() {
              Text(item.image)
                .fontSize(48)
                .width('100%')
                .height(100)
                .textAlign(TextAlign.Center)
                .backgroundColor('#F0F0F0')
                .borderRadius({ topLeft: 10, topRight: 10 })

              Column() {
                Text(item.name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#333333')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Row() {
                  Text('⭐ ' + item.rating)
                    .fontSize(11)
                    .fontColor('#FF6600')
                  Text(item.price)
                    .fontSize(11)
                    .fontColor('#999999')
                    .margin({ left: 6 })
                }
                .width('100%')
                .margin({ top: 4 })

                Row() {
                  ForEach(item.tags, (tag: string) => {
                    Text(tag)
                      .fontSize(10)
                      .fontColor('#FF6600')
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .border({ width: 0.5, color: '#FF6600', radius: 4 })
                      .margin({ right: 4 })
                  })
                }
                .width('100%')
                .margin({ top: 4 })
              }
              .width('100%')
              .padding({ left: 8, right: 8, top: 8, bottom: 10 })
              .alignItems(HorizontalAlign.Start)
            }
            .width(150)
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .margin({ right: 10 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/NoteDetailPage', params: { name: item.name } });
            })
          })
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(210)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16, bottom: 12 })
  }

  @Builder
  NearbySection() {
    Column() {
      Row() {
        Text('📍 附近美食')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Text('更多 >')
          .fontSize(12)
          .fontColor('#999999')
          .onClick(() => {
            router.pushUrl({ url: 'pages/FoodListPage' });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      // Nearby items
      ForEach(['川味小馆', '粤式茶餐厅', '日式拉面馆', '韩式烤肉店'], (name: string, index: number) => {
        Row() {
          Text(['🌶️', '🥘', '🍜', '🥩'][index])
            .fontSize(28)
            .width(50)
            .height(50)
            .textAlign(TextAlign.Center)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)

          Column() {
            Text(name)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
            Row() {
              Text('⭐ ' + ['4.5', '4.3', '4.6', '4.4'][index])
                .fontSize(11)
                .fontColor('#FF6600')
              Text(['¥60/人', '¥80/人', '¥70/人', '¥90/人'][index])
                .fontSize(11)
                .fontColor('#999999')
                .margin({ left: 8 })
              Text(['1.2km', '0.8km', '1.5km', '2.0km'][index])
                .fontSize(11)
                .fontColor('#999999')
                .margin({ left: 8 })
            }
            .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: 10 })

          Text('去探店 >')
            .fontSize(11)
            .fontColor('#FF6600')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/NoteDetailPage', params: { name: name } });
        })
      })

      // Divider between items handled by default
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16, bottom: 16 })
  }
}
