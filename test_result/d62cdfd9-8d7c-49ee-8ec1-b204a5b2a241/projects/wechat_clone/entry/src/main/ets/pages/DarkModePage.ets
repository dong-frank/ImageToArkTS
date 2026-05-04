import router from '@ohos.router';

@Entry
@Component
struct DarkModePage {
  @State private isSystemFollowEnabled: boolean = true;

  build() {
    Column() {
      // ── Navigation Bar ──
      Row() {
        // Back button
        Text('<')
          .fontSize(22)
          .fontColor('#333333')
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.back();
          })

        // Title
        Text('深色模式')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#191919')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Spacer for symmetry with back button area
        Row()
          .width(44)
          .height(44)
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#EDEDED')

      // ── Scrollable content area ──
      Scroll() {
        Column() {
          // ── Setting Item: 跟随系统 ──
          Column() {
            Row() {
              Column() {
                Text('跟随系统')
                  .fontSize(16)
                  .fontColor('#191919')
                  .fontWeight(FontWeight.Normal)

                Text('开启后，将跟随系统打开或关闭深色模式')
                  .fontSize(12)
                  .fontColor('#999999')
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Toggle({ type: ToggleType.Switch, isOn: this.isSystemFollowEnabled })
                .selectedColor('#07C160')
                .onChange((isOn: boolean) => {
                  this.isSystemFollowEnabled = isOn;
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 12 })
          .borderRadius(0)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
