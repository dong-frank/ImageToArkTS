import { BottomNavBar } from '../common/components/BottomNavBar';

interface DiscoverItem {
  icon: string;
  label: string;
  hasAvatar?: boolean;
  avatarSrc?: string;
  hasRedDot?: boolean;
  subtitle?: string;
}

@Entry
@Component
struct DiscoverPage {
  private featureItems: DiscoverItem[] = [
    { icon: '\uEA01', label: '朋友圈', hasAvatar: true, avatarSrc: 'user_avatar_1' },
    { icon: '\uEA02', label: '视频号' },
    { icon: '\uEA03', label: '直播' },
    { icon: '\uEA04', label: '扫一扫' },
    { icon: '\uEA05', label: '听一听', hasRedDot: true, subtitle: "Alyssa今日\u2661的音乐" },
    { icon: '\uEA06', label: '看一看' },
    { icon: '\uEA07', label: '搜一搜' },
    { icon: '\uEA08', label: '附近的人' },
    { icon: '\uEA09', label: '游戏', hasRedDot: true, subtitle: '神域膜拜活动！参与赢礼' },
    { icon: '\uEA10', label: '小程序' },
  ];

  private tabItems: string[] = ['微信', '通讯录', '发现', '我'];

  build() {
    Column() {
      // Header
      Row() {
        Text('发现')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#191919')
          .textAlign(TextAlign.Center)
          .flexGrow(1)
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#EDEDED')

      // Scrollable feature list
      Scroll() {
        Column() {
          // Feature list group
          Column() {
            ForEach(this.featureItems, (item: DiscoverItem, index: number) => {
              this.FeatureListItem(item, index)
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(0)
          .margin({ top: 16, bottom: 16 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')

      // Bottom navigation bar
      BottomNavBar({ currentPage: '发现', tabs: this.tabItems })
        .backgroundColor('#F7F7F7')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  FeatureListItem(item: DiscoverItem, index: number) {
    Column() {
      Row({ space: 12 }) {
        // Leading icon
        Text(item.icon)
          .fontSize(22)
          .fontColor('#4A90D9')
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)

        // Label area
        Column({ space: 2 }) {
          Text(item.label)
            .fontSize(16)
            .fontColor('#191919')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (item.subtitle && item.subtitle.length > 0) {
            Text(item.subtitle)
              .fontSize(12)
              .fontColor('#999999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // Accessory area
        Row({ space: 8 }) {
          if (item.hasRedDot) {
            Circle({ width: 8, height: 8 })
              .fill('#FA5151')
          }

          if (item.hasAvatar && item.avatarSrc) {
            Image($r('app.media.startIcon'))
              .width(36)
              .height(36)
              .borderRadius(4)
              .objectFit(ImageFit.Cover)
          }

          // Trailing chevron
          Text('\u203A')
            .fontSize(20)
            .fontColor('#C7C7CC')
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 13, bottom: 13 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onFeatureTap(item.label);
      })

      // Separator line
      if (index < this.featureItems.length - 1) {
        Row()
          .width('100%')
          .height(0.5)
          .backgroundColor('#E6E6E6')
          .margin({ left: 56 })
      }
    }
    .width('100%')
  }

  private onFeatureTap(label: string): void {
    // Feature child pages are outside the current 22-page scope.
    // Log the tap for visibility; navigation would be wired when target pages exist.
    console.info(`[DiscoverPage] feature tapped: ${label}`);
  }
}
