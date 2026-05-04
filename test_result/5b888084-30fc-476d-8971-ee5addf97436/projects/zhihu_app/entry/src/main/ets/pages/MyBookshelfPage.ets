import { router } from '@kit.ArkUI';

// ══════════════════════════════════════════
// Data types
// ══════════════════════════════════════════

interface TabItem {
  label: string;
}

interface SubActionItem {
  label: string;
  showArrow?: boolean;
}

// ══════════════════════════════════════════
// Data providers
// ══════════════════════════════════════════

function getTabs(): TabItem[] {
  return [
    { label: '书架' },
    { label: '赞过' },
    { label: '弹评' },
    { label: '历史记录' },
    { label: '书单' }
  ];
}

function getSubActions(): SubActionItem[] {
  return [
    { label: '筛选' },
    { label: '管理' },
    { label: '已下载', showArrow: true }
  ];
}

// ══════════════════════════════════════════
// Main Page
// ══════════════════════════════════════════

@Entry
@Component
struct MyBookshelfPage {
  @State activeTabIndex: number = 0;
  @State tabs: TabItem[] = getTabs();
  @State subActions: SubActionItem[] = getSubActions();

  // ═══════════════════════════════
  // Navigation handlers
  // ═══════════════════════════════

  handleBack(): void {
    router.back();
  }

  handleClassify(): void {
    // '分类' button — design indicates overlay or new page (ambiguous).
    // Target page for classification is not confirmed in route table.
    // Per design notes: "分类按钮功能未确认(可能为分类视图弹窗或新页面)".
    console.info('[MyBookshelfPage] 分类 — target unresolved per design, placeholder only');
  }

  handleTabSelect(index: number): void {
    this.activeTabIndex = index;
  }

  handleSubAction(label: string): void {
    if (label === '筛选') {
      // 筛选 — internal filter action, placeholder
      console.info('[MyBookshelfPage] 筛选 — placeholder');
    } else if (label === '管理') {
      // 管理 — internal management action, placeholder
      console.info('[MyBookshelfPage] 管理 — placeholder');
    } else if (label === '已下载') {
      // 已下载 — design indicates navigation to downloaded list.
      // Route for 已下载列表 is not present in the generated route table.
      console.info('[MyBookshelfPage] 已下载 — target route not available');
    }
  }

  // ═══════════════════════════════
  // Sub-builders
  // ═══════════════════════════════

  @Builder
  buildNavBar() {
    Row() {
      // Back button
      Text('←')
        .fontSize(22)
        .fontColor('#333333')
        .padding({ left: 4, right: 12 })
        .onClick(() => this.handleBack())

      // Title
      Text('我的书架')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#111111')

      Blank()

      // Classify button
      Text('分类')
        .fontSize(15)
        .fontColor('#0A84FF')
        .padding({ left: 12, right: 8 })
        .onClick(() => this.handleClassify())
    }
    .width('100%')
    .height(48)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 8, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildTabBar() {
    Row({ space: 0 }) {
      ForEach(this.tabs, (tab: TabItem, index: number) => {
        Column({ space: 4 }) {
          Text(tab.label)
            .fontSize(15)
            .fontWeight(index === this.activeTabIndex ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(index === this.activeTabIndex ? '#111111' : '#666666')
          // Active indicator
          if (index === this.activeTabIndex) {
            Divider()
              .width(20)
              .height(3)
              .color('#0A84FF')
              .borderRadius(1.5)
          } else {
            Row()
              .width(20)
              .height(3)
          }
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        .onClick(() => this.handleTabSelect(index))
      })
    }
    .width('100%')
    .height(46)
    .backgroundColor('#FFFFFF')
    .padding({ left: 8, right: 8 })
  }

  @Builder
  buildSubActionBar() {
    Row() {
      ForEach(this.subActions, (action: SubActionItem) => {
        Row({ space: 2 }) {
          Text(action.label)
            .fontSize(14)
            .fontColor('#666666')
          if (action.showArrow) {
            Text('>')
              .fontSize(14)
              .fontColor('#999999')
          }
        }
        .padding({ left: 10, right: 10 })
        .onClick(() => this.handleSubAction(action.label))
      })

      Blank()
    }
    .width('100%')
    .padding({ left: 4, right: 12 })
  }

  @Builder
  buildEmptyState() {
    Column({ space: 16 }) {
      // Astronaut robot illustration placeholder
      Column() {
        Text('🤖')
          .fontSize(64)
          .opacity(0.7)
      }
      .width(120)
      .height(120)
      .borderRadius(60)
      .backgroundColor('#E8ECF0')
      .justifyContent(FlexAlign.Center)

      Column({ space: 6 }) {
        Text('还没有内容')
          .fontSize(15)
          .fontColor('#999999')
          .fontWeight(FontWeight.Regular)
      }
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F5F6F7')
  }

  // ═══════════════════════════════
  // Main build
  // ═══════════════════════════════

  build() {
    Column() {
      // Top navigation bar
      this.buildNavBar()

      // Tab bar (5 tabs)
      this.buildTabBar()

      // Sub action bar (筛选 / 管理 / 已下载 >)
      this.buildSubActionBar()

      // Divider below sub actions
      Divider()
        .width('100%')
        .height(1)
        .color('#E5E5E5')

      // Empty state area
      this.buildEmptyState()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F7')
  }
}
