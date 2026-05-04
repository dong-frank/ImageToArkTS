import { router } from '@kit.ArkUI';

// ============================================================
// HelpCenterPage — 帮助与客服
// 从 my_features「帮助与客服」进入
// 包含：蓝色顶栏+返回、问候卡片、搜索框、
//       2×4功能网格、5分类Tab、FAQ列表、联系小管家按钮
// ============================================================

// --------------------------------------------------
// 功能网格项数据模型
// --------------------------------------------------
interface GridItemData {
  label: string;
  icon: string;
}

// --------------------------------------------------
// FAQ 分类 Tab 标签
// --------------------------------------------------
const FAQ_TABS: string[] = [
  '常见问题',
  '盐选会员',
  '知识会员',
  '举报申诉',
  '创作者服'
];

// --------------------------------------------------
// 各分类下的 FAQ 列表
// --------------------------------------------------
const FAQ_DATA: Record<string, string[]> = {
  '常见问题': [
    '如何开通盐选会员？',
    '如何查看会员订阅状态并取消连续订阅？',
    '知乎使用指南',
    '如何更换绑定手机号？如何解绑手机号？'
  ],
  '盐选会员': [
    '盐选会员有哪些权益？',
    '如何升级盐选会员？',
    '盐选会员可以退款吗？'
  ],
  '知识会员': [
    '知识会员包含哪些内容？',
    '如何成为知识会员？'
  ],
  '举报申诉': [
    '如何举报违规内容？',
    '举报后多久会处理？',
    '如何申诉被封禁账号？'
  ],
  '创作者服': [
    '如何开通创作者收益？',
    '创作者等级如何提升？'
  ]
};

@Entry
@Component
struct HelpCenterPage {
  // 功能网格数据：2行×4列
  private functionGrid: GridItemData[] = [
    { label: '账号注销', icon: '🚫' },
    { label: '账号申诉', icon: '📝' },
    { label: '我的举报', icon: '📋' },
    { label: '违规诊断', icon: '🔍' },
    { label: '绑定手机', icon: '📱' },
    { label: '账号关联', icon: '🔗' },
    { label: '我的钱包', icon: '💰' },
    { label: '个人认证', icon: '✅' }
  ];

  // 当前选中的 FAQ 分类 Tab
  @State activeTabIndex: number = 0;
  // 当前 Tab 对应的 FAQ 列表
  @State currentFaqList: string[] = FAQ_DATA[FAQ_TABS[0]];

