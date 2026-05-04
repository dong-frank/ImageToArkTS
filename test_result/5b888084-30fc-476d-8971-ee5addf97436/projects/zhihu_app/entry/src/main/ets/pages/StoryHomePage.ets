import { router } from '@kit.ArkUI';
import { NavigationService } from '../common/services/NavigationService';

// ══════════════════════════════════════════
// Data types
// ══════════════════════════════════════════

interface RankingItem {
  rank: number;
  title: string;
  stats: string;
  tags: string[];
  coverColor: string;
}

interface CarouselCard {
  title: string;
  subtitle: string;
  coverColor: string;
}

// ══════════════════════════════════════════
// Data providers
// ══════════════════════════════════════════

function getRankingList(): RankingItem[] {
  return [
    { rank: 1, title: '沈栀', stats: '6.1万赞', tags: ['言情', '女配'], coverColor: '#FFE4C4' },
    { rank: 2, title: '情蛊', stats: '4874 赞', tags: ['言情', '虐恋'], coverColor: '#D4E4F7' },
    { rank: 3, title: '河清海晏', stats: '63.8 万赞', tags: ['言情', '警察'], coverColor: '#E8D8F0' },
    { rank: 4, title: '映荷', stats: '5.5 万赞', tags: ['言情'], coverColor: '#D4F0D4' },
    { rank: 5, title: '野蛮', stats: '18.2 万赞', tags: ['现实'], coverColor: '#FFF0D4' },
    { rank: 6, title: '最后', stats: '6.7 万赞', tags: ['言情'], coverColor: '#FDD4D4' }
  ];
}

function getTodaysPicks(): CarouselCard[] {
  return [
    { title: '狐魅人妻', subtitle: '4067 精品', coverColor: '#F5E4D0' },
    { title: '军训不能搞', subtitle: '特破', coverColor: '#D4E4F7' },
    { title: '零次救赎', subtitle: '57万 精品', coverColor: '#E8D8F0' },
    { title: '爱情圈套', subtitle: '10万 精品', coverColor: '#FDD4D4' }
  ];
}

// ══════════════════════════════════════════
// Sub-component: SearchBar
// ══════════════════════════════════════════

@Component
struct SearchBar {
  @Prop placeholder: string = '搜索';
  onTap?: () => void;

  build() {
    Row() {
      Text('🔍')
        .fontSize(18)
        .margin({ right: 8 })

      Text(this.placeholder)
        .fontSize(14)
        .fontColor('#999999')
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(36)
    .backgroundColor('#F5F5F5')
    .borderRadius(18)
    .padding({ left: 14, right: 14 })
    .onClick(() => {
      if (this.onTap) {
        this.onTap();
      }
    })
  }
}

// ══════════════════════════════════════════
// Sub-component: ChannelTabBar
// ══════════════════════════════════════════

@Component
struct ChannelTabBar {
  @Prop tabs: string[] = [];
  @Prop selectedIndex: number = 0;
  onTabChange?: (index: number) => void;

