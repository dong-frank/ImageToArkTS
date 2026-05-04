import { router } from '@kit.ArkUI';
import { NavigationService } from '../common/services/NavigationService';
import { BottomNavBar } from '../common/components/BottomNavBar';

// ══════════════════════════════════════════
// Data types
// ══════════════════════════════════════════

interface RankItem {
  rank: number;
  title: string;
  score: string;
  category: string;
  coverColor: string;
}

interface BookItem {
  title: string;
  meta: string;
  coverColor: string;
}

interface QuickAccessItem {
  label: string;
  icon: string;
  color: string;
}

// ══════════════════════════════════════════
// Data providers
// ══════════════════════════════════════════

function getChannelTabs(): string[] {
  return ['关注', '推荐', '热榜', '故事', '知识', '圈子', '专栏', '听'];
}

function getBottomTabs(): string[] {
  return ['首页', '直答', '+', '消息', '我的'];
}

function getQuickAccessItems(): QuickAccessItem[] {
  return [
    { label: '继续阅读', icon: '📖', color: '#F5F0E8' },
    { label: '书架', icon: '📚', color: '#E8F0F5' },
    { label: '分类', icon: '📂', color: '#F0E8F5' }
  ];
}

function getRankingTabs(): string[] {
  return ['口碑榜', '畅销榜', '新鲜榜'];
}

function getRankingData(tabIndex: number): RankItem[] {
  if (tabIndex === 0) {
    return [
      { rank: 1, title: '传染科档案：预防，抢占健康先机', score: '9.2', category: '社会事件', coverColor: '#B0D4F1' },
      { rank: 2, title: '顺治朝：毁誉参半的混沌时代', score: '8.8', category: '清朝历史人物', coverColor: '#D4C5A9' },
      { rank: 3, title: '趋势与周期 3：货币、债务与投资时钟', score: '9.7', category: '地产交易', coverColor: '#C5C5C5' },
      { rank: 4, title: '怕什么来什么？恐惧的心理学解读', score: '8.5', category: '指南', coverColor: '#F5C6C6' },
      { rank: 5, title: '明朝那些事儿：权力游戏中的得与失', score: '8.3', category: '评', coverColor: '#D4A8A0' },
      { rank: 6, title: '历史深处的回响：文明冲突与融合', score: '8.1', category: '分', coverColor: '#C8D4A8' }
    ];
  } else if (tabIndex === 1) {
    return [
      { rank: 1, title: '未来简史：人类命运的终极预言', score: '9.5', category: '社科·未来学', coverColor: '#B8D4E8' },
      { rank: 2, title: '终身成长：重新定义成功的思维模式', score: '9.3', category: '心理学', coverColor: '#E8D4B8' },
      { rank: 3, title: '认知觉醒：开启自我改变的原动力', score: '9.1', category: '个人成长', coverColor: '#D4E8B8' },
      { rank: 4, title: '刻意练习：如何从新手到大师', score: '8.9', category: '学习方法', coverColor: '#E8B8D4' },
      { rank: 5, title: '穷查理宝典：查理·芒格智慧箴言录', score: '8.7', category: '投资理财', coverColor: '#B8D4D4' }
    ];
  } else {
    return [
      { rank: 1, title: 'AI时代的核心竞争力：不可替代的思维', score: '9.4', category: '科技·趋势', coverColor: '#D4D4F0' },
      { rank: 2, title: 'DeepSeek实战：从入门到精通', score: '9.2', category: '计算机', coverColor: '#F0D4D4' },
      { rank: 3, title: '量子计算简史：从理论到工程突破', score: '8.9', category: '物理', coverColor: '#D4F0D4' },
      { rank: 4, title: '气候经济与未来投资', score: '8.6', category: '经济', coverColor: '#F0F0D4' }
    ];
  }
}

