import { router } from '@kit.ArkUI';
import { NavigationService } from '../common/services/NavigationService';

// ══════════════════════════════════════════
// Data types
// ══════════════════════════════════════════

interface FeedItem {
  id: string;
  title: string;
  author: string;
  meta: string;
  excerpt: string;
  upvotes: number;
  stars: number;
  comments: number;
  tags: string[];
  hasImage: boolean;
  imageCount: number;
}

interface HotItem {
  rank: number;
  title: string;
  heat: string;
}

interface CreatorQuickAccess {
  name: string;
  avatarColor: string;
}

class QuickAction {
  label: string;
  icon: string;

  constructor(label: string, icon: string) {
    this.label = label;
    this.icon = icon;
  }
}

// ══════════════════════════════════════════
// Data providers
// ══════════════════════════════════════════

function getRecommendedFeed(): FeedItem[] {
  return [
    {
      id: '1',
      title: '无大算力时，作为学生，LLM 还有哪些值得做的研究？',
      author: 'Cv大法代码酱',
      meta: '2.4 万人关注',
      excerpt: '看到你说研0非LLM相关，手里没大算力，又觉得RAG和Agent偏工程没什么可研究的...',
      upvotes: 3424,
      stars: 5917,
      comments: 95,
      tags: [],
      hasImage: false,
      imageCount: 0
    },
    {
      id: '2',
      title: '为什么有钱人皮肤都这么好？',
      author: '达布溜溜梅',
      meta: '',
      excerpt: '我老妈是美容院的首席成分研发师...',
      upvotes: 13000,
      stars: 28000,
      comments: 962,
      tags: ['50+购买'],
      hasImage: false,
      imageCount: 0
    },
    {
      id: '3',
      title: 'DeepSeek-V4 技术报告一手解读来了',
      author: '欠阿贝尔两块钱',
      meta: 'verified',
      excerpt: 'coding和agent能力加强了不少，比GLM-5.1稍强一些...',
      upvotes: 75,
      stars: 170,
      comments: 6,
      tags: [],
      hasImage: true,
      imageCount: 2
    }
  ];
}

function getFollowingCreators(): CreatorQuickAccess[] {
  return [
    { name: '张小北', avatarColor: '#FF6B6B' },
    { name: '李不太白', avatarColor: '#4ECDC4' },
    { name: '王尼玛', avatarColor: '#45B7D1' },
    { name: '赵小姐', avatarColor: '#96CEB4' },
    { name: '刘看山', avatarColor: '#FFEAA7' },
    { name: '陈同学', avatarColor: '#DDA0DD' }
  ];
}

function getFollowingFilters(): string[] {
  return ['精选', '最新', '想法'];
}

function getHotQuickActions(): QuickAction[] {
  return [
    new QuickAction('每周必看', '🔥'),
    new QuickAction('知乎日报', '📰'),
    new QuickAction('错过热议', '💬'),
    new QuickAction('辟谣专区', '🛡️')
  ];
}

function getHotRanking(): HotItem[] {
  return [
    { rank: 1, title: 'DeepSeek-V4 发布，性能全面超越 GPT-5', heat: '9812 万热度' },
    { rank: 2, title: '如何看待 2026 年 AI 行业薪资暴涨？', heat: '8754 万热度' },
    { rank: 3, title: '特斯拉 Optimus 机器人开始在工厂试运行', heat: '7621 万热度' },
    { rank: 4, title: '《黑神话：悟空2》首支预告片发布', heat: '6987 万热度' },
    { rank: 5, title: '中国航天：2030 年载人登月计划细节公布', heat: '6543 万热度' },
    { rank: 6, title: '为什么越来越多年轻人选择不婚？', heat: '5890 万热度' },
    { rank: 7, title: '2026 年高考改革最新方案解读', heat: '5234 万热度' },
    { rank: 8, title: '日本福岛核污水排放第五轮监测报告', heat: '4876 万热度' }
  ];
}

// ══════════════════════════════════════════
// Format helpers
// ══════════════════════════════════════════

function formatCount(n: number): string {
  if (n >= 10000) {
    const v = n / 10000;
    const s = v.toFixed(1);
    if (s.endsWith('.0')) {
      return s.substring(0, s.length - 2) + ' 万';
    }
    return s + ' 万';
  }
  if (n >= 1000) {
    const v = n / 1000;
    const s = v.toFixed(1);
    if (s.endsWith('.0')) {
      return s.substring(0, s.length - 2) + 'k';
    }
    return s + 'k';
  }
  return n.toString();
}

// ══════════════════════════════════════════
// Sub-component: SearchBar
// ══════════════════════════════════════════

