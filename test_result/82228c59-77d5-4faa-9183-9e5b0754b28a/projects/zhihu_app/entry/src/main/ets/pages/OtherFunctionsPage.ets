import router from '@ohos.router';

@Entry
@Component
struct OtherFunctionsPage {
  build() {
    Column() {
      // Header
      Row() {
        Text('\u{2039}')
          .fontSize(24)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })
        Text('更多功能')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .margin({ left: 8 })
        Blank()
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // Content tools section
          this.SectionHeader('创作工具')
          this.FunctionItem('\u{1F4DD}', '草稿箱', '0')
          this.FunctionItem('\u{1F4CA}', '创作中心', '')
          this.FunctionItem('\u{1F465}', '我的专栏', '2篇')

          // Community section
          this.SectionHeader('社区功能')
          this.FunctionItem('\u{1F3AE}', '知乎 Live', '')
          this.FunctionItem('\u{1F4AC}', '圆桌讨论', '')
          this.FunctionItem('\u{1F4EB}', '知乎日报', '')
          this.FunctionItem('\u{1F3B5}', '知乎电台', '')

          // Privacy & security section
          this.SectionHeader('隐私与安全')
          this.FunctionItem('\u{1F512}', '隐私设置', '')
          this.FunctionItem('\u{1F6E1}', '账号安全', '')
          this.FunctionItem('\u{1F510}', '黑名单管理', '')

          // Other section
          this.SectionHeader('其他')
          this.FunctionItem('\u{1F4F1}', '夜间模式', '')
          this.FunctionItem('\u{1F4E4}', '分享应用', '')
          this.FunctionItem('\u{2B50}', '评分应用', '')
          this.FunctionItem('\u{2139}', '关于知乎', '')
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor('#999999')
      .padding({ left: 16, top: 16, bottom: 6 })
      .width('100%')
  }

  @Builder
  FunctionItem(icon: string, label: string, extra: string) {
    Row() {
      Text(icon)
        .fontSize(20)
        .margin({ right: 12 })
      Text(label)
        .fontSize(15)
        .fontColor('#1A1A1A')
        .layoutWeight(1)
      if (extra.length > 0) {
        Text(extra)
          .fontSize(13)
          .fontColor('#999999')
          .margin({ right: 4 })
      }
      Text('>')
        .fontSize(14)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#F5F5F5' })
    .onClick(() => {
      // Navigate to respective sub-page
    })
  }
}
