import router from '@ohos.router';

@Entry
@Component
struct MinorModePage {
  @State minorModeEnabled: boolean = false;
  @State timeLimit: number = 40;

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
        Text('青少年模式')
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
          // Description
          Column() {
            Text('\u{1F6E1}')
              .fontSize(48)
              .margin({ top: 24 })
            Text('青少年模式')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ top: 12 })
            Text('开启后可对使用时长、功能及内容进行管理，为青少年营造更健康的成长环境')
              .fontSize(13)
              .fontColor('#666666')
              .textAlign(TextAlign.Center)
              .lineHeight(20)
              .padding({ left: 40, right: 40, top: 12 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)

          // Toggle switch
          Row() {
            Text('开启青少年模式')
              .fontSize(15)
              .fontColor('#333333')
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.minorModeEnabled })
              .onChange((isOn: boolean) => {
                this.minorModeEnabled = isOn;
              })
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FFFFFF')
          .margin({ top: 24 })

          if (this.minorModeEnabled) {
            // Time limit section
            this.SectionHeader('时长管理')
            Row() {
              Text('每日使用时长')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text(this.timeLimit + ' 分钟')
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
              // Time limit picker
            })

            Row() {
              Text('休息提醒')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text('每30分钟')
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
              // Rest reminder settings
            })

            // Content restriction
            this.SectionHeader('内容管理')
            Row() {
              Text('内容分级')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text('适合14岁以上')
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
              // Content rating settings
            })

            Row() {
              Text('搜索内容过滤')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text('已开启')
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
              // Search filter settings
            })

            // Password
            this.SectionHeader('密码管理')
            Row() {
              Text('设置密码')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text('未设置')
                .fontSize(13)
                .fontColor('#FF6600')
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
              // Set password
            })

            // Tip text
            Text('家长设置密码后，关闭青少年模式需输入密码验证')
              .fontSize(11)
              .fontColor('#999999')
              .padding({ left: 16, top: 12, bottom: 32 })
              .width('100%')
          }
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
}
