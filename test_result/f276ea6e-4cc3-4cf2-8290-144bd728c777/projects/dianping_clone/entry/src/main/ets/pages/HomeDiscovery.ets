import router from '@ohos.router';
import { BottomNavBar } from '../common/components/BottomNavBar';

// Category data model
interface CategoryItem {
  label: string;
  iconHint: string;
  route?: string;
}

// Post card data model
interface PostCard {
  title: string;
  author: string;
  likeCount: number;
  imageColor: string;
}

@Entry
@Component
struct HomeDiscovery {
  @State activeTab: string = '首页';
  @State selectedSegment: number = 0;

  private segments: string[] = ['附近', '品质外卖', '热点', '美食', '旅行'];

  private categories: CategoryItem[] = [
    { label: '美食', iconHint: 'chicken', route: 'pages/FoodList' },
    { label: '休闲玩乐', iconHint: 'footprint' },
    { label: '酒店民宿', iconHint: 'building' },
    { label: '景点游玩', iconHint: 'palm_tree' },
    { label: '电影演出', iconHint: 'cat_face' },
    { label: '医疗口腔', iconHint: 'plus_sign' },
    { label: '特价团', iconHint: 'fire' },
    { label: '医学美容', iconHint: 'face_mask' },
    { label: '生活服务', iconHint: 'spray_bottle' },
    { label: '丽人美发', iconHint: 'woman_hair' }
  ];

  private posts: PostCard[] = [
    {
      title: '栖霞山最难找的店，也是我最想私藏的店 ☕',
      author: '食尚田',
      likeCount: 13,
      imageColor: '#E8D5B7'
    },
    {
      title: '南京记住这个位置！！！真的会哇出声！！！',
      author: '晶',
      likeCount: 372,
      imageColor: '#D4C5B9'
    },
    {
      title: '南京新街口！好好吃啊！',
      author: '美食达人小王',
      likeCount: 56,
      imageColor: '#C5D5C5'
    },
    {
      title: '藏在老门东巷子里的宝藏咖啡馆',
      author: '探店小能手',
      likeCount: 28,
      imageColor: '#D5C5C5'
    }
  ];

  // Icon color mapping for category items
  getCategoryColor(label: string): string {
    const colorMap: Record<string, string> = {
      '美食': '#FF6B35',
      '休闲玩乐': '#4ECDC4',
      '酒店民宿': '#7B68EE',
      '景点游玩': '#2ECC71',
      '电影演出': '#E74C3C',
      '医疗口腔': '#3498DB',
      '特价团': '#F39C12',
      '医学美容': '#E91E63',
      '生活服务': '#1ABC9C',
      '丽人美发': '#9B59B6'
    };
    return colorMap[label] || '#FF6600';
  }

  // Get emoji icon for category
  getCategoryIcon(label: string): string {
    const iconMap: Record<string, string> = {
      '美食': '🍗',
      '休闲玩乐': '👣',
      '酒店民宿': '🏨',
      '景点游玩': '🌴',
      '电影演出': '🎬',
      '医疗口腔': '🦷',
      '特价团': '🔥',
      '医学美容': '💆',
      '生活服务': '🧴',
      '丽人美发': '💇'
    };
    return iconMap[label] || '📌';
  }

  handleCategoryTap(category: CategoryItem) {
    if (category.route) {
      router.pushUrl({ url: category.route });
    }
  }

  handlePostTap(post: PostCard) {
    router.pushUrl({ url: 'pages/ContentDetail' });
  }

  handleOverlayTrigger() {
    // Action hub overlay - triggered by '+' button
    // This will be implemented when action_hub_overlay is built
    console.info('Action hub overlay triggered');
  }

