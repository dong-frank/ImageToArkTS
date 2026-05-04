import router from '@ohos.router';
import { BottomNavBar } from '../common/components/BottomNavBar';

@Entry
@Component
struct MyProfile {
  @State activeTab: string = '我的';

  build() {
    Column() {
      // Scrollable content area
      Scroll() {
        Column() {
          // ===== Header Section =====
          Column() {
            // Avatar + User Info + Action Icons Row
            Row() {
              // Avatar
              Column() {
                Text('🍰')
                  .fontSize(36)
                  .width(64)
                  .height(64)
                  .borderRadius(32)
                  .backgroundColor('#FFF0E0')
                  .textAlign(TextAlign.Center)
                  .lineHeight(64)
              }

              // User Info
              Column({ space: 4 }) {
                Text('猫馋喜之郎')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')

                Text('0 粉丝  1 关注  9 获赞')
                  .fontSize(13)
                  .fontColor('#999999')
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 12 })
              .layoutWeight(1)

              // Action Icons
              Row({ space: 16 }) {
                // 个人主页
                Row({ space: 2 }) {
                  Text('个人主页')
                    .fontSize(12)
                    .fontColor('#666666')
                  Text('>')
                    .fontSize(12)
                    .fontColor('#999999')
                }
                .onClick(() => {
                  // 个人主页 - unresolved target, keep as placeholder
                  console.info('个人主页 tapped - target page not yet available');
                })

                // Headset icon
                Text('🎧')
                  .fontSize(20)

                // Settings icon
                Text('⚙')
                  .fontSize(20)
                  .onClick(() => {
                    router.pushUrl({ url: 'pages/SettingsRoot' });
                  })
              }
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // Badge Row
            Row({ space: 8 }) {
              BadgeChip({ text: 'Lv4', bgColor: '#FFF7E6', textColor: '#FA8C16' })
              BadgeChip({ text: 'VIP', bgColor: '#FFF0F0', textColor: '#FF4D4F' })
              BadgeChip({ text: '16枚', bgColor: '#F0F5FF', textColor: '#2F54EB' })
              BadgeChip({ text: '黑金会员', bgColor: '#1A1A1A', textColor: '#FFD700' })
            }
            .width('100%')
            .margin({ top: 12 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 12 })
          .backgroundColor('#FFFFFF')
          .borderRadius({ bottomLeft: 12, bottomRight: 12 })

          // ===== Stat Cards =====
          Row({ space: 10 }) {
            StatCard({ title: '打卡', subtitle: '累计29次', icon: '📍' })
              .onClick(() => {
                router.pushUrl({ url: 'pages/MyCheckin' });
              })
            StatCard({ title: '我的足迹', subtitle: '66个足迹', icon: '👣' })
            StatCard({ title: '口味档案', subtitle: '用餐41次', icon: '🍽️' })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 8 })
          .justifyContent(FlexAlign.SpaceBetween)

          // ===== Review Summary Section =====
          Column() {
            // Section header
            Row() {
              Text('评价 (37)')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')

              Blank()

              Text('全部 >')
                .fontSize(13)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 10 })

            // Metrics Row
            Row() {
              Column({ space: 4 }) {
                Text('浏览')
                  .fontSize(12)
                  .fontColor('#999999')
                Row({ space: 4 }) {
                  Text('2.2万次')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')
                  Text('+69')
                    .fontSize(12)
                    .fontColor('#FF6600')
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)

              // Divider
              Column()
                .width(1)
                .height(36)
                .backgroundColor('#EEEEEE')

              Column({ space: 4 }) {
                Text('帮助')
                  .fontSize(12)
                  .fontColor('#999999')
                Row({ space: 4 }) {
                  Text('1244人')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')
                  Text('+65')
                    .fontSize(12)
                    .fontColor('#FF6600')
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 12 })

            // Review Preview Grid (3 items)
            Row({ space: 8 }) {
              ReviewPreview({ tag: '超预期' })
              ReviewPreview({ tag: '超预期' })
              ReviewPreview({ tag: '超预期' })
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 14 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16, top: 8 })

          // ===== Function Icon Grid (2x4) =====
          Column() {
            // Row 1
            Row() {
              FunctionIcon({ label: '订单', icon: '📋' })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/OrderList' });
                })
              FunctionIcon({ label: '收藏', icon: '❤️' })
              FunctionIcon({ label: '待评价', icon: '✏️' })
              FunctionIcon({ label: '最近浏览', icon: '🕐' })
            }
            .width('100%')
            .padding({ top: 14, bottom: 8 })

            // Row 2
            Row() {
              FunctionIcon({ label: '卡券', icon: '🎫', badge: '1' })
              FunctionIcon({ label: '钱包', icon: '👛' })
              FunctionIcon({ label: '草稿箱', icon: '📝' })
              FunctionIcon({ label: '笔记达人中心', icon: '⭐' })
            }
            .width('100%')
            .padding({ top: 8, bottom: 14 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16, top: 8 })

          // ===== Promo Card Grid (2x2) =====
          Column({ space: 8 }) {
            // Row 1
            Row({ space: 8 }) {
              PromoCard({ title: '免费试', subtitle: '0元吃大餐', bgColor: '#FFF7E6', accentColor: '#FA8C16' })
              PromoCard({ title: '大众评审', subtitle: '快来评理', bgColor: '#F0F5FF', accentColor: '#2F54EB' })
            }
            .width('100%')

            // Row 2
            Row({ space: 8 }) {
              PromoCard({ title: '每日签到', subtitle: '做任务领现金', bgColor: '#FFF0F0', accentColor: '#FF4D4F' })
              PromoCard({ title: '活动中心', subtitle: '参与活动赢奖励', bgColor: '#F0FFF0', accentColor: '#52C41A' })
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })

          // Bottom spacer for tab bar
          Column()
            .height(16)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // ===== Bottom Navigation Bar =====
      BottomNavBar({ activeTab: this.activeTab })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

// ===== Sub-components =====

@Component
struct BadgeChip {
  @Prop text: string = '';
  @Prop bgColor: string = '#F0F0F0';
  @Prop textColor: string = '#666666';

  build() {
    Text(this.text)
      .fontSize(11)
      .fontColor(this.textColor)
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .backgroundColor(this.bgColor)
      .borderRadius(4)
  }
}

@Component
struct StatCard {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop icon: string = '';

  build() {
    Column({ space: 6 }) {
      Text(this.icon)
        .fontSize(24)

      Text(this.title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Text(this.subtitle)
        .fontSize(11)
        .fontColor('#999999')
    }
    .layoutWeight(1)
    .height(90)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
  }
}

@Component
struct ReviewPreview {
  @Prop tag: string = '';

  build() {
    Column({ space: 4 }) {
      // Placeholder image area
      Column()
        .width('100%')
        .height(60)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text(this.tag)
        .fontSize(11)
        .fontColor('#FF6600')
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .backgroundColor('#FFF7E6')
        .borderRadius(3)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
}

@Component
struct FunctionIcon {
  @Prop label: string = '';
  @Prop icon: string = '';
  @Prop badge: string = '';

  build() {
    Column({ space: 6 }) {
      Stack() {
        Text(this.icon)
          .fontSize(28)

        if (this.badge !== '') {
          Text(this.badge)
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF4D4F')
            .borderRadius(8)
            .width(16)
            .height(16)
            .textAlign(TextAlign.Center)
            .lineHeight(16)
            .position({ x: 18, y: -4 })
        }
      }

      Text(this.label)
        .fontSize(12)
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 6, bottom: 6 })
  }
}

@Component
struct PromoCard {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop bgColor: string = '#FFFFFF';
  @Prop accentColor: string = '#FF6600';

  build() {
    Row() {
      Column({ space: 4 }) {
        Text(this.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Text(this.subtitle)
          .fontSize(11)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('>')
        .fontSize(14)
        .fontColor('#CCCCCC')
    }
    .layoutWeight(1)
    .height(64)
    .padding({ left: 14, right: 14 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.bgColor)
    .borderRadius(10)
  }
}
