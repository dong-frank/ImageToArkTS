import router from '@ohos.router';
import { BottomNavBar } from '../components/BottomNavBar';

@Entry
@Component
struct ProfilePage {
  @State isLoggedIn: boolean = true;
  @State userName: string = '知乎用户';
  @State userBio: string = '还没有填写个人简介';
  @State followingCount: string = '128';
  @State followersCount: string = '2560';
  @State likesCount: string = '3.4万';

  build() {
    Column() {
      // Header
      Row() {
        Text('我的')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
        Blank()
        Text('\u{1F50D}')
          .fontSize(20)
          .margin({ right: 12 })
        Text('\u{2699}')
          .fontSize(20)
          .onClick(() => {
            router.pushUrl({ url: 'pages/SettingsPage' });
          })
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // User info card
          Column() {
            Row() {
              Column() {
                Text('\u{1F464}')
                  .fontSize(36)
              }
              .width(64)
              .height(64)
              .borderRadius(32)
              .backgroundColor('#E8F2FF')
              .justifyContent(FlexAlign.Center)

              Column() {
                Text(this.userName)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A1A1A')
                Text(this.userBio)
                  .fontSize(13)
                  .fontColor('#999999')
                  .margin({ top: 4 })
                  .maxLines(1)
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 12 })
              .layoutWeight(1)

              Text('编辑资料')
                .fontSize(13)
                .fontColor('#0066FF')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .border({ width: 1, color: '#0066FF', radius: 14 })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/PersonalInfoGuidePage' });
                })
            }
            .width('100%')

            Row() {
              this.StatItem('关注了', this.followingCount)
              this.StatItem('关注者', this.followersCount)
              this.StatItem('赞同', this.likesCount)
            }
            .width('100%')
            .margin({ top: 16 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 6 })

          // My creations section
          Column() {
            Row() {
              Text('我的创作')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
              Blank()
              Text('全部')
                .fontSize(13)
                .fontColor('#999999')
                .onClick(() => {
                  router.pushUrl({ url: 'pages/BookshelfPage' });
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 10 })

            Row() {
              this.CreationItem('\u{1F4DD}', '回答', '36')
              this.CreationItem('\u{2753}', '提问', '12')
              this.CreationItem('\u{1F4D6}', '文章', '8')
              this.CreationItem('\u{1F4AC}', '想法', '24')
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 14 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 10 })

          // Menu items
          Column() {
            this.MenuItem('\u{1F4DA}', '我的书架', 'pages/BookshelfPage')
            this.MenuItem('\u{1F393}', '我的课程', 'pages/CoursesPage')
            this.MenuItem('\u{1F4B0}', '我的钱包', 'pages/WalletPage')
            this.MenuItem('\u{1F48C}', '付费咨询', 'pages/ConsultationPage')
            this.MenuItem('\u{1F6CD}', '知乎商城', 'pages/MallPage')
            this.MenuItem('\u{2753}', '帮助中心', 'pages/HelpCenterPage')
            this.MenuItem('\u{2699}', '更多功能', 'pages/OtherFunctionsPage')
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 10 })

          // Logout button
          Button('退出登录')
            .fontSize(15)
            .fontColor('#FF4444')
            .width('90%')
            .height(44)
            .backgroundColor('#FFFFFF')
            .borderRadius(22)
            .margin({ top: 20, bottom: 10 })
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      BottomNavBar({ currentTab: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  StatItem(label: string, count: string) {
    Column() {
      Text(count)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
      Text(label)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  CreationItem(icon: string, label: string, count: string) {
    Column() {
      Text(icon)
        .fontSize(24)
      Text(count)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .margin({ top: 4 })
      Text(label)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MenuItem(icon: string, label: string, targetPage: string) {
    Row() {
      Text(icon)
        .fontSize(20)
        .margin({ right: 12 })
      Text(label)
        .fontSize(15)
        .fontColor('#1A1A1A')
        .layoutWeight(1)
      Text('>')
        .fontSize(14)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .border({ width: { bottom: 0.5 }, color: '#F5F5F5' })
    .onClick(() => {
      router.pushUrl({ url: targetPage });
    })
  }
}