import router from '@ohos.router';

@Entry
@Component
struct GeneralSettings {
  @State smartDataSaving: boolean = true;
  @State mutePlayback: boolean = false;
  @State autoRefresh: boolean = true;

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ left: 16, right: 8, top: 12, bottom: 12 })
          .onClick(() => {
            router.back();
          })

        Text('通用')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })

      // Settings list
      Column() {
        // 视频智能省流量
        Row() {
          Text('视频智能省流量')
            .fontSize(16)
            .fontColor('#333333')

          Blank()

          Toggle({ type: ToggleType.Switch, isOn: this.smartDataSaving })
            .onChange((isOn: boolean) => {
              this.smartDataSaving = isOn;
            })
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        .alignItems(VerticalAlign.Center)

        Divider()
          .strokeWidth(0.5)
          .color('#F0F0F0')
          .margin({ left: 16 })

        // 视频默认静音播放
        Row() {
          Text('视频默认静音播放')
            .fontSize(16)
            .fontColor('#333333')

          Blank()

          Toggle({ type: ToggleType.Switch, isOn: this.mutePlayback })
            .onChange((isOn: boolean) => {
              this.mutePlayback = isOn;
            })
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        .alignItems(VerticalAlign.Center)

        Divider()
          .strokeWidth(0.5)
          .color('#F0F0F0')
          .margin({ left: 16 })

        // 首页自动刷新
        Row() {
          Text('首页自动刷新')
            .fontSize(16)
            .fontColor('#333333')

          Blank()

          Toggle({ type: ToggleType.Switch, isOn: this.autoRefresh })
            .onChange((isOn: boolean) => {
              this.autoRefresh = isOn;
            })
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
