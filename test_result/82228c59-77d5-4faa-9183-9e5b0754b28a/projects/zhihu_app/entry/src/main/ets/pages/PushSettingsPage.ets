import router from '@ohos.router';

@Entry
@Component
struct PushSettingsPage {
  @State pushEnabled: boolean = true;
  @State personalizedPush: boolean = true;
  @State hotPushEnabled: boolean = true;

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
        Text('推送通知')
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
          // Main push toggle
          Row() {
            Text('接收推送通知')
              .fontSize(15)
              .fontColor('#333333')
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.pushEnabled })
              .onChange((isOn: boolean) => {
                this.pushEnabled = isOn;
              })
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FFFFFF')
          .margin({ top: 12 })

          if (this.pushEnabled) {
            // Content push
            this.SectionHeader('内容推送')
            this.ToggleItem('热点资讯推送', this.hotPushEnabled, (isOn: boolean) => {
              this.hotPushEnabled = isOn;
            })
            this.ToggleItem('关注内容更新', true, () => {})
            this.ToggleItem('活动推荐', true, () => {})
            this.ToggleItem('直播提醒', false, () => {})
            this.ToggleItem('专栏更新提醒', true, () => {})

            // Personalized push
            this.SectionHeader('个性化推荐')
            this.ToggleItem('个性化推送', this.personalizedPush, (isOn: boolean) => {
              this.personalizedPush = isOn;
            })
            if (this.personalizedPush) {
              Row() {
                Text('基于浏览记录推荐相关内容，为您提供更好的使用体验')
                  .fontSize(12)
                  .fontColor('#999999')
                  .lineHeight(18)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .backgroundColor('#FFFFFF')
              .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
            }
            this.ToggleItem('兴趣标签推送', true, () => {})
            this.ToggleItem('地区热门推送', false, () => {})

            // Push frequency
            this.SectionHeader('推送频次')
            Row() {
              Text('推送频次')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text('标准')
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
            .onClick(() => {
              // Push frequency options: Low / Standard / High
            })

            Row() {
              Text('静默时段')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text('23:00 - 08:00')
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
            .onClick(() => {
              // Silent hours settings
            })

            // Push content types
            this.SectionHeader('推送内容类型')
            this.ToggleItem('图文内容', true, () => {})
            this.ToggleItem('视频内容', true, () => {})
            this.ToggleItem('音频内容', false, () => {})
            this.ToggleItem('直播内容', true, () => {})
          }

          // Bottom spacing
          Column()
            .width('100%')
            .height(24)
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
  ToggleItem(title: string, isOn: boolean, onChange: (isOn: boolean) => void) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .onChange(onChange)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
  }
}
