import { router } from '@kit.ArkUI';

// ============================================================
// MyFeaturesPage — 我的-功能列表
// 从 profile_home 功能网格「更多」进入
// 包含：标题栏、周报统计区、其他功能列表、底部导航（我的高亮）
// ============================================================

// --------------------------------------------------
// 功能列表项数据模型
// --------------------------------------------------
interface FunctionItemData {
  label: string;
  icon: string;
  targetRoute: string;
}

// --------------------------------------------------
// 统计项数据模型
// --------------------------------------------------
interface StatItemData {
  label: string;
  value: string;
}

// --------------------------------------------------
// 底部导航项数据模型
// --------------------------------------------------
interface BottomTabData {
  label: string;
  icon: string;
  selected: boolean;
  targetRoute: string;
}

@Entry
@Component
struct MyFeaturesPage {
  // --------------------------------------------------
  // 周报统计数据
  // --------------------------------------------------
  @State statsData: StatItemData[] = [
    { label: '获赞', value: '1,234' },
    { label: '内容被赞同', value: '567' },
    { label: '总发布量', value: '89' }
  ];

  // --------------------------------------------------
  // 功能列表数据
  // --------------------------------------------------
  @State functionItems: FunctionItemData[] = [
    { label: '关注', icon: 'star', targetRoute: 'pages/HomeFeedPage' },
    { label: '收藏', icon: 'bookmark', targetRoute: 'pages/MyBookshelfPage' },
    { label: '稍后再看', icon: 'clock', targetRoute: 'pages/HomeFeedPage' },
    { label: '随便看看', icon: 'eye', targetRoute: 'pages/HomeFeedPage' },
    { label: '赞赏', icon: 'gift', targetRoute: 'pages/MallHomePage' },
    { label: '钱包', icon: 'wallet', targetRoute: 'pages/MallHomePage' },
    { label: '课程', icon: 'book', targetRoute: 'pages/MyCoursesPage' },
    { label: '刘看山彩蛋', icon: 'smile', targetRoute: 'pages/ProfileHomePage' },
    { label: '知海', icon: 'globe', targetRoute: 'pages/HomeFeedPage' },
    { label: '帮助与客服', icon: 'help', targetRoute: 'pages/HelpCenterPage' }
  ];

  // --------------------------------------------------
  // 底部导航数据
  // --------------------------------------------------
  @State bottomTabs: BottomTabData[] = [
    { label: '首页', icon: 'home', selected: false, targetRoute: 'pages/HomeFeedPage' },
    { label: '直答', icon: 'question', selected: false, targetRoute: 'pages/QaLandingPage' },
    { label: '+', icon: 'plus', selected: false, targetRoute: 'pages/ContentEditorPage' },
    { label: '消息', icon: 'bell', selected: false, targetRoute: 'pages/MessageListPage' },
    { label: '我的', icon: 'profile', selected: true, targetRoute: 'pages/ProfileHomePage' }
  ];

  // --------------------------------------------------
  // 导航方法
  // --------------------------------------------------
  private handleBack(): void {
    router.back();
  }

  private handleNotificationTap(): void {
    router.pushUrl({ url: 'pages/MessageListPage' });
  }

  private handleFunctionItemTap(item: FunctionItemData): void {
    if (item.targetRoute) {
      router.pushUrl({ url: item.targetRoute });
    }
  }

  private handleBottomTabTap(tab: BottomTabData): void {
    if (tab.selected) {
      // 已在当前 Tab，不重复跳转
      return;
    }
    if (tab.targetRoute) {
      router.replaceUrl({ url: tab.targetRoute });
    }
  }

  // --------------------------------------------------
  // 图标映射：用文字/符号代替图标（无资源文件时）
  // --------------------------------------------------
  @Builder
  buildIcon(iconName: string) {
    if (iconName === 'star') {
      Text('★')
        .fontSize(20)
        .fontColor('#FFB800')
    } else if (iconName === 'bookmark') {
      Text('🔖')
        .fontSize(18)
    } else if (iconName === 'clock') {
      Text('🕐')
        .fontSize(18)
    } else if (iconName === 'eye') {
      Text('👁')
        .fontSize(18)
    } else if (iconName === 'gift') {
      Text('🎁')
        .fontSize(18)
    } else if (iconName === 'wallet') {
      Text('💰')
        .fontSize(18)
    } else if (iconName === 'book') {
      Text('📖')
        .fontSize(18)
    } else if (iconName === 'smile') {
      Text('😊')
        .fontSize(18)
    } else if (iconName === 'globe') {
      Text('🌐')
        .fontSize(18)
    } else if (iconName === 'help') {
      Text('❓')
        .fontSize(18)
    } else {
      Text('•')
        .fontSize(18)
        .fontColor('#999999')
    }
  }

