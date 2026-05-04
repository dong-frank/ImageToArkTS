import router from '@ohos.router';

@Entry
@Component
struct SecurityCenterPage {
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
        Text('安全中心')
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
          // Security overview
          Column() {
            Text('安全检测')
              .fontSize(16)
              .fontColor('#333333')
            Text('未发现风险')
              .fontSize(13)
              .fontColor('#07C160')
              .margin({ top: 4 })
          }
          .width('100%')
          .height(72)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 16 })
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            this.ActionItem('修改密码', () => {
              // Placeholder
            })
            this.ActionItem('冻结账号', () => {
              // Placeholder
            })
            this.ActionItem('解冻账号', () => {
              // Placeholder
            })
            this.ActionItem('找回密码', () => {
              // Placeholder
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
  ActionItem(title: string, onClick: () => void) {
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
}
