import router from '@ohos.router';

@Entry
@Component
struct DarkModePage {
  @State selectedMode: string = '跟随系统';

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })
        Text('深色模式')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Row()
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#EDEDED')

      Scroll() {
        Column() {
          this.RadioItem('跟随系统', '根据系统设置自动切换深色/浅色模式')
          this.RadioItem('深色模式', '始终使用深色显示')
          this.RadioItem('浅色模式', '始终使用浅色显示')
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .margin({ top: 16, bottom: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#EDEDED')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  RadioItem(mode: string, description: string) {
    Row() {
      Column() {
        Text(mode)
          .fontSize(16)
          .fontColor('#333333')
        Text(description)
          .fontSize(12)
          .fontColor('#B3B3B3')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Radio({ value: mode, group: 'darkModeGroup' })
        .checked(this.selectedMode === mode)
        .radioStyle({ checkedBackgroundColor: '#07C160' })
        .onClick(() => {
          this.selectedMode = mode;
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      this.selectedMode = mode;
    })
    .border({
      width: { bottom: 0.5 },
      color: '#F1F1F1'
    })
  }
}
