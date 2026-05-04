import router from '@ohos.router';

@Entry
@Component
struct PermissionManagementPage {
  @State analyzeAlbumEnabled: boolean = false;
  @State useAlbumLocationEnabled: boolean = false;
  @State useAlbumContentEnabled: boolean = false;

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
        Text('系统权限管理')
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
          // Permission items
          Column() {
            this.PermissionNavItem(
              '位置信息权限',
              '根据位置信息推荐你周边的生活服务',
              '已允许访问'
            )

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.PermissionNavItem(
              '相机权限',
              '进行拍照、录视频及扫码，用于登录、发布内容及买单',
              '已允许访问'
            )

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.PermissionNavItem(
              '相册权限',
              '用于添加、编辑、制作、上传、发布、下载、保存、识别图片和视频等功能',
              '已允许访问'
            )

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.PermissionToggleItem(
              '分析相册内容权限',
              '开启后，我们仅会在你授权访问的本地相册范围内，于设备本地识别并分析图片的位置、时间和内容信息，用于打卡、写评价、写笔记、标记好去处场景。关闭后，将不再识别和分析你手机相册中的内容。',
              this.analyzeAlbumEnabled,
              (value: boolean) => {
                this.analyzeAlbumEnabled = value;
              }
            )

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.PermissionToggleItem(
              '允许使用相册内容的位置信息',
              '开启后，将在发布时依据你相册中照片和视频的位置信息为你推荐拍摄地点；若关闭，将不使用相册内容的位置信息。',
              this.useAlbumLocationEnabled,
              (value: boolean) => {
                this.useAlbumLocationEnabled = value;
              }
            )

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.PermissionToggleItem(
              '允许使用相册的内容信息',
              '开启后，我们仅在你使用模板滤镜推荐、美颜、智能遮挡、菜品标签等智能编辑功能时，分析你上传的图片／视频画面内容；若关闭，将无法使用上述智能编辑功能，其他不涉及画面内容分析的基础编辑功能不受影响。',
              this.useAlbumContentEnabled,
              (value: boolean) => {
                this.useAlbumContentEnabled = value;
              }
            )
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 12, right: 12, top: 12 })
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
  PermissionNavItem(title: string, description: string, status: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor('#333333')
        Text(description)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(status)
        .fontSize(13)
        .fontColor('#999999')
        .margin({ right: 8 })

      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }

  @Builder
  PermissionToggleItem(
    title: string,
    description: string,
    isOn: boolean,
    onChange: (value: boolean) => void
  ) {
    Column() {
      Row() {
        Text(title)
          .fontSize(15)
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
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }
}