  build() {
    Column() {
      // ── 蓝色顶栏 ──
      this.buildNavBar();

      // ── 可滚动内容区 ──
      Scroll() {
        Column() {
          // ── 问候卡片 ──
          this.buildGreetingCard();

          // ── 搜索框 ──
          this.buildSearchBar();

          // ── 2×4 功能网格 ──
          this.buildFunctionGrid();

          // ── 分隔线 ──
          Divider()
            .color('#F0F0F0')
            .width('100%')
            .margin({ top: 12, bottom: 0 });

          // ── 5分类Tab ──
          this.buildTabSegment();

          // ── FAQ 列表 ──
          this.buildFaqList();

          // ── 底部联系按钮 ──
          this.buildContactButton();

          // 底部安全区
          Blank().height(24);
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // ─── 蓝色顶栏 ───
  @Builder
  buildNavBar() {
    Row() {
      // 返回按钮
      Text('\uE0D9')
        .fontSize(28)
        .fontColor('#FFFFFF')
        .padding({ left: 12, right: 8, top: 10, bottom: 10 })
        .onClick(() => {
          router.back();
        })

      // 标题
      Text('帮助与客服')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')

      Blank()
    }
    .width('100%')
    .height(56)
    .backgroundColor('#0084FF')
  }

  // ─── 问候卡片 ───
  @Builder
  buildGreetingCard() {
    Column() {
      Row({ space: 12 }) {
        // 小管家头像占位
        Column() {
          Text('🤖')
            .fontSize(28)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor('#E8F4FD')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 4 }) {
          Text('Hi, 小雨滴')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')

          Text('我是知乎小管家，下面由我来为你提供服务')
            .fontSize(13)
            .fontColor('#888888')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 20 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 12, left: 16, right: 16 })
    .borderRadius(12)
  }

  // ─── 搜索框 ───
  @Builder
  buildSearchBar() {
    Row({ space: 8 }) {
      Text('\uE009')
        .fontSize(18)
        .fontColor('#AAAAAA')

      Text('搜索相关问题')
        .fontSize(14)
        .fontColor('#AAAAAA')

      Blank()
    }
    .width('100%')
    .height(40)
    .backgroundColor('#F0F0F0')
    .borderRadius(20)
    .padding({ left: 16, right: 16 })
    .margin({ top: 12, left: 16, right: 16 })
    .onClick(() => {
      // 搜索入口 — 目标搜索页面未在当前页面集合中覆盖，保留占位
      console.info('[HelpCenterPage] 搜索相关问题 - 搜索页暂未覆盖');
    })
  }

  // ─── 2×4 功能网格 ───
  @Builder
  buildFunctionGrid() {
    Column() {
      // 第1行
      Row() {
        ForEach(this.functionGrid.slice(0, 4), (item: GridItemData) => {
          this.buildGridCell(item);
        }, (item: GridItemData) => item.label)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)

      // 第2行
      Row() {
        ForEach(this.functionGrid.slice(4, 8), (item: GridItemData) => {
          this.buildGridCell(item);
        }, (item: GridItemData) => item.label)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ top: 16 })
    }
    .width('100%')
    .padding({ top: 16, bottom: 16, left: 8, right: 8 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 12, left: 16, right: 16 })
    .borderRadius(12)
  }

  @Builder
  buildGridCell(item: GridItemData) {
    Column({ space: 8 }) {
      Text(item.icon)
        .fontSize(32)

      Text(item.label)
        .fontSize(12)
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('22%')
    .padding({ top: 8, bottom: 8 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // 功能网格各项对应具体功能页，当前页面集合中未覆盖
      console.info(`[HelpCenterPage] 功能入口点击: ${item.label} - 目标页暂未覆盖`);
    })
  }

  // ─── 5分类Tab ───
  @Builder
  buildTabSegment() {
    Row() {
      ForEach(FAQ_TABS, (tab: string, index: number) => {
        Column({ space: 6 }) {
          Text(tab)
            .fontSize(14)
            .fontWeight(index === this.activeTabIndex ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(index === this.activeTabIndex ? '#0084FF' : '#666666')
            .maxLines(1)

          // 选中指示器
          if (index === this.activeTabIndex) {
            Divider()
              .width(24)
              .height(2)
              .color('#0084FF')
          } else {
            Blank().height(2)
          }
        }
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.activeTabIndex = index;
          this.currentFaqList = FAQ_DATA[tab];
        })
      }, (tab: string) => tab)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
    .padding({ top: 12, bottom: 8, left: 8, right: 8 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 12, left: 16, right: 16 })
    .borderRadius(12)
  }

  // ─── FAQ 列表 ───
  @Builder
  buildFaqList() {
    Column() {
      ForEach(this.currentFaqList, (question: string, qIndex: number) => {
        Row() {
          Text(question)
            .fontSize(15)
            .fontColor('#333333')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Text('\uE0DA')
            .fontSize(18)
            .fontColor('#CCCCCC')
            .padding({ left: 8 })
        }
        .width('100%')
        .padding({ top: 14, bottom: 14, left: 4, right: 4 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          // FAQ 详情页 — 目标FAQ详情/帮助页未在当前页面集合中覆盖
          console.info(`[HelpCenterPage] FAQ点击: ${question} - 详情页暂未覆盖`);
        })

        // 分隔线（最后一项除外）
        if (qIndex < this.currentFaqList.length - 1) {
          Divider()
            .color('#F0F0F0')
            .width('100%')
            .margin({ left: 4 })
        }
      }, (question: string) => question)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 0, left: 16, right: 16 })
    .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 12, bottomRight: 12 })
  }

  // ─── 联系小管家按钮 ───
  @Builder
  buildContactButton() {
    Row({ space: 8 }) {
      Text('💬')
        .fontSize(18)

      Text('联系小管家')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#0084FF')
    }
    .width('100%')
    .height(48)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ top: 16, left: 16, right: 16 })
    .border({
      width: 1,
      color: '#0084FF'
    })
    .onClick(() => {
      // 客服聊天页 — 目标页面未在当前页面集合中覆盖
      console.info('[HelpCenterPage] 联系小管家 - 客服聊天页暂未覆盖');
    })
  }
}
