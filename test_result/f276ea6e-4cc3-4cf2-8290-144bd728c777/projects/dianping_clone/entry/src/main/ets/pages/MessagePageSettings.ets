import router from '@ohos.router';

interface ToggleItem {
  label: string;
  isOn: boolean;
}

@Entry
@Component
struct MessagePageSettings {
  @State messageSettings: ToggleItem[] = [
    { label: '赞/收藏/有帮助', isOn: true },
    { label: '评论和@', isOn: true },
    { label: '新增粉丝', isOn: true },
    { label: '活动消息', isOn: true },
    { label: '系统消息', isOn: true },
    { label: '订单消息', isOn: true },
    { label: '聊天消息', isOn: true },
    { label: '其他消息', isOn: true }
  ];

  @State dmSettings: ToggleItem[] = [
    { label: '接收陌生人私信', isOn: true },
    { label: '接收好友私信', isOn: true }
  ];

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

        Text('消息页设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })

      // Scrollable settings list
      Scroll() {
        Column() {
          // Section: 消息设置
          Text('消息设置')
            .fontSize(13)
            .fontColor('#999999')
            .padding({ left: 16, top: 16, bottom: 8 })
            .width('100%')

          ForEach(this.messageSettings, (item: ToggleItem, index: number) => {
            Column() {
              Row() {
                Text(item.label)
                  .fontSize(16)
                  .fontColor('#333333')
                  .layoutWeight(1)

                Toggle({ type: ToggleType.Switch, isOn: item.isOn })
                  .onChange((value: boolean) => {
                    this.messageSettings[index] = { label: item.label, isOn: value };
                    this.messageSettings = [...this.messageSettings];
                  })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .backgroundColor('#FFFFFF')

              if (index < this.messageSettings.length - 1) {
                Divider()
                  .strokeWidth(0.5)
                  .color('#F0F0F0')
                  .margin({ left: 16 })
              }
            }
            .width('100%')
          })

          // Section: 私信消息接收设置
          Text('私信消息接收设置')
            .fontSize(13)
            .fontColor('#999999')
            .padding({ left: 16, top: 24, bottom: 8 })
            .width('100%')

          ForEach(this.dmSettings, (item: ToggleItem, index: number) => {
            Column() {
              Row() {
                Text(item.label)
                  .fontSize(16)
                  .fontColor('#333333')
                  .layoutWeight(1)

                Toggle({ type: ToggleType.Switch, isOn: item.isOn })
                  .onChange((value: boolean) => {
                    this.dmSettings[index] = { label: item.label, isOn: value };
                    this.dmSettings = [...this.dmSettings];
                  })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .backgroundColor('#FFFFFF')

              if (index < this.dmSettings.length - 1) {
                Divider()
                  .strokeWidth(0.5)
                  .color('#F0F0F0')
                  .margin({ left: 16 })
              }
            }
            .width('100%')
          })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
