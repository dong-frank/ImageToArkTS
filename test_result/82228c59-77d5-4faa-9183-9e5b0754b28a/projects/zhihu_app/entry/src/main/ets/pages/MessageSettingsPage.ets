import router from '@ohos.router';

@Entry
@Component
struct MessageSettingsPage {
  @State messageNotify: boolean = true;
  @State soundEnabled: boolean = true;
  @State vibrateEnabled: boolean = true;
  @State showDetail: boolean = true;

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
        Text('消息通知')
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
          // Main message toggle
          Row() {
            Text('接收消息通知')
              .fontSize(15)
              .fontColor('#333333')
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.messageNotify })
              .onChange((isOn: boolean) => {
                this.messageNotify = isOn;
              })
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FFFFFF')
          .margin({ top: 12 })

          if (this.messageNotify) {
            // Interaction messages
            this.SectionHeader('互动消息')
            this.ToggleItem('赞同与喜欢', this.soundEnabled, (isOn: boolean) => {
              this.soundEnabled = isOn;
            })
            this.ToggleItem('评论与回复', true, () => {})
            this.ToggleItem('关注', true, () => {})
            this.ToggleItem('邀请回答', true, () => {})
            this.ToggleItem('收藏与分享', false, () => {})

            // Private messages
            this.SectionHeader('私信')
            this.ToggleItem('私信提醒', true, () => {})
            this.ToggleItem('陌生人私信免打扰', true, () => {})
            this.ToggleItem('私信声音提示', this.soundEnabled, (isOn: boolean) => {
              this.soundEnabled = isOn;
            })

            // System messages
            this.SectionHeader('系统消息')
            this.ToggleItem('活动通知', true, () => {})
            this.ToggleItem('系统更新', true, () => {})
            this.ToggleItem('运营通知', false, () => {})

            // Notification style
            this.SectionHeader('通知方式')
            this.ToggleItem('声音提示', this.soundEnabled, (isOn: boolean) => {
              this.soundEnabled = isOn;
            })
            this.ToggleItem('震动提示', this.vibrateEnabled, (isOn: boolean) => {
              this.vibrateEnabled = isOn;
            })
            Row() {
              Text('通知铃声')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text('默认铃声')
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
              // Select ringtone
            })

            // Display settings
            this.SectionHeader('显示设置')
            this.ToggleItem('通知详情显示', this.showDetail, (isOn: boolean) => {
              this.showDetail = isOn;
            })
            Row() {
              Text('通知显示位置')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text('通知栏')
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
              // Display position
            })

            // Night mode
            this.SectionHeader('免打扰')
            Row() {
              Text('夜间免打扰')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text('未开启')
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
              // Night DND settings
            })
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
