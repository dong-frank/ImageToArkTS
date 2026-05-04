import router from '@ohos.router';
import { NavigationService } from '../common/services/NavigationService';

interface AboutItemData {
  label: string;
  trailingText: string;
  showBadge: boolean;
  badgeText: string;
  showChevron: boolean;
  showLinkIcon: boolean;
  targetRoute: string;
  isAction: boolean;
}

@Entry
@Component
struct AboutWechatPage {
  private appInfoItems: AboutItemData[] = [
    {
      label: '微信',
      trailingText: 'Version 8.0.1',
      showBadge: false,
      badgeText: '',
      showChevron: false,
      showLinkIcon: false,
      targetRoute: '',
      isAction: false
    },
    {
      label: '功能介绍',
      trailingText: '',
      showBadge: false,
      badgeText: '',
      showChevron: true,
      showLinkIcon: false,
      targetRoute: NavigationService.routeFor('功能介绍'),
      isAction: false
    },
    {
      label: '检查新版本',
      trailingText: '',
      showBadge: true,
      badgeText: '已是最新版',
      showChevron: true,
      showLinkIcon: false,
      targetRoute: '',
      isAction: true
    }
  ];

  private legalItems: AboutItemData[] = [
    {
      label: '服务协议与隐私政策',
      trailingText: '',
      showBadge: false,
      badgeText: '',
      showChevron: true,
      showLinkIcon: false,
      targetRoute: '',
      isAction: true
    },
    {
      label: '腾讯客服',
      trailingText: '',
      showBadge: false,
      badgeText: '',
      showChevron: true,
      showLinkIcon: true,
      targetRoute: '',
      isAction: true
    }
  ];

  onBackTap(): void {
    router.back();
  }

  onItemTap(item: AboutItemData): void {
    if (item.targetRoute && item.targetRoute.length > 0) {
      router.pushUrl({ url: item.targetRoute });
    } else if (item.isAction) {
      if (item.label === '检查新版本') {
        console.info('Check for update triggered');
      } else if (item.label === '服务协议与隐私政策') {
        console.info('Navigate to agreement page');
      } else if (item.label === '腾讯客服') {
        console.info('Navigate to Tencent customer service');
      }
    }
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
  AboutRow(item: AboutItemData) {
    Row() {
      // Label
      Text(item.label)
        .fontSize(16)
        .fontColor('#191919')
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .layoutWeight(1)

      // Badge (e.g. "已是最新版")
      if (item.showBadge && item.badgeText.length > 0) {
        Text(item.badgeText)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ right: 6 })
      }

      // Trailing text (e.g. version number)
      if (item.trailingText && item.trailingText.length > 0) {
        Text(item.trailingText)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ right: 4 })
      }

      // Link icon
      if (item.showLinkIcon) {
        Text('🔗')
          .fontSize(14)
          .margin({ right: 2 })
      }

      // Chevron
      if (item.showChevron) {
        Text('›')
          .fontSize(20)
          .fontColor('#BBBBBB')
      }
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
  SeparatorLine() {
    Divider()
      .strokeWidth(0.5)
      .color('#E5E5E5')
      .margin({ left: 16 })
  }

  @Builder
  FooterText(text: string) {
    Text(text)
      .fontSize(12)
      .fontColor('#999999')
      .width('100%')
      .textAlign(TextAlign.Center)
      .padding({ top: 8, bottom: 4 })
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

        Text('关于')
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
          // ── 应用信息 Section ──
          this.SectionHeader('应用信息')
          Column() {
            ForEach(this.appInfoItems, (item: AboutItemData, index: number) => {
              this.AboutRow(item)
              if (index < this.appInfoItems.length - 1) {
                this.SeparatorLine()
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          // ── 更多法律信息 Section ──
          this.SectionHeader('更多法律信息')
          Column() {
            ForEach(this.legalItems, (item: AboutItemData, index: number) => {
              this.AboutRow(item)
              if (index < this.legalItems.length - 1) {
                this.SeparatorLine()
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          // ── Footer copyright & registration info ──
          this.FooterText('© 2025 Tencent All Rights Reserved.')
          this.FooterText('粤公网安备44030002000001号')
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
