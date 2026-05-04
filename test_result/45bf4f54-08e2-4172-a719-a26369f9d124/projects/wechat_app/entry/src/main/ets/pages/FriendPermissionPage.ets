import router from '@ohos.router';

@Entry
@Component
struct FriendPermissionPage {
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
        Text('朋友权限')
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
          Column() {
            this.MenuItem('加我为朋友时需要验证', true, () => {
              // Toggle switch - placeholder
            })
            this.DescriptionItem('开启后，他人添加你为朋友时需要向你发送验证申请。')
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            this.MenuItem('向我推荐通讯录朋友', true, () => {
              // Toggle switch - placeholder
            })
            this.DescriptionItem('开启后，你可以向对方推荐通讯录里的朋友。')
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            this.MenuItem('添加我的方式', false, () => {
              // Placeholder
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            this.MenuItem('朋友圈权限', false, () => {
              // Placeholder
            })
            this.MenuItem('视频号权限', false, () => {
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
  MenuItem(title: string, isToggle: boolean, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#333333')
      Blank()
      if (isToggle) {
        Toggle({ type: ToggleType.Switch, isOn: true })
          .selectedColor('#07C160')
          .onClick(() => {
            onClick();
          })
      } else {
        Text('›')
          .fontSize(18)
          .fontColor('#CCCCCC')
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      if (!isToggle) {
        onClick();
      }
    })
    .border({
      width: { bottom: 0.5 },
      color: '#F1F1F1'
    })
  }

  @Builder
  DescriptionItem(text: string) {
    Text(text)
      .fontSize(12)
      .fontColor('#B3B3B3')
      .padding({ left: 16, right: 16, top: 8, bottom: 12 })
      .width('100%')
  }
}
