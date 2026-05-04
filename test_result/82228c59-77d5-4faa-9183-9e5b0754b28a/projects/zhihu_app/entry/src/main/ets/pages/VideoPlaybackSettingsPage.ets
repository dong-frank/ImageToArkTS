import router from '@ohos.router';

@Entry
@Component
struct VideoPlaybackSettingsPage {
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
        Text('视频播放设置')
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
          // Auto play section
          this.SectionHeader('自动播放')
          this.RadioItem('移动网络和Wi-Fi下均自动播放', true, () => {})
          this.RadioItem('仅Wi-Fi下自动播放', false, () => {})
          this.RadioItem('关闭自动播放', false, () => {})

          // Play quality section
          this.SectionHeader('播放画质')
          this.SettingItem('默认画质', '高清 720P', () => {
            // Quality settings
          })
          this.SettingItem('移动网络下默认画质', '流畅 360P', () => {
            // Mobile network quality
          })

          // Play settings
          this.SectionHeader('播放设置')
          this.SettingItem('视频播放时亮度提高', '已开启', () => {
            // Brightness boost
          })
          this.SettingItem('横屏时自动全屏', '已开启', () => {
            // Auto fullscreen
          })
          this.SettingItem('音量键控制', '媒体音量', () => {
            // Volume key control
          })

          // Danmaku settings
          this.SectionHeader('弹幕设置')
          this.SettingItem('弹幕开关', '已开启', () => {
            // Danmaku toggle
          })
          this.SettingItem('弹幕透明度', '80%', () => {
            // Danmaku opacity
          })
          this.SettingItem('弹幕显示区域', '全屏', () => {
            // Danmaku area
          })
          this.SettingItem('弹幕字号', '中', () => {
            // Danmaku font size
          })

          // Download section
          this.SectionHeader('离线缓存')
          this.SettingItem('下载画质', '高清 720P', () => {
            // Download quality
          })
          this.SettingItem('同时下载数', '3', () => {
            // Concurrent downloads
          })
          this.SettingItem('缓存目录', '内部存储', () => {
            // Cache directory
          })
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
  SettingItem(title: string, value: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
      Text(value)
        .fontSize(13)
        .fontColor('#999999')
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

  @Builder
  RadioItem(title: string, selected: boolean, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
      Text(selected ? '\u{25C9}' : '\u{25CB}')
        .fontSize(18)
        .fontColor(selected ? '#0066FF' : '#CCCCCC')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
    .onClick(onClick)
  }
}
