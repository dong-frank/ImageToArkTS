import router from '@ohos.router';

@Entry
@Component
struct VideoAutoPlayPage {
  @State selectedOption: number = 0;

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('\u2190')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => { router.back(); })
        Text('推荐视频页面自动播放')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Radio options
      Column() {
        this.RadioOption(0, '开启自动播放')
        this.RadioOption(1, '仅 Wi-Fi 下自动播放')
        this.RadioOption(2, '关闭自动播放')
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .margin({ top: 8 })

      // Footer note
      Text('设置后，将在推荐页/关注页/个人动态页/搜索/问题中的视频/直播广场生效')
        .fontSize(12)
        .fontColor('#999999')
        .padding({ left: 16, right: 16, top: 16 })
        .width('100%')

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  RadioOption(index: number, label: string) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)
      if (this.selectedOption === index) {
        Text('\u2713')
          .fontSize(18)
          .fontColor('#0066FF')
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
    .onClick(() => { this.selectedOption = index; })
  }
}
