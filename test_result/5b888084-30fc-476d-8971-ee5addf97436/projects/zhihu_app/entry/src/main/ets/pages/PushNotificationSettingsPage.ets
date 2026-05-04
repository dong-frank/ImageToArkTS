import { router } from '@kit.ArkUI';

interface ToggleItemData {
  label: string;
  isOn: boolean;
}

interface NavItemData {
  label: string;
  route?: string;
}

@Entry
@Component
struct PushNotificationSettingsPage {
  // ─── System Notification ───
  @State systemNotificationOn: boolean = false;

  // ─── Zhihu Recommend ───
  @State zhihuRecommendOn: boolean = true;

  // ─── Interaction Behavior Notifications (6 toggles, all ON) ───
  @State interactionToggles: ToggleItemData[] = [
    { label: '有人发私信给我', isOn: true },
    { label: '有人邀请我回答问题', isOn: true },
    { label: '提及 / 评论', isOn: true },
    { label: '转发', isOn: true },
    { label: '赞 / 喜欢 / 掌声', isOn: true },
    { label: '有人添加 / 认可我的形象关键词', isOn: true }
  ];

  // ─── Dynamic Navigation Items ───
  private dynamicNavItems: NavItemData[] = [
    { label: '有人关注了我', route: '' },
    { label: '关注动态', route: '' },
    { label: '参与动态', route: '' }
  ];

  build() {
    Column() {
      // ── Top Navigation Bar ──
      this.buildNavBar();

      // ── Scrollable Content ──
      Scroll() {
        Column() {
          // Section 1: 系统通知
          this.buildSystemNotificationSection();

          // Section 2: 知乎推荐
          this.buildZhihuRecommendSection();

          // Section 3: 互动行为通知
          this.buildInteractionSection();

          // Section 4: 动态类导航项
          this.buildDynamicNavSection();

          // Bottom safe area spacer
          Blank().height(32);
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  // ─── Navigation Bar ───
  @Builder
  buildNavBar() {
    Row() {
      // Back button
      Text('\uE0D9')
        .fontSize(28)
        .fontColor('#1A1A1A')
        .padding({ left: 16, right: 12, top: 12, bottom: 12 })
        .onClick(() => {
          router.back();
        })

      // Title
      Text('推送消息设置')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A1A')

      Blank()
    }
    .width('100%')
    .height(56)
    .backgroundColor('#FFFFFF')
    .border({
      width: { bottom: 0.5 },
      color: '#E5E5E5'
    })
  }

  // ─── Section 1: 系统通知 (toggle OFF + red warning) ───
  @Builder
  buildSystemNotificationSection() {
    Column() {
      // Section header
      Text('系统通知')
        .fontSize(13)
        .fontColor('#6D6D72')
        .padding({ left: 32, right: 16, top: 24, bottom: 6 })
        .width('100%')

      // Section body (white card with rounded corners)
      Column() {
        // Toggle row
        Row() {
          Text('系统通知')
            .fontSize(16)
            .fontColor('#1A1A1A')
            .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.systemNotificationOn })
            .selectedColor('#007AFF')
            .onChange((value: boolean) => {
              this.systemNotificationOn = value;
            })
        }
        .width('100%')
        .padding({
          left: 16,
          right: 16,
          top: 13,
          bottom: 13
        })

        // Red warning hint (shown when toggle is OFF)
        if (!this.systemNotificationOn) {
          Divider()
            .strokeWidth(0.5)
            .color('#E8E8E8')
            .margin({ left: 16 })

          Text('你可能错过重要消息通知，点击去"设置"开启通知')
            .fontSize(13)
            .fontColor('#FF3B30')
            .width('100%')
            .padding({
              left: 16,
              right: 16,
              top: 10,
              bottom: 10
            })
            .onClick(() => {
              // External navigation to iOS system notification settings
              console.info('[PushNotificationSettings] 跳转至系统设置开启通知');
            })
        }
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 16, right: 16 })
    }
    .width('100%')
  }

  // ─── Section 2: 知乎推荐 (toggle ON + subtitle) ───
  @Builder
  buildZhihuRecommendSection() {
    Column() {
      // Section header
      Text('知乎推荐')
        .fontSize(13)
        .fontColor('#6D6D72')
        .padding({ left: 32, right: 16, top: 20, bottom: 6 })
        .width('100%')

      // Section body (white card)
      Column() {
        Row() {
          Column() {
            Text('知乎推荐')
              .fontSize(16)
              .fontColor('#1A1A1A')

            Text('有知乎精选内容时通知我')
              .fontSize(13)
              .fontColor('#999999')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.zhihuRecommendOn })
            .selectedColor('#007AFF')
            .onChange((value: boolean) => {
              this.zhihuRecommendOn = value;
            })
        }
        .width('100%')
        .padding({
          left: 16,
          right: 16,
          top: 12,
          bottom: 12
        })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 16, right: 16 })
    }
    .width('100%')
  }

  // ─── Section 3: 互动行为通知 (6 toggle items) ───
  @Builder
  buildInteractionSection() {
    Column() {
      // Section header
      Text('互动行为通知')
        .fontSize(13)
        .fontColor('#6D6D72')
        .padding({ left: 32, right: 16, top: 20, bottom: 6 })
        .width('100%')

      // Section body (white card with toggles)
      Column() {
        ForEach(this.interactionToggles, (item: ToggleItemData, index: number) => {
          Row() {
            Text(item.label)
              .fontSize(16)
              .fontColor('#1A1A1A')
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: item.isOn })
              .selectedColor('#007AFF')
              .onChange((value: boolean) => {
                this.interactionToggles[index].isOn = value;
              })
          }
          .width('100%')
          .padding({
            left: 16,
            right: 16,
            top: 13,
            bottom: 13
          })

          if (index < this.interactionToggles.length - 1) {
            Divider()
              .strokeWidth(0.5)
              .color('#E8E8E8')
              .margin({ left: 16 })
          }
        })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 16, right: 16 })
    }
    .width('100%')
  }

  // ─── Section 4: 动态类导航项 (3 nav items with chevron) ───
  @Builder
  buildDynamicNavSection() {
    Column() {
      // Section header
      Text('动态类导航项')
        .fontSize(13)
        .fontColor('#6D6D72')
        .padding({ left: 32, right: 16, top: 20, bottom: 6 })
        .width('100%')

      // Section body (white card)
      Column() {
        ForEach(this.dynamicNavItems, (item: NavItemData, index: number) => {
          Row() {
            Text(item.label)
              .fontSize(16)
              .fontColor('#1A1A1A')
              .layoutWeight(1)

            // Chevron right arrow
            Text('\uE0E1')
              .fontSize(18)
              .fontColor('#C7C7CC')
          }
          .width('100%')
          .padding({
            left: 16,
            right: 12,
            top: 13,
            bottom: 13
          })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            // Dynamic navigation sub-pages: target pages not yet covered in current design scope.
            // These are placeholder entries for future implementation of dynamic notification sub-settings.
            console.info('[PushNotificationSettings] 动态导航项点击: ' + item.label);
          })

          if (index < this.dynamicNavItems.length - 1) {
            Divider()
              .strokeWidth(0.5)
              .color('#E8E8E8')
              .margin({ left: 16 })
          }
        })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 16, right: 16 })
    }
    .width('100%')
  }
}
