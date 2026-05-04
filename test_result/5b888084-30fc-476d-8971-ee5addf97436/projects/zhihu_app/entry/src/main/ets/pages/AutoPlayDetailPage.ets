import { router } from '@kit.ArkUI';

@Entry
@Component
struct AutoPlayDetailPage {
  @State selectedOption: string = '开启自动播放';

  private options: string[] = [
    '开启自动播放',
    '仅 Wi-Fi 下自动播放',
    '关闭自动播放'
  ];

  onBack(): void {
    router.back();
  }

  onSelectOption(option: string): void {
    this.selectedOption = option;
  }

  build() {
    Column() {
      // ── Top Navigation Bar ──
      Row() {
        // Back button
        Text('‹')
          .fontSize(28)
          .fontColor('#1A1A1A')
          .padding({ left: 4, right: 12, top: 2, bottom: 4 })
          .onClick(() => {
            this.onBack();
          })

        // Title
        Text('推荐视频页面自动播放')
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

      // ── Content: Scrollable list ──
      Scroll() {
        Column() {
          // Spacing above the option list
          Column()
            .width('100%')
            .height(20)

          // ── Radio option list card ──
          Column() {
            ForEach(this.options, (option: string, index: number) => {
              Column() {
                Row() {
                  Text(option)
                    .fontSize(16)
                    .fontColor('#1A1A1A')
                    .layoutWeight(1)

                  // Checkmark for selected option
                  if (option === this.selectedOption) {
                    Text('✓')
                      .fontSize(18)
                      .fontColor('#007AFF')
                      .fontWeight(FontWeight.Medium)
                      .padding({ left: 8 })
                  }
                }
                .width('100%')
                .height(48)
                .padding({ left: 20, right: 16 })
                .alignItems(VerticalAlign.Center)
                .onClick(() => {
                  this.onSelectOption(option);
                })

                // Divider between items (not after the last)
                if (index < this.options.length - 1) {
                  Divider()
                    .strokeWidth(0.5)
                    .color('#E5E5E5')
                    .margin({ left: 20 })
                }
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16 })

          // ── Footer scope notice ──
          Text('设置后，将在推荐页/关注页/个人动态页/搜索/问题中的视频/直播广场生效')
            .fontSize(13)
            .fontColor('#8E8E93')
            .padding({ left: 20, right: 20, top: 12 })
            .width('100%')
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
