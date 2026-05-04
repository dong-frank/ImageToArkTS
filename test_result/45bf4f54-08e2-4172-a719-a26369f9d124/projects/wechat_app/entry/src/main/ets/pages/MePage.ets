import router from '@ohos.router';
import { BottomNavBar } from '../components/BottomNavBar';

@Entry
@Component
struct MePage {
  build() {
    Column() {
      // Profile header
      Column() {
        Row() {
          // Avatar
          Column() {
            Text('🐱')
              .fontSize(30)
          }
          .width(60)
          .height(60)
          .borderRadius(8)
          .backgroundColor('#FF9800')
          .justifyContent(FlexAlign.Center)
          .margin({ right: 14 })

          // Name and info
          Column() {
            Text('猫馋喜之郎')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#191919')
            Row({ space: 8 }) {
              Text('微信号：wxid_...')
                .fontSize(12)
                .fontColor('#999999')
              Text('>')
                .fontSize(12)
                .fontColor('#CCCCCC')
            }
            .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // QR code
          Text('📱')
            .fontSize(22)
            .fontColor('#666666')
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        // Status and friends row
        Row({ space: 16 }) {
          Row() {
            Text('+ 状态')
              .fontSize(13)
              .fontColor('#666666')
              .padding({ left: 14, right: 14, top: 5, bottom: 5 })
          }
          .border({ width: 1, color: '#D9D9D9', style: BorderStyle.Dashed })
          .borderRadius(4)

          Row({ space: 6 }) {
            Text('3个朋友')
              .fontSize(13)
              .fontColor('#666666')
            Circle({ width: 7, height: 7 })
              .fill('#F44837')
          }
        }
        .width('100%')
        .padding({ left: 16, top: 14, bottom: 10 })
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .padding({ top: 16, bottom: 16 })

      // Divider
      Row()
        .width('100%')
        .height(8)
        .backgroundColor('#EDEDED')

      // Menu items
      List({ space: 0 }) {
        // 服务
        ListItem() {
          this.MenuItem('💼', '服务', '')
        }

        // 收藏
        ListItem() {
          this.MenuItem('⭐', '收藏', '')
        }

        // 朋友圈
        ListItem() {
          this.MenuItem('🖼️', '朋友圈', '')
        }

        // 公众号
        ListItem() {
          this.MenuItem('📢', '公众号', '')
        }

        // 小店与卡包 (with red dot and trailing text)
        ListItem() {
          this.MenuItemWithBadge('🛒', '小店与卡包', '[关注]本来食物恋的小店有上新')
        }

        // 表情
        ListItem() {
          this.MenuItem('😊', '表情', '')
        }

        // Spacing
        ListItem() {
          Row()
            .width('100%')
            .height(8)
            .backgroundColor('#EDEDED')
        }

        // 设置
        ListItem() {
          this.MenuItem('⚙️', '设置', '', () => {
            router.pushUrl({ url: 'pages/SettingsPage' });
          })
        }
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#FFFFFF')
      .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 56, endMargin: 16 })

      // Bottom nav
      BottomNavBar({ currentTab: 3 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#EDEDED')
  }

  @Builder
  MenuItem(icon: string, label: string, subtitle: string, onClick?: () => void) {
    Row() {
      Column() {
        Text(icon)
          .fontSize(20)
      }
      .width(36)
      .height(36)
      .borderRadius(6)
      .backgroundColor('#F5F5F5')
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      Text(label)
        .fontSize(15)
        .fontColor('#191919')
        .layoutWeight(1)

      if (subtitle !== '') {
        Text(subtitle)
          .fontSize(11)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 140 })
          .margin({ right: 6 })
      }

      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      if (onClick) {
        onClick();
      }
    })
  }

  @Builder
  MenuItemWithBadge(icon: string, label: string, trailing: string) {
    Row() {
      Column() {
        Text(icon)
          .fontSize(20)
      }
      .width(36)
      .height(36)
      .borderRadius(6)
      .backgroundColor('#F5F5F5')
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      Text(label)
        .fontSize(15)
        .fontColor('#191919')
        .layoutWeight(1)

      Row({ space: 6 }) {
        Text(trailing)
          .fontSize(11)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 140 })
        Circle({ width: 7, height: 7 })
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
