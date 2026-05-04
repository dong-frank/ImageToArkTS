import router from '@ohos.router';

@Entry
@Component
struct InterfaceDisplayPage {
  @State darkModeValue: string = '跟随系统';
  @State fontSizeValue: string = '标准';

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
        Text('界面与显示')
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
          this.SettingItemWithValue('深色模式', this.darkModeValue, () => {
            router.pushUrl({ url: 'pages/DarkModePage' });
          })
          this.SettingItem('字体大小', () => {
            // Placeholder for font size picker
          })
          this.SettingItem('多语言', () => {
            // Placeholder for language selector
          })
          this.SettingItem('翻译', () => {
            // Placeholder for translation settings
          })
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
  SettingItem(title: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#333333')
      Blank()
      Text('›')
        .fontSize(18)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      onClick();
    })
    .border({
      width: { bottom: 0.5 },
      color: '#F1F1F1'
    })
  }

  @Builder
  SettingItemWithValue(title: string, value: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#333333')
      Blank()
      Text(value)
        .fontSize(14)
        .fontColor('#999999')
        .margin({ right: 4 })
      Text('›')
        .fontSize(18)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      onClick();
    })
    .border({
      width: { bottom: 0.5 },
      color: '#F1F1F1'
    })
  }
}
