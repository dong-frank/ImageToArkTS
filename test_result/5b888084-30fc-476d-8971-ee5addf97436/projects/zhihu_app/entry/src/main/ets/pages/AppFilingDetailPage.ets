import { router } from '@kit.ArkUI';

@Entry
@Component
struct AppFilingDetailPage {
  onBack(): void {
    router.back();
  }

  onFilingNumberTap(): void {
    // 备案编号为不确定的可点击链接，可能跳转工信部公示平台
    // 当前保留为占位，点击后不做真实外链跳转
    console.info('AppFilingDetailPage: 备案编号被点击，目标外链未确认');
  }

  build() {
    Column() {
      // ── Top Navigation Bar ──
      Row() {
        Text('<')
          .fontSize(24)
          .fontColor('#1A1A1A')
          .padding({ left: 4, right: 12, top: 8, bottom: 8 })
          .onClick(() => {
            this.onBack();
          })

        Text('APP 备案编号')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .layoutWeight(1)

        Text('⋯')
          .fontSize(22)
          .fontColor('#1A1A1A')
          .padding({ left: 12, right: 4, top: 8, bottom: 8 })
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#FFFFFF')
      .border({
        width: { bottom: 0.5 },
        color: '#E0E0E0'
      })

      // ── Content: Single info row ──
      Scroll() {
        Column() {
          Row() {
            Text('APP 备案编号')
              .fontSize(16)
              .fontColor('#1A1A1A')

            Blank()

            Text('京ICP备13052560号-7A')
              .fontSize(16)
              .fontColor('#0066CC')
              .onClick(() => {
                this.onFilingNumberTap();
              })
          }
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FFFFFF')
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
