import { router } from '@kit.ArkUI';

@Entry
@Component
struct VideoPlaybackSettingsPage {
  @State pipAutoToggle: boolean = true;
  @State pipInterruptToggle: boolean = true;

  onBack(): void {
    router.back();
  }

  onAutoPlayNav(): void {
    router.pushUrl({
      url: 'pages/AutoPlayDetailPage'
    });
  }

  build() {
    Column() {
      // ── Top Navigation Bar ──
      Row() {
        // Back button
        Text('←')
          .fontSize(22)
          .fontColor('#1A1A1A')
          .padding({ left: 4, right: 12, top: 8, bottom: 8 })
          .onClick(() => {
            this.onBack();
          })

        // Title
        Text('视频播放设置')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 12, right: 16 })
      .backgroundColor('#FFFFFF')
      .border({
        width: { bottom: 0.5 },
        color: '#E5E5E5'
      })

      // ── Content: Scrollable sections ──
      Scroll() {
        Column() {
          // ── Section 1: 视频播放设置 ──
          Column() {
            // Section header
            Text('视频播放设置')
              .fontSize(13)
              .fontColor('#8E8E93')
              .padding({ left: 20, bottom: 6 })
              .width('100%')

            // Section body (white card)
            Column() {
              // Navigation item: 推荐视频页面自动播放
              Row() {
                Column() {
                  Text('推荐视频页面自动播放')
                    .fontSize(16)
                    .fontColor('#1A1A1A')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text('开启自动播放')
                    .fontSize(13)
                    .fontColor('#999999')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // Chevron right arrow
                Text('›')
                  .fontSize(20)
                  .fontColor('#C7C7CC')
                  .padding({ left: 8 })
              }
              .width('100%')
              .height(56)
              .padding({ left: 20, right: 16 })
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                this.onAutoPlayNav();
              })
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ left: 16, right: 16 })
          }
          .width('100%')
          .margin({ top: 12 })

          // Section spacing
          Blank().height(20)

          // ── Section 2: 小窗播放设置 ──
          Column() {
            // Section header
            Text('小窗播放设置')
              .fontSize(13)
              .fontColor('#8E8E93')
              .padding({ left: 20, bottom: 6 })
              .width('100%')

            // Section body (white card)
            Column() {
              // Toggle item 1: 视频自动小窗设置
              Row() {
                Column() {
                  Text('视频自动小窗设置')
                    .fontSize(16)
                    .fontColor('#1A1A1A')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text('观看直播时，访问 App 内其它页面时生效')
                    .fontSize(13)
                    .fontColor('#999999')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({ right: 12 })

                Toggle({ type: ToggleType.Switch, isOn: this.pipAutoToggle })
                  .selectedColor('#007AFF')
                  .onChange((value: boolean) => {
                    this.pipAutoToggle = value;
                  })
              }
              .width('100%')
              .height(56)
              .padding({ left: 20, right: 16, top: 10, bottom: 10 })
              .alignItems(VerticalAlign.Center)

              // Divider
              Divider()
                .strokeWidth(0.5)
                .color('#E8E8E8')
                .margin({ left: 20 })

              // Toggle item 2: 播放中断时自动小窗播放
              Row() {
                Column() {
                  Text('播放中断时自动小窗播放')
                    .fontSize(16)
                    .fontColor('#1A1A1A')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text('观看直播和视频时，切换至 APP 外生效')
                    .fontSize(13)
                    .fontColor('#999999')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({ right: 12 })

                Toggle({ type: ToggleType.Switch, isOn: this.pipInterruptToggle })
                  .selectedColor('#007AFF')
                  .onChange((value: boolean) => {
                    this.pipInterruptToggle = value;
                  })
              }
              .width('100%')
              .height(56)
              .padding({ left: 20, right: 16, top: 10, bottom: 10 })
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ left: 16, right: 16 })
          }
          .width('100%')

          // Bottom safe area
          Blank().height(32)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}
