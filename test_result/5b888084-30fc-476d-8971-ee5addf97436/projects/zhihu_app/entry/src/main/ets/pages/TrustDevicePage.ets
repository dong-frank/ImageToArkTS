import { router } from '@kit.ArkUI';

@Entry
@Component
struct TrustDevicePage {
  build() {
    Column() {
      // ─── Top Navigation Bar ───
      this.buildNavBar();

      // ─── Status Banner: 暂无信任设备 ───
      Row() {
        Text('暂无信任设备')
          .fontSize(14)
          .fontColor('#8E8E93')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 12, bottom: 12 })
      .backgroundColor('#F2F2F7')

      // ─── CTA: Centered blue link button ───
      Blank()
        .layoutWeight(1)

      Button('将本机设置为信任设备')
        .fontSize(16)
        .fontColor('#0066CC')
        .backgroundColor(Color.Transparent)
        .type(ButtonType.Normal)
        .onClick(() => {
          // Trigger trust device registration flow
          // TODO: Connect to actual trust device registration service when available
          console.info('[TrustDevice] 触发信任设备注册流程');
        })

      // ─── Description text ───
      Text('设置成功后，在此设备上登录和使用知乎就会被视为安全使用，无需进行安全验证。')
        .fontSize(13)
        .fontColor('#999999')
        .lineHeight(20)
        .maxLines(3)
        .padding({ left: 32, right: 32, top: 16, bottom: 0 })
        .textAlign(TextAlign.Start)
        .width('100%')

      Blank()
        .layoutWeight(1.2)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  // ─── Navigation Bar ───
  @Builder
  buildNavBar() {
    Row() {
      // Back button
      Text('\uE0D9')
        .fontSize(28)
        .fontColor('#1A1A1A')
        .padding({ left: 16, right: 12, top: 12, bottom: 12 })
        .onClick(() => {
          router.back();
        })

      // Title
      Text('信任设备')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A1A')

      Blank()
    }
    .width('100%')
    .height(56)
    .backgroundColor('#FFFFFF')
    .border({
      width: { bottom: 0.5 },
      color: '#E5E5E5'
    })
  }
}
