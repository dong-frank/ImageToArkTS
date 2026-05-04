import router from '@ohos.router';

@Entry
@Component
struct MoreSettingsPage {
  @State autoSaveImage: boolean = true;
  @State autoSaveVideo: boolean = true;

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
        Text('更多')
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
          Column() {
            this.MenuItemLink('未成年人模式', () => {
              // Placeholder for future page
            })
            this.MenuItemLink('关怀模式', () => {
              // Placeholder for future page
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            this.MenuItemToggle('自动保存拍摄或编辑后的图片', this.autoSaveImage, (value: boolean) => {
              this.autoSaveImage = value;
            })
            this.MenuItemToggle('自动保存拍摄或编辑后的视频', this.autoSaveVideo, (value: boolean) => {
              this.autoSaveVideo = value;
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            this.MenuItemLink('系统权限', () => {
              router.pushUrl({ url: 'pages/SystemPermissionPage' });
            })
            this.MenuItemLink('表情', () => {
              // Placeholder for future page
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            this.MenuItemLink('其他功能', () => {
              router.pushUrl({ url: 'pages/OtherFunctionsPage' });
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16, bottom: 16 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#EDEDED')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MenuItemLink(title: string, onClick: () => void) {
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
  MenuItemToggle(title: string, isOn: boolean, onChange: (value: boolean) => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor('#07C160')
        .onChange((value: boolean) => {
          onChange(value);
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .border({
      width: { bottom: 0.5 },
      color: '#F1F1F1'
    })
  }
}
