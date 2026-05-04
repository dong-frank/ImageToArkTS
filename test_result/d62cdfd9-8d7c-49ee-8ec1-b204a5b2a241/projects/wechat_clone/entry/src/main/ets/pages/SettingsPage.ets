import router from '@ohos.router';
import { NavigationService } from '../common/services/NavigationService';

interface SettingItemData {
  label: string;
  trailingText: string;
  showIcon: boolean;
  iconHint: string;
  targetRoute: string;
  isAction: boolean;
}

@Entry
@Component
struct SettingsPage {
  // ── 账号 section items ──
  private accountItems: SettingItemData[] = [
    { label: '个人资料', trailingText: '', showIcon: false, iconHint: '', targetRoute: '', isAction: false },
    {
      label: '账号安全',
      trailingText: '',
      showIcon: false,
      iconHint: '',
      targetRoute: NavigationService.routeFor('账号安全'),
      isAction: false
    },
    { label: '个人信息与权限', trailingText: '', showIcon: false, iconHint: '', targetRoute: '', isAction: false }
  ];

  // ── 通用 section items ──
  private generalItems: SettingItemData[] = [
    { label: '通知', trailingText: '', showIcon: false, iconHint: '', targetRoute: '', isAction: false },
    {
      label: '界面与显示',
      trailingText: '',
      showIcon: false,
      iconHint: '',
      targetRoute: NavigationService.routeFor('界面与显示'),
      isAction: false
    },
    {
      label: '朋友权限',
      trailingText: '',
      showIcon: false,
      iconHint: '',
      targetRoute: NavigationService.routeFor('朋友权限'),
      isAction: false
    },
    { label: '存储空间', trailingText: '', showIcon: false, iconHint: '', targetRoute: '', isAction: false },
    {
      label: '更多',
      trailingText: '',
      showIcon: false,
      iconHint: '',
      targetRoute: NavigationService.routeFor('更多设置'),
      isAction: false
    }
  ];

  // ── 功能 section items ──
  private featureItems: SettingItemData[] = [
    { label: '聊天', trailingText: '', showIcon: false, iconHint: '', targetRoute: '', isAction: false },
    { label: '音视频通话', trailingText: '', showIcon: false, iconHint: '', targetRoute: '', isAction: false },
    { label: '聊天记录管理', trailingText: '', showIcon: false, iconHint: '', targetRoute: '', isAction: false },
    {
      label: '其他功能',
      trailingText: '',
      showIcon: false,
      iconHint: '',
      targetRoute: NavigationService.routeFor('其他功能'),
      isAction: false
    }
  ];

  // ── 插件 section items ──
  private pluginItems: SettingItemData[] = [
    {
      label: '输入法「语音转文字」全面升级',
      trailingText: '',
      showIcon: true,
      iconHint: 'lightbulb',
      targetRoute: '',
      isAction: false
    }
  ];

  // ── 帮助与关于 section items ──
  private helpItems: SettingItemData[] = [
    {
      label: '帮助与反馈',
      trailingText: '',
      showIcon: false,
      iconHint: '',
      targetRoute: NavigationService.routeFor('帮助与反馈'),
      isAction: false
    },
    {
      label: '关于微信',
      trailingText: '版本 8.0.71',
      showIcon: false,
      iconHint: '',
      targetRoute: NavigationService.routeFor('关于微信'),
      isAction: false
    }
  ];

  onBackTap(): void {
    router.back();
  }

  onItemTap(item: SettingItemData): void {
    if (item.targetRoute && item.targetRoute.length > 0) {
      router.pushUrl({ url: item.targetRoute });
    }
  }

  onSearchTap(): void {
    // Search trigger — placeholder for settings-internal search
    console.info('Settings search triggered');
  }

  onSwitchAccount(): void {
    console.info('Switch account flow initiated');
  }

  onLogout(): void {
    console.info('Logout flow initiated');
  }