function getBookGridData(): BookItem[] {
  return [
    { title: '能量满格计划：高效管理你的精力', meta: '6本 · 1.2万加书架', coverColor: '#FFD4A8' },
    { title: 'AI加速中：开启行动高效能', meta: '8本 · 2071加书架', coverColor: '#A8D4FF' },
    { title: '青年更新发现更适合的路径', meta: '7本 · 64.8万阅读', coverColor: '#D4A8FF' },
    { title: '认知升级：突破思维边界的50本书', meta: '12本 · 3.5万加书架', coverColor: '#A8FFD4' },
    { title: '读懂中国经济：从数据看未来', meta: '5本 · 8900加书架', coverColor: '#FFD4D4' },
    { title: '科学思维训练营：从观察到推理', meta: '9本 · 1.8万加书架', coverColor: '#D4E8A8' }
  ];
}

// ══════════════════════════════════════════
// Main Page
// ══════════════════════════════════════════

@Entry
@Component
struct KnowledgeHomePage {
  @State currentRankingTab: number = 0;
  @State rankingData: RankItem[] = getRankingData(0);

  private channelTabs: string[] = getChannelTabs();
  private bottomTabs: string[] = getBottomTabs();
  private quickAccessItems: QuickAccessItem[] = getQuickAccessItems();
  private rankingTabs: string[] = getRankingTabs();
  private bookData: BookItem[] = getBookGridData();

  // ── Navigation handlers ──

  onChannelTabTap(tab: string): void {
    if (tab === '知识') {
      return;
    }
    if (tab === '推荐' || tab === '关注' || tab === '热榜' || tab === '圈子' || tab === '专栏' || tab === '听') {
      router.replaceUrl({ url: NavigationService.routeFor('首页信息流') });
    } else if (tab === '故事') {
      router.replaceUrl({ url: NavigationService.routeFor('故事频道') });
    }
  }

  onQuickAccessTap(item: QuickAccessItem): void {
    if (item.label === '书架') {
      router.pushUrl({ url: NavigationService.routeFor('我的书架') });
    } else if (item.label === '继续阅读') {
      console.info('KnowledgeHomePage: 继续阅读 tapped — target page not yet available');
    } else if (item.label === '分类') {
      console.info('KnowledgeHomePage: 分类 tapped — target page not yet available');
    }
  }

  onRankingTabChange(index: number): void {
    this.currentRankingTab = index;
    this.rankingData = getRankingData(index);
  }

  onBookTap(book: BookItem): void {
    console.info('KnowledgeHomePage: book tapped — ' + book.title);
  }

  onBottomNavTap(tab: string): void {
    if (tab === '首页') {
      return;
    }
    if (tab === '直答') {
      router.replaceUrl({ url: NavigationService.routeFor('直答/提问首页') });
    } else if (tab === '+') {
      router.pushUrl({ url: NavigationService.routeFor('内容编辑器') });
    } else if (tab === '消息') {
      router.replaceUrl({ url: NavigationService.routeFor('消息列表') });
    } else if (tab === '我的') {
      router.replaceUrl({ url: NavigationService.routeFor('个人中心') });
    }
  }

  // ── UI Builders ──

  @Builder
  SearchBar() {
    Row() {
      Text('搜索')
        .fontSize(14)
        .fontColor('#999999')
        .flexShrink(0)
      Blank()
      Text('🔍')
        .fontSize(14)
    }
    .width('100%')
    .height(36)
    .backgroundColor('#F2F3F5')
    .borderRadius(18)
    .padding({ left: 14, right: 12 })
  }

