import router from '@ohos.router';
import { BottomNavBar } from '../components/BottomNavBar';

@Entry
@Component
struct ContactsPage {
  private alphabet: string[] = ['☆', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'W', 'X', 'Y', 'Z', '#'];

  build() {
    Stack({ alignContent: Alignment.End }) {
      Column() {
        // Title bar
        Row() {
          Text('通讯录')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#191919')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ left: 30 })
          Text('👤+')
            .fontSize(20)
            .fontColor('#191919')
            .margin({ right: 16 })
        }
        .width('100%')
        .height(44)
        .backgroundColor('#EDEDED')

        // Search bar
        Row() {
          Text('🔍 搜索')
            .fontSize(14)
            .fontColor('#B2B2B2')
        }
        .width('90%')
        .height(36)
        .backgroundColor('#EDEDED')
        .borderRadius(6)
        .padding({ left: 12 })
        .margin({ top: 4, bottom: 4 })
        .justifyContent(FlexAlign.Start)

        // Contact list
        List({ space: 0 }) {
          // 新的朋友
          ListItem() {
            this.ContactItem('#F58220', '👤', '新的朋友')
          }

          // 仅聊天的朋友
          ListItem() {
            this.ContactItem('#4CAF50', '💬', '仅聊天的朋友')
          }

          // 群聊
          ListItem() {
            this.ContactItem('#5B9EF5', '👥', '群聊')
          }

          // 标签
          ListItem() {
            this.ContactItem('#F5A623', '🏷️', '标签')
          }

          // 公众号
          ListItem() {
            this.ContactItem('#4A90D9', '📖', '公众号')
          }

          // 服务号
          ListItem() {
            this.ContactItem('#FF9800', '💎', '服务号')
          }

          // 企业微信联系人
          ListItem() {
            this.ContactItem('#607D8B', '🏢', '企业微信联系人')
          }

          // Section: 我的企业
          ListItem() {
            Row() {
              Text('我的企业')
                .fontSize(12)
                .fontColor('#999999')
                .padding({ left: 16, top: 12, bottom: 8 })
            }
            .width('100%')
            .backgroundColor('#EDEDED')
          }

          // 企业微信通知
          ListItem() {
            this.ContactItem('#2196F3', '🔔', '企业微信通知')
          }

          // 学校通知
          ListItem() {
            this.ContactItem('#00BCD4', '🏫', '学校通知')
          }

          // Section: 星标朋友
          ListItem() {
            Row() {
              Text('☆ 星标朋友')
                .fontSize(12)
                .fontColor('#999999')
                .padding({ left: 16, top: 12, bottom: 8 })
            }
            .width('100%')
            .backgroundColor('#EDEDED')
          }

          // Sample contact entries under stars
          ListItem() {
            this.ContactWithAvatar('🐱', '猫馋喜之郎', '#FF9800')
          }

          ListItem() {
            this.ContactWithAvatar('🐶', '饶东', '#795548')
          }

          ListItem() {
            this.ContactWithAvatar('🐰', '赵先生', '#E91E63')
          }
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 70, endMargin: 16 })

        // Bottom nav
        BottomNavBar({ currentTab: 1 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EDEDED')

      // Alphabet index
      Column({ space: 0 }) {
        ForEach(this.alphabet, (letter: string) => {
          Text(letter)
            .fontSize(10)
            .fontColor('#666666')
            .width(20)
            .height(18)
            .textAlign(TextAlign.Center)
        })
      }
      .position({ x: '96%', y: 200 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ContactItem(bgColor: string, icon: string, text: string) {
    Row() {
      Column() {
        Text(icon)
          .fontSize(18)
      }
      .width(44)
      .height(44)
      .borderRadius(6)
      .backgroundColor(bgColor)
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      Text(text)
        .fontSize(15)
        .fontColor('#191919')
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ContactWithAvatar(emoji: string, name: string, bgColor: string) {
    Row() {
      Column() {
        Text(emoji)
          .fontSize(22)
      }
      .width(44)
      .height(44)
      .borderRadius(6)
      .backgroundColor(bgColor)
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      Text(name)
        .fontSize(15)
        .fontColor('#191919')
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
  }
}
