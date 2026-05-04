import router from '@ohos.router';

@Entry
@Component
struct AccountSecurityPage {
  @State personalizedRecommendEnabled: boolean = true;

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })
        Text('账号与安全')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Row()
          .width(22)
          .height(22)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // Section: 隐私政策相关
          Column() {
            this.NavItem('隐私政策', () => {
              router.pushUrl({ url: 'pages/PrivacyPolicyPage' });
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.NavItem('隐私政策概要', () => {
              // Navigate to privacy summary
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.NavItem('应用权限说明', () => {
              router.pushUrl({ url: 'pages/PermissionManagementPage' });
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.NavItem('未成年人保护', () => {
              // Navigate to minor protection
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 12, right: 12, top: 12 })

          // Section: 个性化设置
          Row() {
            Text('个性化设置')
              .fontSize(13)
              .fontColor('#999999')
              .padding({ left: 16, top: 20, bottom: 8 })
          }
          .width('100%')

          Column() {
            this.ToggleSettingItem(
              '接收个性化内容推荐',
              '关闭后将无法收到个性化推荐，建议开启以看到更多感兴趣内容。',
              this.personalizedRecommendEnabled,
              (value: boolean) => {
                this.personalizedRecommendEnabled = value;
              }
            )

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.NavItem('内容推荐算法说明', () => {
              // Navigate to algorithm explanation
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.NavItem('清除历史个性记录', () => {
              // Clear history
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 12, right: 12 })
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

  @Builder
  NavItem(label: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)

      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      onClick();
    })
  }

  @Builder
  ToggleSettingItem(
    label: string,
    description: string,
    isOn: boolean,
    onChange: (value: boolean) => void
  ) {
    Column() {
      Row() {
        Text(label)
          .fontSize(16)
          .fontColor('#333333')
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: isOn })
          .selectedColor('#FF6600')
          .onChange((value: boolean) => {
            onChange(value);
          })
      }
      .width('100%')

      Text(description)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 6 })
        .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }
}
