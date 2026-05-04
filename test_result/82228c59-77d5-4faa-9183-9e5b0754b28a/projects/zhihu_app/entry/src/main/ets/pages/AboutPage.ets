import router from '@ohos.router';

@Entry
@Component
struct AboutPage {
  build() {
    Column() {
      // Top bar
      Row() {
        Text('\u{2190}')
          .fontSize(20)
          .fontColor('#333333')
          .padding(12)
          .onClick(() => {
            router.back();
          })
        Text('关于知乎')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Row()
          .width(44)
          .height(44)
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })

      Scroll() {
        Column() {
          // App logo and version
          Column() {
            Text('\u{2753}')
              .fontSize(64)
              .width(80)
              .height(80)
              .borderRadius(16)
              .backgroundColor('#0066FF')
              .fontColor('#FFFFFF')
              .textAlign(TextAlign.Center)
              .margin({ top: 40 })
            Text('知乎')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ top: 16 })
            Text('版本 9.28.0')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 6 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)

          // Function entries
          Column() {
            this.AboutItem('检查更新', '已是最新版本', () => {
              // Check for updates
            })
            this.AboutItem('功能介绍', '', () => {
              // Feature introduction
            })
            this.AboutItem('用户协议', '', () => {
              router.pushUrl({ url: 'pages/TermsPage' });
            })
            this.AboutItem('隐私政策', '', () => {
              // Privacy policy
            })
            this.AboutItem('权限详情', '', () => {
              // Permission details
            })
            this.AboutItem('开源许可', '', () => {
              // Open source licenses
            })
            this.AboutItem('知识产权', '', () => {
              // Intellectual property
            })
          }
          .width('100%')
          .margin({ top: 32 })

          // Contact info section
          this.SectionHeader('联系我们')
          Row() {
            Text('客服热线')
              .fontSize(15)
              .fontColor('#333333')
              .layoutWeight(1)
            Text('400-xxx-xxxx')
              .fontSize(13)
              .fontColor('#0066FF')
            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
              .margin({ left: 6 })
          }
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 12 })
          .backgroundColor('#FFFFFF')
          .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
          .onClick(() => {
            // Call customer service
          })

          Row() {
            Text('官方网站')
              .fontSize(15)
              .fontColor('#333333')
              .layoutWeight(1)
            Text('zhihu.com')
              .fontSize(13)
              .fontColor('#0066FF')
            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
              .margin({ left: 6 })
          }
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 12 })
          .backgroundColor('#FFFFFF')
          .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
          .onClick(() => {
            // Open website
          })

          Row() {
            Text('反馈与建议')
              .fontSize(15)
              .fontColor('#333333')
              .layoutWeight(1)
            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
              .margin({ left: 6 })
          }
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 12 })
          .backgroundColor('#FFFFFF')
          .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
          .onClick(() => {
            // Feedback
          })

          // Social media
          this.SectionHeader('关注我们')
          Row() {
            Text('\u{1F4F1}')
              .fontSize(28)
              .width(48)
              .height(48)
              .textAlign(TextAlign.Center)
            Column() {
              Text('知乎官方微博')
                .fontSize(15)
                .fontColor('#333333')
              Text('@知乎')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            .margin({ left: 8 })
            Text('关注')
              .fontSize(13)
              .fontColor('#0066FF')
              .border({ width: 1, color: '#0066FF', style: BorderStyle.Solid })
              .borderRadius(14)
              .padding({ left: 16, right: 16, top: 4, bottom: 4 })
          }
          .width('100%')
          .height(64)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FFFFFF')
          .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
          .onClick(() => {
            // Open Weibo
          })

          Row() {
            Text('\u{1F4F1}')
              .fontSize(28)
              .width(48)
              .height(48)
              .textAlign(TextAlign.Center)
            Column() {
              Text('知乎官方公众号')
                .fontSize(15)
                .fontColor('#333333')
              Text('知乎日报')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            .margin({ left: 8 })
            Text('关注')
              .fontSize(13)
              .fontColor('#0066FF')
              .border({ width: 1, color: '#0066FF', style: BorderStyle.Solid })
              .borderRadius(14)
              .padding({ left: 16, right: 16, top: 4, bottom: 4 })
          }
          .width('100%')
          .height(64)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FFFFFF')
          .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
          .onClick(() => {
            // Open WeChat
          })

          // Copyright
          Column() {
            Text('Copyright \u{00A9} 2010-2025 知乎')
              .fontSize(12)
              .fontColor('#BBBBBB')
              .textAlign(TextAlign.Center)
            Text('All Rights Reserved')
              .fontSize(12)
              .fontColor('#BBBBBB')
              .textAlign(TextAlign.Center)
              .margin({ top: 4 })
            Text('京ICP备xxxxxxxx号-x')
              .fontSize(12)
              .fontColor('#BBBBBB')
              .textAlign(TextAlign.Center)
              .margin({ top: 4 })
          }
          .width('100%')
          .padding({ top: 32, bottom: 32 })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(12)
      .fontColor('#999999')
      .padding({ left: 16, top: 20, bottom: 8 })
      .width('100%')
  }

  @Builder
  AboutItem(title: string, value: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
      if (value !== '') {
        Text(value)
          .fontSize(13)
          .fontColor('#999999')
      }
      Text('>')
        .fontSize(14)
        .fontColor('#CCCCCC')
        .margin({ left: 6 })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 12 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
    .onClick(onClick)
  }
}
