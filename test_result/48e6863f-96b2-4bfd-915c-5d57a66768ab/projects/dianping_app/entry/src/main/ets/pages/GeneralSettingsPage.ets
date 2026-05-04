import router from '@ohos.router';

@Entry
@Component
struct GeneralSettingsPage {
  @State videoSaveDataEnabled: boolean = true;
  @State videoMutePlayEnabled: boolean = false;
  @State homeAutoRefreshEnabled: boolean = true;

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('<')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })

        Text('通用')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row()
          .width(44)
          .height(44)
      }
      .width('100%')
      .height(48)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#FFFFFF')

      // Content
      Column() {
        this.ToggleSettingItem(
          '视频智能省流量',
          '',
          this.videoSaveDataEnabled,
          (value: boolean) => {
            this.videoSaveDataEnabled = value;
          }
        )

        Divider()
          .strokeWidth(0.5)
          .color('#F0F0F0')
          .margin({ left: 16 })

        this.ToggleSettingItem(
          '视频默认静音播放',
          '开启后视频默认静音，视频页内可开启声音',
          this.videoMutePlayEnabled,
          (value: boolean) => {
            this.videoMutePlayEnabled = value;
          }
        )

        Divider()
          .strokeWidth(0.5)
          .color('#F0F0F0')
          .margin({ left: 16 })

        this.ToggleSettingItem(
          '首页自动刷新',
          '开启后，回到首页自动刷新内容',
          this.homeAutoRefreshEnabled,
          (value: boolean) => {
            this.homeAutoRefreshEnabled = value;
          }
        )
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .margin({ top: 10 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  ToggleSettingItem(
    label: string,
    description: string,
    isOn: boolean,
    onChange: (value: boolean) => void
  ) {
    Row() {
      Column() {
        Text(label)
          .fontSize(15)
          .fontColor('#333333')
        if (description !== '') {
          Text(description)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor('#FF6600')
        .onChange((value: boolean) => {
          onChange(value);
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }
}