  build() {
    Scroll() {
      Row({ space: 0 }) {
        ForEach(this.tabs, (tab: string, index: number) => {
          Column({ space: 4 }) {
            Text(tab)
              .fontSize(index === this.selectedIndex ? 17 : 15)
              .fontWeight(index === this.selectedIndex ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(index === this.selectedIndex ? '#111111' : '#666666')
              .padding({ left: 12, right: 12 })

            if (index === this.selectedIndex) {
              Divider()
                .width(20)
                .height(3)
                .color('#0066FF')
                .borderRadius(1.5)
            } else {
              Divider()
                .width(20)
                .height(3)
                .color(Color.Transparent)
                .borderRadius(1.5)
            }
          }
          .onClick(() => {
            if (this.onTabChange) {
              this.onTabChange(index);
            }
          })
        })
      }
      .padding({ left: 4, right: 4 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }
}

// ══════════════════════════════════════════
// Sub-component: MembershipBanner
// ══════════════════════════════════════════

@Component
struct MembershipBanner {
  onTap?: () => void;

  build() {
    Row() {
      // Left: icon area
      Row() {
        Text('📚')
          .fontSize(28)
      }
      .width(48)
      .height(48)
      .backgroundColor('#F5E6D0')
      .borderRadius(8)
      .justifyContent(FlexAlign.Center)

      // Center: text content
      Column({ space: 4 }) {
        Text('开通盐选会员')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#5C3D2E')
        Text('畅享10w+优质内容')
          .fontSize(12)
          .fontColor('#8B6914')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      // Right: CTA
      Row({ space: 4 }) {
        Text('最低 0.3 元/天')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#5C3D2E')
        Text('›')
          .fontSize(16)
          .fontColor('#5C3D2E')
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor('#FFF8E7')
    .borderRadius(10)
    .onClick(() => {
      if (this.onTap) {
        this.onTap();
      }
    })
  }
}

// ══════════════════════════════════════════
// Sub-component: QuickAccessRow
// ══════════════════════════════════════════

@Component
struct QuickAccessRow {
  onBookshelfTap?: () => void;
  onCategoryTap?: () => void;

  build() {
    Row({ space: 12 }) {
      // 书架
      Row({ space: 6 }) {
        Text('📖')
          .fontSize(18)
        Text('书架')
          .fontSize(14)
          .fontColor('#333333')
      }
      .layoutWeight(1)
      .height(44)
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        if (this.onBookshelfTap) {
          this.onBookshelfTap();
        }
      })

      // 分类
      Row({ space: 6 }) {
        Text('📂')
          .fontSize(18)
        Text('分类')
          .fontSize(14)
          .fontColor('#333333')
      }
      .layoutWeight(1)
      .height(44)
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        if (this.onCategoryTap) {
          this.onCategoryTap();
        }
      })
    }
    .width('100%')
  }
}

// ══════════════════════════════════════════
// Sub-component: RankingListSection
// ══════════════════════════════════════════

@Component
struct RankingListSection {
  @State selectedSubTab: number = 0;
  private subTabs: string[] = ['推荐榜', '新书榜', '热度榜'];
  onItemTap?: (item: RankingItem) => void;

  build() {
    Column({ space: 0 }) {
      // Header
      Row() {
        Text('故事排行榜')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')

        Blank()

        Text('完整榜单')
          .fontSize(12)
          .fontColor('#999999')
        Text(' ›')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ left: 4, right: 4, bottom: 12 })

      // Sub-tabs: 推荐榜 / 新书榜 / 热度榜
      Row({ space: 0 }) {
        ForEach(this.subTabs, (tab: string, index: number) => {
          Text(tab)
            .fontSize(14)
            .fontWeight(index === this.selectedSubTab ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(index === this.selectedSubTab ? '#111111' : '#666666')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .borderWidth({
              bottom: index === this.selectedSubTab ? 2 : 0
            })
            .borderColor('#0066FF')
            .onClick(() => {
              this.selectedSubTab = index;
            })
        })
      }
      .width('100%')
      .margin({ bottom: 12 })

      // Ranking items
      Column({ space: 0 }) {
        ForEach(getRankingList(), (item: RankingItem, index: number) => {
          Row() {
            // Rank number
            Text(item.rank.toString())
              .fontSize(18)
              .fontWeight(item.rank <= 3 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(item.rank <= 3 ? '#FF6600' : '#999999')
              .width(28)
              .textAlign(TextAlign.Center)

            // Cover placeholder
            Row()
              .width(56)
              .height(72)
              .backgroundColor(item.coverColor)
              .borderRadius(6)
              .margin({ left: 12, right: 12 })

            // Text content
            Column({ space: 4 }) {
              Text(item.title)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#111111')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Row({ space: 8 }) {
                if (item.tags.length > 0) {
                  Text(item.tags.join(' · '))
                    .fontSize(11)
                    .fontColor('#999999')
                }
                Text(item.stats)
                  .fontSize(11)
                  .fontColor('#FF6600')
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            // Arrow
            Text('›')
              .fontSize(16)
              .fontColor('#CCCCCC')
              .margin({ left: 8 })
          }
          .width('100%')
          .padding({ top: 10, bottom: 10, left: 4, right: 8 })
          .borderWidth({
            bottom: index < getRankingList().length - 1 ? 0.5 : 0
          })
          .borderColor('#EEEEEE')
          .onClick(() => {
            if (this.onItemTap) {
              this.onItemTap(item);
            }
          })
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
  }
}

// ══════════════════════════════════════════
// Sub-component: TodaysPicksSection
// ══════════════════════════════════════════

@Component
struct TodaysPicksSection {
  @State picks: CarouselCard[] = getTodaysPicks();
  onCardTap?: (card: CarouselCard) => void;
  onRefresh?: () => void;

  build() {
    Column({ space: 10 }) {
      // Header
      Row() {
        Text('今日精选')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')

        Blank()

        Row({ space: 4 }) {
          Text('换一换')
            .fontSize(12)
            .fontColor('#0066FF')
          Text('🔄')
            .fontSize(12)
        }
        .onClick(() => {
          if (this.onRefresh) {
            this.onRefresh();
          }
        })
      }
      .width('100%')
      .padding({ left: 4, right: 4 })

      // Horizontal carousel of cards
      Scroll() {
        Row({ space: 12 }) {
          ForEach(this.picks, (card: CarouselCard) => {
            Column({ space: 6 }) {
              // Cover image placeholder
              Row()
                .width(120)
                .height(160)
                .backgroundColor(card.coverColor)
                .borderRadius(8)

              // Title
              Text(card.title)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#111111')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width(120)

              // Subtitle
              Text(card.subtitle)
                .fontSize(11)
                .fontColor('#999999')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width(120)
            }
            .onClick(() => {
              if (this.onCardTap) {
                this.onCardTap(card);
              }
            })
          })
        }
        .padding({ left: 4, right: 4 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
  }
}

// ══════════════════════════════════════════
// Bottom navigation bar
// Reuses the same pattern as HomeFeedPage's
// bottom nav — consistent across all pages
// in the bottom-tab navigation system.
// ══════════════════════════════════════════

@Component
struct StoryBottomNavBar {
  @Prop selectedTab: string = '首页';

  build() {
    Row() {
      // 首页
      Column({ space: 2 }) {
        Text('🏠')
          .fontSize(22)
        Text('首页')
          .fontSize(10)
          .fontColor(this.selectedTab === '首页' ? '#0066FF' : '#999999')
          .fontWeight(this.selectedTab === '首页' ? FontWeight.Medium : FontWeight.Regular)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        if (this.selectedTab !== '首页') {
          router.replaceUrl({ url: NavigationService.routeFor('首页信息流') });
        }
      })

      // 直答
      Column({ space: 2 }) {
        Text('💡')
          .fontSize(22)
        Text('直答')
          .fontSize(10)
          .fontColor(this.selectedTab === '直答' ? '#0066FF' : '#999999')
          .fontWeight(this.selectedTab === '直答' ? FontWeight.Medium : FontWeight.Regular)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        router.replaceUrl({ url: NavigationService.routeFor('直答/提问首页') });
      })

      // + 按钮
      Column() {
        Circle()
          .width(44)
          .height(44)
          .fill('#0066FF')
          .shadow({ radius: 8, color: '#330066FF', offsetY: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        router.pushUrl({ url: NavigationService.routeFor('内容编辑器') });
      })

      // 消息
      Column({ space: 2 }) {
        Stack() {
          Text('🔔')
            .fontSize(22)
          Text('10')
            .fontSize(9)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF4444')
            .borderRadius(8)
            .width(16)
            .height(16)
            .textAlign(TextAlign.Center)
            .position({ x: 12, y: -6 })
        }
        Text('消息')
          .fontSize(10)
          .fontColor(this.selectedTab === '消息' ? '#0066FF' : '#999999')
          .fontWeight(this.selectedTab === '消息' ? FontWeight.Medium : FontWeight.Regular)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        router.replaceUrl({ url: NavigationService.routeFor('消息列表') });
      })

      // 我的
      Column({ space: 2 }) {
        Text('👤')
          .fontSize(22)
        Text('我的')
          .fontSize(10)
          .fontColor(this.selectedTab === '我的' ? '#0066FF' : '#999999')
          .fontWeight(this.selectedTab === '我的' ? FontWeight.Medium : FontWeight.Regular)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        router.replaceUrl({ url: NavigationService.routeFor('个人中心') });
      })
    }
    .width('100%')
    .height(56)
    .padding({ top: 4, bottom: 4 })
    .backgroundColor('#FFFFFF')
    .borderWidth({ top: 1 })
    .borderColor('#EEEEEE')
  }
}

// ══════════════════════════════════════════
// Main Page: StoryHomePage
// ══════════════════════════════════════════

@Entry
@Component
struct StoryHomePage {
  @State selectedTabIndex: number = 3; // 故事 = index 3
  private channelTabs: string[] = ['关注', '推荐', '热榜', '故事', '知识', '圈子', '专栏', '听'];

  handleSearchTap(): void {
    // Search page not yet in scope; log intent
    console.info('[StoryHomePage] Search tapped - search page not yet registered');
  }

  handleChannelTabChange(index: number): void {
    const tab = this.channelTabs[index];

    // Keep "故事" in-page (already selected)
    if (index === 3) {
      return;
    }

    // Channel-level navigation:
    // 关注/推荐/热榜 → HomeFeedPage (back to parent)
    if (tab === '关注' || tab === '推荐' || tab === '热榜') {
      router.back();
      return;
    }

    // 知识 → KnowledgeHomePage
    if (tab === '知识') {
      router.replaceUrl({ url: NavigationService.routeFor('知识频道') });
      return;
    }

    // 圈子/专栏/听 → back to HomeFeedPage
    router.back();
  }

  handleMembershipTap(): void {
    // Membership purchase page not yet in scope
    console.info('[StoryHomePage] Membership banner tapped - membership page not yet registered');
  }

  handleBookshelfTap(): void {
    router.pushUrl({ url: NavigationService.routeFor('我的书架') });
  }

  handleCategoryTap(): void {
    // Category browse page not yet in scope
    console.info('[StoryHomePage] Category tapped - category page not yet registered');
  }

  handleRankingItemTap(_item: RankingItem): void {
    // Story detail page not yet registered; log intent
    console.info('[StoryHomePage] Ranking item tapped - story detail page not yet registered');
  }

  handleCarouselCardTap(_card: CarouselCard): void {
    // Story detail page not yet registered; log intent
    console.info('[StoryHomePage] Carousel card tapped - story detail page not yet registered');
  }

  handleCarouselRefresh(): void {
    // Shuffle carousel cards for demo effect
    console.info('[StoryHomePage] Refresh carousel');
  }

  build() {
    Column() {
      // ── Fixed header: search bar ──
      Row() {
        SearchBar({
          placeholder: '南瑞继保硕士3年后待遇',
          onTap: (): void => { this.handleSearchTap(); }
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 6 })
      .backgroundColor('#FFFFFF')

      // ── Channel tab bar ──
      ChannelTabBar({
        tabs: this.channelTabs,
        selectedIndex: this.selectedTabIndex,
        onTabChange: (index: number): void => { this.handleChannelTabChange(index); }
      })
        .padding({ bottom: 6 })
        .backgroundColor('#FFFFFF')

      // Header divider
      Divider()
        .height(1)
        .color('#EEEEEE')

      // ── Scrollable content area ──
      Scroll() {
        Column({ space: 10 }) {
          // Membership banner
          MembershipBanner({
            onTap: (): void => { this.handleMembershipTap(); }
          })

          // Quick access row: 书架 / 分类
          QuickAccessRow({
            onBookshelfTap: (): void => { this.handleBookshelfTap(); },
            onCategoryTap: (): void => { this.handleCategoryTap(); }
          })

          // Story ranking list
          RankingListSection({
            onItemTap: (item: RankingItem): void => { this.handleRankingItemTap(item); }
          })

          // Today's picks carousel
          TodaysPicksSection({
            onCardTap: (card: CarouselCard): void => { this.handleCarouselCardTap(card); },
            onRefresh: (): void => { this.handleCarouselRefresh(); }
          })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .width('100%')

      // ── Fixed bottom navigation ──
      StoryBottomNavBar({ selectedTab: '首页' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