  @Builder
  buildBottomNavIcon(iconName: string, selected: boolean) {
    if (iconName === 'home') {
      Text('🏠')
        .fontSize(20)
        .fontColor(selected ? '#FFFFFF' : '#999999')
    } else if (iconName === 'question') {
      Text('💬')
        .fontSize(20)
        .fontColor(selected ? '#FFFFFF' : '#999999')
    } else if (iconName === 'plus') {
      Text('➕')
        .fontSize(20)
        .fontColor(selected ? '#FFFFFF' : '#999999')
    } else if (iconName === 'bell') {
      Text('🔔')
        .fontSize(20)
        .fontColor(selected ? '#FFFFFF' : '#999999')
    } else if (iconName === 'profile') {
      Text('👤')
        .fontSize(20)
        .fontColor(selected ? '#FFFFFF' : '#999999')
    } else {
      Text('•')
        .fontSize(20)
        .fontColor(selected ? '#FFFFFF' : '#999999')
    }
  }

  build() {
    Column() {
      // ================================================
      // 状态栏占位
      // ================================================
      Row()
        .width('100%')
        .height(24)
        .backgroundColor('#F5F5F5')

      // ================================================
      // 标题栏：返回箭头 + 标题「我的」
      // ================================================
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => {
            this.handleBack();
          })
          .margin({ left: 16, right: 8 })

        Text('我的')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')
          .layoutWeight(1)

        // 右侧占位保持标题居中
        Row()
          .width(40)
          .height(24)
          .margin({ right: 16 })
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')

      // ================================================
      // 可滚动内容区
      // ================================================
      Scroll() {
        Column() {
          // ==============================================
          // 周报统计卡片区
          // ==============================================
          Column() {
            // 统计区标题行
            Row() {
              Text('周报统计')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#111111')
                .layoutWeight(1)

              // 通知按钮
              Row() {
                Text('🔔')
                  .fontSize(14)
                Text('通知')
                  .fontSize(12)
                  .fontColor('#666666')
                  .margin({ left: 4 })
              }
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .borderRadius(12)
              .backgroundColor('#F0F0F0')
              .onClick(() => {
                this.handleNotificationTap();
              })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 8 })

            // 三个统计数字
            Row() {
              ForEach(this.statsData, (item: StatItemData) => {
                Column() {
                  Text(item.value)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#0066FF')

                  Text(item.label)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
              })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 16 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16, top: 12 })

          // ==============================================
          // 「其他功能」区域标题
          // ==============================================
          Text('其他功能')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#111111')
            .width('100%')
            .padding({ left: 20, right: 16, top: 20, bottom: 8 })

          // ==============================================
          // 功能列表
          // ==============================================
          Column() {
            ForEach(this.functionItems, (item: FunctionItemData, index: number) => {
              // 列表项
              Row() {
                // 图标
                Row() {
                  this.buildIcon(item.icon)
                }
                .width(36)
                .height(36)
                .borderRadius(18)
                .backgroundColor('#F5F5F5')
                .justifyContent(FlexAlign.Center)

                // 标签文字
                Text(item.label)
                  .fontSize(15)
                  .fontColor('#333333')
                  .margin({ left: 12 })
                  .layoutWeight(1)

                // 右箭头
                Text('›')
                  .fontSize(18)
                  .fontColor('#CCCCCC')
              }
              .width('100%')
              .height(52)
              .padding({ left: 16, right: 16 })
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                this.handleFunctionItemTap(item);
              })

              // 分割线（最后一项不显示）
              if (index < this.functionItems.length - 1) {
                Divider()
                  .strokeWidth(0.5)
                  .color('#F0F0F0')
                  .margin({ left: 64 })
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16 })

          // 列表底部留白，为底部导航留空间
          Row()
            .height(80)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#F5F5F5')
      .scrollBar(BarState.Off)

      // ================================================
      // 底部导航栏（我的高亮）
      // ================================================
      Row() {
        ForEach(this.bottomTabs, (tab: BottomTabData) => {
          Column() {
            this.buildBottomNavIcon(tab.icon, tab.selected)
            Text(tab.label)
              .fontSize(10)
              .fontColor(tab.selected ? '#FFFFFF' : '#999999')
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .padding({ top: 6, bottom: 6 })
          .borderRadius(tab.selected ? 20 : 0)
          .backgroundColor(tab.selected ? '#0066FF' : 'transparent')
          .onClick(() => {
            this.handleBottomTabTap(tab);
          })
        })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .padding({ left: 4, right: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