  @Builder
  ChannelTabBar() {
    Scroll() {
      Row({ space: 0 }) {
        ForEach(this.channelTabs, (tab: string) => {
          Text(tab)
            .fontSize(tab === '知识' ? 18 : 15)
            .fontWeight(tab === '知识' ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(tab === '知识' ? '#111111' : '#666666')
            .padding({ left: 12, right: 12, top: 8, bottom: 4 })
            .onClick(() => { this.onChannelTabTap(tab) })
        })
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  @Builder
  QuickAccessRow() {
    Row({ space: 10 }) {
      ForEach(this.quickAccessItems, (item: QuickAccessItem, index: number) => {
        Row() {
          if (index === 0) {
            Column() {
              Text(item.label)
                .fontSize(12)
                .fontColor('#666666')
              Text('计算机时代 2023年0...')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor('#111111')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text('上次读到 1%')
                .fontSize(10)
                .fontColor('#999999')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(10)
            .width('100%')
            .onClick(() => { this.onQuickAccessTap(item) })
          } else {
            Column({ space: 4 }) {
              Text(item.icon)
                .fontSize(22)
              Text(item.label)
                .fontSize(12)
                .fontColor('#333333')
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .justifyContent(FlexAlign.Center)
            .onClick(() => { this.onQuickAccessTap(item) })
          }
        }
        .backgroundColor(item.color)
        .borderRadius(8)
        .layoutWeight(index === 0 ? 2 : 1)
        .height(72)
      })
    }
    .width('100%')
  }

  @Builder
  RankingSection() {
    Column() {
      Row({ space: 0 }) {
        ForEach(this.rankingTabs, (tab: string, index: number) => {
          Text(tab)
            .fontSize(15)
            .fontWeight(this.currentRankingTab === index ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(this.currentRankingTab === index ? '#111111' : '#888888')
            .padding({ left: 16, right: 16, top: 10, bottom: 8 })
            .onClick(() => { this.onRankingTabChange(index) })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      Row() {
        Row()
          .width(40)
          .height(3)
          .backgroundColor('#0066FF')
          .borderRadius(1.5)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .padding({ left: 16 + this.currentRankingTab * 48 })

      Column({ space: 0 }) {
        ForEach(this.rankingData, (item: RankItem, index: number) => {
          Column() {
            Row({ space: 12 }) {
              Text(item.rank.toString())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(item.rank <= 3 ? '#FF6B35' : '#999999')
                .width(28)
                .textAlign(TextAlign.Center)

              Row()
                .width(44)
                .height(60)
                .backgroundColor(item.coverColor)
                .borderRadius(4)

              Column({ space: 4 }) {
                Text(item.title)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#111111')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Row({ space: 4 }) {
                  Text('评分 ' + item.score)
                    .fontSize(12)
                    .fontColor('#0066FF')
                    .fontWeight(FontWeight.Medium)
                  Text('·')
                    .fontSize(12)
                    .fontColor('#CCCCCC')
                  Text(item.category)
                    .fontSize(12)
                    .fontColor('#888888')
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Text('›')
                .fontSize(20)
                .fontColor('#CCCCCC')
                .width(20)
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })

            if (index < this.rankingData.length - 1) {
              Divider()
                .strokeWidth(0.5)
                .color('#F0F0F0')
                .margin({ left: 40 })
            }
          }
        })
      }
    }
    .width('100%')
  }

  @Builder
  BookGrid() {
    Column() {
      Row() {
        Text('精品书单')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')
        Blank()
        Text('更多 >')
          .fontSize(13)
          .fontColor('#0066FF')
      }
      .width('100%')
      .padding({ left: 4, right: 4, bottom: 12 })

      Grid() {
        ForEach(this.bookData, (item: BookItem) => {
          GridItem() {
            Column({ space: 6 }) {
              Column()
                .width('100%')
                .height(100)
                .backgroundColor(item.coverColor)
                .borderRadius(6)

              Column({ space: 2 }) {
                Text(item.title)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#111111')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(item.meta)
                  .fontSize(10)
                  .fontColor('#999999')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .onClick(() => { this.onBookTap(item) })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(10)
      .rowsGap(14)
    }
    .width('100%')
  }

  // ── Main build ──

  build() {
    Column() {
      // ── Header: Search + Channel tabs ──
      Column({ space: 10 }) {
        this.SearchBar()
        this.ChannelTabBar()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 4 })
      .backgroundColor('#FFFFFF')

      // ── Scrollable content ──
      Scroll() {
        Column({ space: 16 }) {
          this.QuickAccessRow()

          Divider()
            .strokeWidth(8)
            .color('#F5F5F5')

          this.RankingSection()

          Divider()
            .strokeWidth(8)
            .color('#F5F5F5')

          this.BookGrid()
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // ── Bottom navigation ──
      BottomNavBar({
        currentPage: '首页',
        tabs: this.bottomTabs
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
