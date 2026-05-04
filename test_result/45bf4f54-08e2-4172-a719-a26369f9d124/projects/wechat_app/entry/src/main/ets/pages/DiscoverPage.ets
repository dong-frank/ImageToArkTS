import router from '@ohos.router';
import { BottomNavBar } from '../components/BottomNavBar';

@Entry
@Component
struct DiscoverPage {
  build() {
    Column() {
      // Title bar
      Row() {
        Text('发现')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#191919')
      }
      .width('100%')
      .height(44)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#EDEDED')

      // Discover list
      List({ space: 0 }) {
        // 朋友圈
        ListItem() {
          this.DiscoverItemWithTrailing(
            '🎨',
            '朋友圈',
            '#F58220',
            '👤',
            '#4CAF50'
          )
        }

        // 视频号
        ListItem() {
          this.DiscoverItem('🦋', '视频号', '#FF9800')
        }

        // 直播
        ListItem() {
          this.DiscoverItem('🔴', '直播', '#F44837')
        }

        // Spacing divider
        ListItem() {
          Row()
            .width('100%')
            .height(8)
            .backgroundColor('#EDEDED')
        }

        // 扫一扫
        ListItem() {
          this.DiscoverItem('📷', '扫一扫', '#5B9EF5')
        }

        // 听一听
        ListItem() {
          this.DiscoverItemWithSubtitle(
            '🎵',
            '听一听',
            '#F44837',
            "Alyssa今日♡的音乐"
          )
        }

        // Spacing divider
        ListItem() {
          Row()
            .width('100%')
            .height(8)
            .backgroundColor('#EDEDED')
        }

        // 看一看
        ListItem() {
          this.DiscoverItem('⭐', '看一看', '#FFD600')
        }

        // 搜一搜
        ListItem() {
          this.DiscoverItem('🔍', '搜一搜', '#F44837')
        }

        // 附近的人
        ListItem() {
          this.DiscoverItem('📍', '附近的人', '#5B9EF5')
        }

        // Spacing divider
        ListItem() {
          Row()
            .width('100%')
            .height(8)
            .backgroundColor('#EDEDED')
        }

        // 游戏
        ListItem() {
          this.DiscoverItemWithSubtitle(
            '🎮',
            '游戏',
            '#7C4DFF',
            '神域膜拜活动！参与赢礼'
          )
        }

        // 小程序
        ListItem() {
          this.DiscoverItem('🎵', '小程序', '#7C4DFF')
        }
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#FFFFFF')
      .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 56, endMargin: 16 })

      // Bottom nav
      BottomNavBar({ currentTab: 2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#EDEDED')
  }

  @Builder
  DiscoverItem(icon: string, label: string, iconBgColor: string) {
    Row() {
      Column() {
        Text(icon)
          .fontSize(18)
      }
      .width(36)
      .height(36)
      .borderRadius(6)
      .backgroundColor(iconBgColor)
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      Text(label)
        .fontSize(15)
        .fontColor('#191919')
        .layoutWeight(1)

      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  DiscoverItemWithTrailing(icon: string, label: string, iconBgColor: string, trailingIcon: string, trailingBgColor: string) {
    Row() {
      Column() {
        Text(icon)
          .fontSize(18)
      }
      .width(36)
      .height(36)
      .borderRadius(6)
      .backgroundColor(iconBgColor)
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      Text(label)
        .fontSize(15)
        .fontColor('#191919')
        .layoutWeight(1)

      // Small avatar trailing
      Column() {
        Text(trailingIcon)
          .fontSize(12)
      }
      .width(28)
      .height(28)
      .borderRadius(14)
      .backgroundColor(trailingBgColor)
      .justifyContent(FlexAlign.Center)
      .margin({ right: 8 })

      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  DiscoverItemWithSubtitle(icon: string, label: string, iconBgColor: string, subtitle: string) {
    Row() {
      Column() {
        Text(icon)
          .fontSize(18)
      }
      .width(36)
      .height(36)
      .borderRadius(6)
      .backgroundColor(iconBgColor)
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      Column() {
        Text(label)
          .fontSize(15)
          .fontColor('#191919')
        Text(subtitle)
          .fontSize(11)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row({ space: 4 }) {
        // Red dot indicator
        Circle({ width: 8, height: 8 })
          .fill('#F44837')
        Text('>')
          .fontSize(16)
          .fontColor('#CCCCCC')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
  }
}