  onFooterLinkTap(label: string): void {
    console.info(`Footer link tapped: ${label}`);
  }

  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor('#888888')
      .padding({ left: 16, top: 16, bottom: 6 })
      .width('100%')
  }

  @Builder
  SettingRow(item: SettingItemData) {
    Row() {
      // Leading icon (for plugin items)
      if (item.showIcon) {
        Column() {
          Text('💡')
            .fontSize(18)
        }
        .width(36)
        .height(36)
        .borderRadius(4)
        .backgroundColor('#F5F5F5')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ right: 12 })
      }

      // Label
      Text(item.label)
        .fontSize(16)
        .fontColor('#191919')
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .layoutWeight(1)

      // Trailing text (e.g. version number)
      if (item.trailingText && item.trailingText.length > 0) {
        Text(item.trailingText)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ right: 4 })
      }

      // Chevron
      Text('›')
        .fontSize(18)
        .fontColor('#BBBBBB')
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onItemTap(item);
    })
  }

  @Builder
  ActionRow(label: string, onClickAction: () => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#191919')
    }
    .width('100%')
    .height(44)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      onClickAction();
    })
  }

  @Builder
  SeparatorLine() {
    Divider()
      .strokeWidth(0.5)
      .color('#E5E5E5')
      .margin({ left: 16 })
  }

  build() {
    Column() {
      // ── Navigation Bar ──
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#191919')
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onBackTap();
          })

        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#191919')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Spacer to balance the back button
        Row()
          .width(44)
          .height(44)
      }
      .width('100%')
      .height(44)
      .padding({ left: 4 })
      .backgroundColor('#EDEDED')

      // ── Scrollable Content ──
      Scroll() {
        Column() {
          // ── Search Bar ──
          Row() {
            Text('🔍')
              .fontSize(16)
              .margin({ right: 6 })
            Text('搜索')
              .fontSize(15)
              .fontColor('#BBBBBB')
          }
          .width('100%')
          .height(36)
          .backgroundColor('#EDEDED')
          .borderRadius(6)
          .justifyContent(FlexAlign.Center)
          .margin({ left: 16, right: 16, top: 10, bottom: 4 })
          .onClick(() => {
            this.onSearchTap();
          })

          // ── 账号 Section ──
          this.SectionHeader('账号')
          Column() {
            ForEach(this.accountItems, (item: SettingItemData, index: number) => {
              this.SettingRow(item)
              if (index < this.accountItems.length - 1) {
                this.SeparatorLine()
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          // ── 通用 Section ──
          this.SectionHeader('通用')
          Column() {
            ForEach(this.generalItems, (item: SettingItemData, index: number) => {
              this.SettingRow(item)
              if (index < this.generalItems.length - 1) {
                this.SeparatorLine()
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          // ── 功能 Section ──
          this.SectionHeader('功能')
          Column() {
            ForEach(this.featureItems, (item: SettingItemData, index: number) => {
              this.SettingRow(item)
              if (index < this.featureItems.length - 1) {
                this.SeparatorLine()
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          // ── 插件 Section ──
          this.SectionHeader('插件')
          Column() {
            ForEach(this.pluginItems, (item: SettingItemData, index: number) => {
              this.SettingRow(item)
              if (index < this.pluginItems.length - 1) {
                this.SeparatorLine()
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          // ── 帮助与关于 Section ──
          this.SectionHeader('帮助与关于')
          Column() {
            ForEach(this.helpItems, (item: SettingItemData, index: number) => {
              this.SettingRow(item)
              if (index < this.helpItems.length - 1) {
                this.SeparatorLine()
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          // ── Spacer before bottom actions ──
          Divider()
            .strokeWidth(0)
            .height(12)
            .color(Color.Transparent)

          // ── 切换账号 ──
          this.ActionRow('切换账号', () => {
            this.onSwitchAccount();
          })

          // ── Divider ──
          Divider()
            .strokeWidth(8)
            .color('#F5F5F5')

          // ── 退出登录 ──
          this.ActionRow('退出登录', () => {
            this.onLogout();
          })

          // ── Spacer ──
          Divider()
            .strokeWidth(0)
            .height(20)
            .color(Color.Transparent)

          // ── Footer Legal Links ──
          Row({ space: 0 }) {
            Text('个人信息收集清单')
              .fontSize(12)
              .fontColor('#576B95')
              .onClick(() => {
                this.onFooterLinkTap('个人信息收集清单');
              })

            Text(' | ')
              .fontSize(12)
              .fontColor('#C0C0C0')

            Text('第三方信息共享清单')
              .fontSize(12)
              .fontColor('#576B95')
              .onClick(() => {
                this.onFooterLinkTap('第三方信息共享清单');
              })
          }
          .justifyContent(FlexAlign.Center)
          .margin({ top: 0, bottom: 24 })

        }
        .width('100%')
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