@Component
struct SearchBar {
  @Prop placeholder: string = '';
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
// Sub-component: FeedCardRecommended
// ══════════════════════════════════════════

@Component
struct FeedCardRecommended {
  @Prop item: FeedItem = {
    id: '',
    title: '',
    author: '',
    meta: '',
    excerpt: '',
    upvotes: 0,
    stars: 0,
    comments: 0,
    tags: [],
    hasImage: false,
    imageCount: 0
  };
  onCardTap?: () => void;
  onCloseTap?: () => void;

  build() {
    Column({ space: 8 }) {
      // Header: author + close
      Row() {
        Row({ space: 6 }) {
          Circle()
            .width(20)
            .height(20)
            .fill('#E0E0E0')

          Text(this.item.author)
            .fontSize(13)
            .fontColor('#666666')
            .maxLines(1)
        }

        Blank()

        Text('×')
          .fontSize(18)
          .fontColor('#999999')
          .padding({ left: 8, right: 4, top: 0, bottom: 0 })
          .onClick(() => {
            if (this.onCloseTap) {
              this.onCloseTap();
            }
          })
      }
      .width('100%')

      // Title
      Text(this.item.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#111111')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .onClick(() => {
          if (this.onCardTap) {
            this.onCardTap();
          }
        })

      // Excerpt
      if (this.item.excerpt.length > 0) {
        Text(this.item.excerpt)
          .fontSize(14)
          .fontColor('#888888')
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }

      // Tags
      if (this.item.tags.length > 0) {
        Row({ space: 8 }) {
          ForEach(this.item.tags, (tag: string) => {
            Text(tag)
              .fontSize(12)
              .fontColor('#0066FF')
              .backgroundColor('#EBF3FF')
              .borderRadius(4)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          })
        }
      }

      // Image placeholder
      if (this.item.hasImage) {
        Row({ space: 6 }) {
          ForEach(this.getItemImagePlaceholders(this.item.imageCount),
            (index: number) => {
              Row()
                .width(120)
                .height(80)
                .backgroundColor('#F0F0F0')
                .borderRadius(6)
                .justifyContent(FlexAlign.Center)
            })
        }
      }

      // Stats bar
      Row({ space: 16 }) {
        Row({ space: 4 }) {
          Text('▲')
            .fontSize(12)
            .fontColor('#666666')
          Text(formatCount(this.item.upvotes))
            .fontSize(12)
            .fontColor('#666666')
        }

        Row({ space: 4 }) {
          Text('★')
            .fontSize(12)
            .fontColor('#666666')
          Text(formatCount(this.item.stars))
            .fontSize(12)
            .fontColor('#666666')
        }

        Row({ space: 4 }) {
          Text('💬')
            .fontSize(12)
            .fontColor('#666666')
          Text(formatCount(this.item.comments))
            .fontSize(12)
            .fontColor('#666666')
        }

        Blank()

        Row({ space: 4 }) {
          Text('⋯')
            .fontSize(14)
            .fontColor('#999999')
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
  }

  getItemImagePlaceholders(count: number): number[] {
    let result: number[] = [];
    for (let i = 0; i < count; i++) {
      result.push(i);
    }
    return result;
  }
}

// ══════════════════════════════════════════
// Sub-component: FeedFollowingContent
// ══════════════════════════════════════════

@Component
struct FeedFollowingContent {
  onCardTap?: () => void;

  build() {
    Column({ space: 12 }) {
      // Creator quick access row
      Column({ space: 10 }) {
        Text('我的关注')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .width('100%')

        Scroll() {
          Row({ space: 16 }) {
            ForEach(getFollowingCreators(), (creator: CreatorQuickAccess) => {
              Column({ space: 4 }) {
                Circle()
                  .width(44)
                  .height(44)
                  .fill(creator.avatarColor)
                Text(creator.name)
                  .fontSize(11)
                  .fontColor('#666666')
                  .maxLines(1)
              }
              .alignItems(HorizontalAlign.Center)
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

      // Filter bar
      Row({ space: 0 }) {
        ForEach(getFollowingFilters(), (filter: string, index: number) => {
          Text(filter)
            .fontSize(13)
            .fontWeight(index === 0 ? FontWeight.Medium : FontWeight.Regular)
            .fontColor(index === 0 ? '#0066FF' : '#666666')
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .borderRadius(14)
            .backgroundColor(index === 0 ? '#EBF3FF' : '#F5F5F5')
            .margin({ right: 8 })
        })
      }
      .width('100%')

      // Empty state for following feed
      Column({ space: 8 }) {
        Text('你关注的用户暂无新动态')
          .fontSize(14)
          .fontColor('#999999')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 40, bottom: 40 })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
    }
    .width('100%')
  }
}

// ══════════════════════════════════════════
// Sub-component: FeedHotContent
// ══════════════════════════════════════════

@Component
struct FeedHotContent {
  onCardTap?: () => void;

  build() {
    Column({ space: 12 }) {
      // Quick action row
      Row({ space: 8 }) {
        ForEach(getHotQuickActions(), (action: QuickAction) => {
          Column({ space: 6 }) {
            Text(action.icon)
              .fontSize(24)
            Text(action.label)
              .fontSize(11)
              .fontColor('#666666')
          }
          .width(72)
          .height(72)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)

      // Hot ranking list
      Column({ space: 0 }) {
        ForEach(getHotRanking(), (item: HotItem, index: number) => {
          Row() {
            Row() {
              Text(item.rank.toString())
                .fontSize(16)
                .fontWeight(item.rank <= 3 ? FontWeight.Bold : FontWeight.Regular)
                .fontColor(item.rank <= 3 ? '#FF4444' : '#999999')
                .width(24)
                .textAlign(TextAlign.Center)
            }
            .width(32)
            .justifyContent(FlexAlign.Center)

            Column({ space: 2 }) {
              Text(item.title)
                .fontSize(15)
                .fontColor('#111111')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(item.heat)
                .fontSize(12)
                .fontColor('#999999')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .onClick(() => {
              if (this.onCardTap) {
                this.onCardTap();
              }
            })
          }
          .width('100%')
          .padding({ top: 12, bottom: 12, left: 8, right: 8 })
          .borderWidth({
            bottom: index < getHotRanking().length - 1 ? 1 : 0
          })
          .borderColor('#F0F0F0')
        })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .padding({ left: 4, right: 4 })
    }
    .width('100%')
  }
}

// ══════════════════════════════════════════
// Bottom navigation bar (page-local)
// The shared BottomNavBar is too basic
// (text-only, no icons/badges/center button)
// to meet design requirements. This
// page-local implementation fills the gap.
// ══════════════════════════════════════════

@Component
struct HomeBottomNavBar {
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
          Text('31')
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
// Main Page: HomeFeedPage
// ══════════════════════════════════════════

@Entry
@Component
struct HomeFeedPage {
  @State selectedTabIndex: number = 1;
  @State searchPlaceholder: string = '南瑞继保硕士3年后待遇';
  @State feedData: FeedItem[] = getRecommendedFeed();
  private channelTabs: string[] = ['关注', '推荐', '热榜', '故事', '知识', '圈子', '专栏', '听'];
  private removedCardIds: Set<string> = new Set();

  aboutToAppear(): void {
    this.loadFeedForTab(this.selectedTabIndex);
  }

  loadFeedForTab(index: number): void {
    this.selectedTabIndex = index;
    if (index === 1) {
      this.feedData = getRecommendedFeed();
    }
  }

  handleSearchTap(): void {
    // Search page not yet in scope; log intent
    console.info('[HomeFeedPage] Search tapped - search page not yet registered');
  }

  handleFeedCardTap(_item: FeedItem): void {
    router.pushUrl({ url: NavigationService.routeFor('回答详情页') });
  }

  handleCloseCard(cardId: string): void {
    this.removedCardIds.add(cardId);
    this.feedData = this.feedData.filter((item: FeedItem) => !this.removedCardIds.has(item.id));
  }

  handleChannelTabChange(index: number): void {
    const tab = this.channelTabs[index];

    // Channel-level navigation: 故事 → StoryHomePage, 知识 → KnowledgeHomePage
    if (tab === '故事') {
      router.pushUrl({ url: NavigationService.routeFor('故事频道') });
      return;
    }
    if (tab === '知识') {
      router.pushUrl({ url: NavigationService.routeFor('知识频道') });
      return;
    }

    // In-page tab switch for 关注/推荐/热榜/圈子/专栏/听
    this.loadFeedForTab(index);
  }

  build() {
    Column() {
      // ── Fixed header: search bar ──
      Row() {
        SearchBar({
          placeholder: this.searchPlaceholder,
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
        Column({ space: 0 }) {
          if (this.selectedTabIndex === 0) {
            // 关注 tab
            Column() {
              FeedFollowingContent({
                onCardTap: (): void => { this.handleFeedCardTap(this.feedData[0]); }
              })
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 10 })
          } else if (this.selectedTabIndex === 2) {
            // 热榜 tab
            Column() {
              FeedHotContent({
                onCardTap: (): void => { this.handleFeedCardTap(this.feedData[0]); }
              })
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 10 })
          } else {
            // 推荐 / 圈子 / 专栏 / 听 tab — use same card layout
            Column({ space: 10 }) {
              ForEach(this.feedData, (item: FeedItem) => {
                FeedCardRecommended({
                  item: item,
                  onCardTap: (): void => { this.handleFeedCardTap(item); },
                  onCloseTap: (): void => { this.handleCloseCard(item.id); }
                })
              }, (item: FeedItem): string => item.id)
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .width('100%')

      // ── Fixed bottom navigation ──
      HomeBottomNavBar({ selectedTab: '首页' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
