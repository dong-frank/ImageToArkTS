import router from '@ohos.router';

@Entry
@Component
struct SystemPermissionManagement {
  @State calendarToggle: boolean = false;
  @State contactsToggle: boolean = false;

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

        Text('系统权限管理')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })

      // Permission list (scrollable)
      Scroll() {
        Column() {
          // 1. 位置 - 已允许访问
          Row() {
            Column() {
              Text('位置')
                .fontSize(16)
                .fontColor('#333333')
              Text('根据位置信息推荐你周边的生活服务')
                .fontSize(13)
                .fontColor('#999999')
                .margin({ top: 4 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('已允许访问')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ right: 4 })

            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor('#FFFFFF')
          .alignItems(VerticalAlign.Center)

          Divider()
            .strokeWidth(0.5)
            .color('#F0F0F0')
            .margin({ left: 16 })

          // 2. 相机 - 已允许访问
          Row() {
            Column() {
              Text('相机')
                .fontSize(16)
                .fontColor('#333333')
              Text('进行拍照、录视频及扫码，用于登录、发布内容及买单')
                .fontSize(13)
                .fontColor('#999999')
                .margin({ top: 4 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('已允许访问')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ right: 4 })

            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor('#FFFFFF')
          .alignItems(VerticalAlign.Center)

          Divider()
            .strokeWidth(0.5)
            .color('#F0F0F0')
            .margin({ left: 16 })

          // 3. 麦克风 - 已允许访问
          Row() {
            Column() {
              Text('麦克风')
                .fontSize(16)
                .fontColor('#333333')
              Text('用于语音搜索、语音输入及视频录制')
                .fontSize(13)
                .fontColor('#999999')
                .margin({ top: 4 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('已允许访问')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ right: 4 })

            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor('#FFFFFF')
          .alignItems(VerticalAlign.Center)

          Divider()
            .strokeWidth(0.5)
            .color('#F0F0F0')
            .margin({ left: 16 })

          // 4. 相册 - 已允许访问
          Row() {
            Column() {
              Text('相册')
                .fontSize(16)
                .fontColor('#333333')
              Text('用于添加、编辑、制作、上传、发布、下载、保存、识别图片和视频等功能')
                .fontSize(13)
                .fontColor('#999999')
                .margin({ top: 4 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('已允许访问')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ right: 4 })

            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor('#FFFFFF')
          .alignItems(VerticalAlign.Center)

          Divider()
            .strokeWidth(0.5)
            .color('#F0F0F0')
            .margin({ left: 16 })

          // 5. 通知 - 暂未允许，去设置 (warning style)
          Row() {
            Column() {
              Text('通知')
                .fontSize(16)
                .fontColor('#333333')
              Text('接收消息推送、活动提醒及系统通知')
                .fontSize(13)
                .fontColor('#999999')
                .margin({ top: 4 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('暂未允许，去设置')
              .fontSize(14)
              .fontColor('#FF6600')
              .margin({ right: 4 })

            Text('>')
              .fontSize(14)
              .fontColor('#FF6600')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor('#FFFFFF')
          .alignItems(VerticalAlign.Center)

          Divider()
            .strokeWidth(0.5)
            .color('#F0F0F0')
            .margin({ left: 16 })

          // 6. 日历 - Toggle OFF
          Row() {
            Column() {
              Text('日历')
                .fontSize(16)
                .fontColor('#333333')
              Text('用于添加活动提醒、日程管理等功能')
                .fontSize(13)
                .fontColor('#999999')
                .margin({ top: 4 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.calendarToggle })
              .onChange((isOn: boolean) => {
                this.calendarToggle = isOn;
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor('#FFFFFF')
          .alignItems(VerticalAlign.Center)

          Divider()
            .strokeWidth(0.5)
            .color('#F0F0F0')
            .margin({ left: 16 })

          // 7. 通讯录 - Toggle OFF
          Row() {
            Column() {
              Text('通讯录')
                .fontSize(16)
                .fontColor('#333333')
              Text('获取手机中的联系人信息，用于分享、交流和互动')
                .fontSize(13)
                .fontColor('#999999')
                .margin({ top: 4 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.contactsToggle })
              .onChange((isOn: boolean) => {
                this.contactsToggle = isOn;
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor('#FFFFFF')
          .alignItems(VerticalAlign.Center)
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
}
