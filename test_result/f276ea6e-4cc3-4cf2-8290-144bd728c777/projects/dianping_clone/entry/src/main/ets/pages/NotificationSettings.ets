import router from '@ohos.router';

@Entry
@Component
struct NotificationSettings {
  @State interactionToggle: boolean = true;
  @State activityToggle: boolean = true;
  @State systemToggle: boolean = true;

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ left: 16, right: 8, top: 12, bottom: 12 })
          .onClick(() => {
            router.back();
          })

        Text('消息通知设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .padding({ top: 12, bottom: 12 })

        // Spacer for symmetry with back button
        Row()
          .width(48)
          .height(48)
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })

      // Scrollable content
      Scroll() {
        Column() {
          // Section: 大众点评未打开时
          Text('大众点评未打开时')
            .fontSize(13)
            .fontColor('#999999')
            .padding({ left: 16, top: 20, bottom: 8 })
            .width('100%')

          // System notification item (read-only, with chevron)
          Row() {
            Column() {
              Text('系统通知')
                .fontSize(16)
                .fontColor('#333333')
              Text('排队/订单动态、推荐内容等通知')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('已关闭')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ right: 4 })

            Text('›')
              .fontSize(18)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor('#FFFFFF')
          .onClick(() => {
            // External system settings - unresolved navigation
            console.info('系统通知：跳转系统设置开启通知（外部跳转，当前未实现）');
          })

          // Section: 大众点评打开时
          Text('大众点评打开时')
            .fontSize(13)
            .fontColor('#999999')
            .padding({ left: 16, top: 24, bottom: 8 })
            .width('100%')

          // Toggle group container
          Column() {
            // 互动通知 toggle
            Row() {
              Text('互动通知')
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.interactionToggle })
                .onChange((value: boolean) => {
                  this.interactionToggle = value;
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .backgroundColor('#FFFFFF')

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            // 活动通知 toggle
            Row() {
              Text('活动通知')
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.activityToggle })
                .onChange((value: boolean) => {
                  this.activityToggle = value;
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .backgroundColor('#FFFFFF')

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            // 系统通知 toggle
            Row() {
              Text('系统通知')
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.systemToggle })
                .onChange((value: boolean) => {
                  this.systemToggle = value;
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .backgroundColor('#FFFFFF')
          }

          // Spacer before 消息页设置
          Text('')
            .height(24)
            .width('100%')

          // 消息页设置 entry
          Row() {
            Text('消息页设置')
              .fontSize(16)
              .fontColor('#333333')
              .layoutWeight(1)

            Text('›')
              .fontSize(18)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor('#FFFFFF')
          .onClick(() => {
            router.pushUrl({ url: 'pages/MessagePageSettings' });
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
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
