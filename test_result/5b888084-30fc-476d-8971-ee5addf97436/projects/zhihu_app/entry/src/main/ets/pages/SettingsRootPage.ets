import { router } from '@kit.ArkUI';

interface SettingItem {
  label: string;
  subtitle?: string;
  route?: string;
}

interface SettingSection {
  items: SettingItem[];
}

@Entry
@Component
struct SettingsRootPage {
  private sections: SettingSection[] = [
    {
      items: [
        {
          label: '消息设置',
          subtitle: '私信接收设置、通知设置',
          route: 'pages/MessageSettingsPage'
        },
        {
          label: '推送通知',
          subtitle: '推荐通知、个性化内容推荐',
          route: 'pages/PushNotificationSettingsPage'
        }
      ]
    },
    {
      items: [
        {
          label: '卡片贴纸',
          route: ''
        }
      ]
    },
    {
      items: [
        {
          label: '账号与安全',
          route: ''
        },
        {
          label: '隐私',
          subtitle: '屏蔽设置、互动设置、隐私设置',
          route: 'pages/PrivacySettingsPage'
        }
      ]
    },
    {
      items: [
        {
          label: '存储空间',
          subtitle: '缓存、下载管理',
          route: ''
        },
        {
          label: '视频播放设置',
          route: 'pages/VideoPlaybackSettingsPage'
        },
        {
          label: '内容兴趣偏好',
          route: 'pages/InterestPreferencePage'
        }
      ]
    },
    {
      items: [
        {
          label: '通用设置',
          route: 'pages/SettingsGeneralPage'
        }
      ]
    },
    {
      items: [
        {
          label: '关于知乎',
          route: 'pages/AboutZhihuPage'
        }
      ]
    }
  ];

  build() {
    Column() {
      // ── Top Navigation Bar ──
      this.buildNavBar();

      // ── Scrollable Content ──
      Scroll() {
        Column() {
          // Settings sections
          ForEach(this.sections, (section: SettingSection, sectionIndex: number) => {
            this.buildSection(section, sectionIndex);
          }, (section: SettingSection, sectionIndex: number) => sectionIndex.toString())

          // Spacer before logout
          Blank().height(32);

          // ── Logout Button ──
          this.buildLogoutButton();

          // Bottom safe area spacer
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
      Text('设置')
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

  // ─── Section Builder ───
  @Builder
  buildSection(section: SettingSection, sectionIndex: number) {
    Column() {
      // Top spacer for section separation (not for first section)
      if (sectionIndex > 0) {
        Blank().height(16);
      }

      // Section container with white background and rounded corners
      Column() {
        ForEach(section.items, (item: SettingItem, itemIndex: number) => {
          this.buildSettingItem(item, itemIndex, section.items.length);
        }, (item: SettingItem, itemIndex: number) => `${sectionIndex}_${itemIndex}`)
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 16, right: 16 })
    }
    .width('100%')
  }

  // ─── Setting List Item Builder ───
  @Builder
  buildSettingItem(item: SettingItem, itemIndex: number, totalItems: number) {
    Column() {
      Row() {
        Column() {
          Text(item.label)
            .fontSize(16)
            .fontColor('#1A1A1A')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (item.subtitle && item.subtitle.length > 0) {
            Text(item.subtitle)
              .fontSize(13)
              .fontColor('#999999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ right: 12 })

        // Chevron right arrow
        Text('\uE0E1')
          .fontSize(18)
          .fontColor('#C7C7CC')
      }
      .width('100%')
      .padding({
        left: 16,
        right: 12,
        top: item.subtitle ? 11 : 13,
        bottom: item.subtitle ? 11 : 13
      })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onItemClick(item);
      })

      // Divider between items (not after last)
      if (itemIndex < totalItems - 1) {
        Divider()
          .color('#E5E5E5')
          .width('100%')
          .margin({ left: 16 })
      }
    }
    .width('100%')
  }

  // ─── Logout Button ───
  @Builder
  buildLogoutButton() {
    Row() {
      Text('退出登录')
        .fontSize(16)
        .fontColor('#E53935')
    }
    .width('100%')
    .height(48)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16 })
    .onClick(() => {
      console.info('退出登录 clicked');
    })
  }

  // ─── Item Click Handler ───
  private onItemClick(item: SettingItem): void {
    if (item.route && item.route.length > 0) {
      router.pushUrl({ url: item.route });
    } else {
      console.info(`设置项 "${item.label}" 被点击，暂无目标路由`);
    }
  }
}
