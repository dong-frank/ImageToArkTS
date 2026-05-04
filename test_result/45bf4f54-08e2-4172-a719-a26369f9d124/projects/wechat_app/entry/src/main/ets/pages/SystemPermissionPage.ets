import router from '@ohos.router';

@Entry
@Component
struct SystemPermissionPage {
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
        Text('系统权限管理')
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
            this.PermissionItem('位置', '未授权', () => {
              // Placeholder
            })
            this.PermissionItem('相机', '仅使用中允许', () => {
              // Placeholder
            })
            this.PermissionItem('麦克风', '仅使用中允许', () => {
              // Placeholder
            })
            this.PermissionItem('相册', '已授权', () => {
              // Placeholder
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            this.PermissionItem('通讯录', '已授权', () => {
              // Placeholder
            })
            this.PermissionItem('日历', '未授权', () => {
              // Placeholder
            })
            this.PermissionItem('传感器', '未授权', () => {
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
  PermissionItem(permissionName: string, status: string, onClick: () => void) {
    Row() {
      Text(permissionName)
        .fontSize(16)
        .fontColor('#333333')
      Blank()
      Text(status)
        .fontSize(14)
        .fontColor('#999999')
        .margin({ right: 4 })
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
