import router from '@ohos.router';

interface SettingsItemData {
  label: string;
  route?: string;
  isResolved: boolean;
}

@Entry
@Component
struct PersonalInfoManagement {
  private settingsItems: SettingsItemData[] = [
    { label: '账号资料', isResolved: false },
    { label: '当前设备信息', route: 'pages/DeviceInfo', isResolved: true },
    { label: '应用相关信息', route: 'pages/AppInfo', isResolved: true }
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

        Text('个人信息查看与管理')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Spacer to balance the back button
        Row()
          .width(48)
          .height(48)
      }
      .width('100%')
      .height(48)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })

      // Settings list
      List() {
        ForEach(this.settingsItems, (item: SettingsItemData, index: number) => {
          ListItem() {
            Row() {
              Text(item.label)
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)

              Text('>')
                .fontSize(16)
                .fontColor('#CCCCCC')
                .padding({ right: 16 })
            }
            .width('100%')
            .height(48)
            .alignItems(VerticalAlign.Center)
            .padding({ left: 16 })
            .backgroundColor('#FFFFFF')
            .onClick(() => {
              if (item.isResolved && item.route) {
                router.pushUrl({ url: item.route });
              } else {
                console.info('[PersonalInfoManagement] 账号资料 - 目标页未覆盖，暂不跳转');
              }
            })
          }
          .border({ width: { bottom: index < this.settingsItems.length - 1 ? 0.5 : 0 }, color: '#F0F0F0' })
        })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .listDirection(Axis.Vertical)
      .divider({ strokeWidth: 0 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