  build() {
    Column() {
      // ===== Top Bar =====
      Row() {
        // "关注" button
        Text('关注')
          .fontSize(14)
          .fontColor('#333333')
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .borderRadius(4)
          .onClick(() => {
            console.info('关注 clicked');
          })

        Blank()

        // City dropdown "南京"
        Row({ space: 2 }) {
          Text('南京')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          Text('▼')
            .fontSize(10)
            .fontColor('#999999')
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .onClick(() => {
          console.info('城市选择下拉 clicked - target page not yet available');
        })

        Blank()

        // Segmented control
        Row({ space: 0 }) {
          ForEach(this.segments, (segment: string, index: number) => {
            Text(segment)
              .fontSize(13)
              .fontColor(this.selectedSegment === index ? '#FFFFFF' : '#666666')
              .backgroundColor(this.selectedSegment === index ? '#FF6600' : '#F5F5F5')
              .borderRadius(14)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ left: 2, right: 2 })
              .onClick(() => {
                this.selectedSegment = index;
              })
          })
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')

      // ===== Search Bar =====
      Row({ space: 8 }) {
        // Scan icon
        Text('📷')
          .fontSize(20)

        // Search input
        TextInput({ placeholder: '克丽缇娜美容院' })
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .height(36)
          .layoutWeight(1)
          .padding({ left: 12, right: 12 })

        // Camera icon
        Text('📸')
          .fontSize(20)

        // Search button
        Text('搜索')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF6600')
          .borderRadius(18)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .onClick(() => {
            console.info('搜索 clicked - target page not yet available');
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor('#FFFFFF')

      // ===== Scrollable Content =====
      Scroll() {
        Column({ space: 0 }) {
          // ===== Category Grid (2×5) =====
          Column() {
            // Row 1: first 5 categories
            Row() {
              ForEach(this.categories.slice(0, 5), (category: CategoryItem) => {
                Column({ space: 4 }) {
                  Text(this.getCategoryIcon(category.label))
                    .fontSize(28)
                  Text(category.label)
                    .fontSize(11)
                    .fontColor('#333333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('20%')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .padding({ top: 10, bottom: 6 })
                .onClick(() => {
                  this.handleCategoryTap(category);
                })
              })
            }
            .width('100%')

            // Row 2: last 5 categories
            Row() {
              ForEach(this.categories.slice(5, 10), (category: CategoryItem) => {
                Column({ space: 4 }) {
                  Text(this.getCategoryIcon(category.label))
                    .fontSize(28)
                  Text(category.label)
                    .fontSize(11)
                    .fontColor('#333333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('20%')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .padding({ top: 6, bottom: 10 })
                .onClick(() => {
                  this.handleCategoryTap(category);
                })
              })
            }
            .width('100%')
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 12, right: 12, top: 8, bottom: 8 })
          .padding({ top: 4, bottom: 4 })

          // ===== Promo Banner Row =====
          Row({ space: 8 }) {
            // 点评榜单 card
            Column({ space: 6 }) {
              Row() {
                Text('点评榜单')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                Text(' 跟榜吃领半价神券 >')
                  .fontSize(11)
                  .fontColor('#FF6600')
              }
              .width('100%')

              Row({ space: 6 }) {
                Column() {
                  Text('🥢')
                    .fontSize(24)
                }
                .width(40)
                .height(40)
                .borderRadius(8)
                .backgroundColor('#FFF5EE')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)

                Column({ space: 2 }) {
                  Text('鮨鸟歡·烧鸟yakitori')
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Row({ space: 4 }) {
                    Text('热门榜第3名')
                      .fontSize(10)
                      .fontColor('#FF6600')
                      .backgroundColor('#FFF0E6')
                      .borderRadius(3)
                      .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                    Text('4.7km')
                      .fontSize(10)
                      .fontColor('#999999')
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
            }
            .layoutWeight(1)
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .padding(10)
            .onClick(() => {
              console.info('榜单卡片 clicked - target page not yet available');
            })

            // 免费试 card
            Column({ space: 6 }) {
              Row() {
                Text('免费试')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                Text(' 6303个活动在线 >')
                  .fontSize(11)
                  .fontColor('#FF6600')
              }
              .width('100%')

              Row({ space: 6 }) {
                Column() {
                  Text('🎁')
                    .fontSize(24)
                }
                .width(40)
                .height(40)
                .borderRadius(8)
                .backgroundColor('#FFF5EE')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)

                Column({ space: 2 }) {
                  Text('野人先生免费抽')
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Row({ space: 4 }) {
                    Text('¥0')
                      .fontSize(12)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FF6600')
                    Text('¥28')
                      .fontSize(10)
                      .fontColor('#CCCCCC')
                      .decoration({ type: TextDecorationType.LineThrough })
                    Text('1.3km')
                      .fontSize(10)
                      .fontColor('#999999')
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
            }
            .layoutWeight(1)
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .padding(10)
            .onClick(() => {
              console.info('免费试卡片 clicked - target page not yet available');
            })
          }
          .width('100%')
          .padding({ left: 12, right: 12 })
          .margin({ bottom: 8 })

          // ===== Section Header =====
          Row() {
            Text('为你推荐')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 4, bottom: 8 })

          // ===== Two-Column Content Feed =====
          Row({ space: 8 }) {
            // Left column
            Column({ space: 8 }) {
              ForEach(this.posts.filter((_: PostCard, index: number) => index % 2 === 0),
                (post: PostCard) => {
                  Column({ space: 0 }) {
                    // Image placeholder
                    Column() {
                      Text('📷')
                        .fontSize(32)
                        .fontColor('#CCCCCC')
                    }
                    .width('100%')
                    .height(140)
                    .backgroundColor(post.imageColor)
                    .borderRadius({ topLeft: 10, topRight: 10 })
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)

                    // Text content
                    Column({ space: 6 }) {
                      Text(post.title)
                        .fontSize(13)
                        .fontColor('#333333')
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .lineHeight(18)

                      Row({ space: 4 }) {
                        Text(post.author)
                          .fontSize(11)
                          .fontColor('#999999')
                          .layoutWeight(1)
                        Row({ space: 2 }) {
                          Text('❤️')
                            .fontSize(10)
                          Text(post.likeCount.toString())
                            .fontSize(10)
                            .fontColor('#999999')
                        }
                      }
                      .width('100%')
                    }
                    .width('100%')
                    .padding({ left: 8, right: 8, top: 8, bottom: 10 })
                    .alignItems(HorizontalAlign.Start)
                  }
                  .width('100%')
                  .backgroundColor('#FFFFFF')
                  .borderRadius(10)
                  .onClick(() => {
                    this.handlePostTap(post);
                  })
                })
            }
            .layoutWeight(1)

            // Right column
            Column({ space: 8 }) {
              ForEach(this.posts.filter((_: PostCard, index: number) => index % 2 === 1),
                (post: PostCard) => {
                  Column({ space: 0 }) {
                    // Image placeholder
                    Column() {
                      Text('📷')
                        .fontSize(32)
                        .fontColor('#CCCCCC')
                    }
                    .width('100%')
                    .height(140)
                    .backgroundColor(post.imageColor)
                    .borderRadius({ topLeft: 10, topRight: 10 })
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)

                    // Text content
                    Column({ space: 6 }) {
                      Text(post.title)
                        .fontSize(13)
                        .fontColor('#333333')
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .lineHeight(18)

                      Row({ space: 4 }) {
                        Text(post.author)
                          .fontSize(11)
                          .fontColor('#999999')
                          .layoutWeight(1)
                        Row({ space: 2 }) {
                          Text('❤️')
                            .fontSize(10)
                          Text(post.likeCount.toString())
                            .fontSize(10)
                            .fontColor('#999999')
                        }
                      }
                      .width('100%')
                    }
                    .width('100%')
                    .padding({ left: 8, right: 8, top: 8, bottom: 10 })
                    .alignItems(HorizontalAlign.Start)
                  }
                  .width('100%')
                  .backgroundColor('#FFFFFF')
                  .borderRadius(10)
                  .onClick(() => {
                    this.handlePostTap(post);
                  })
                })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 8 })

          // Bottom spacer for tab bar clearance
          Column()
            .height(8)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F0F0F0')

      // ===== Bottom Tab Bar (shared component) =====
      BottomNavBar({
        activeTab: this.activeTab,
        onOverlayTrigger: () => {
          this.handleOverlayTrigger();
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F0F0')
  }
}
