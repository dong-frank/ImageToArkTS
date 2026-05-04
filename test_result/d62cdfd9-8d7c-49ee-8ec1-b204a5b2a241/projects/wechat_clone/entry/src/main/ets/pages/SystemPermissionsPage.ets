import router from '@ohos.router';

@Entry
@Component
struct SystemPermissionsPage {
  @Builder
  BackButton() {
    Row() {
      Text('<')
        .fontSize(22)
        .fontColor('#333333')
        .fontWeight(FontWeight.Normal)
    }
    .width(44)
    .height(44)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      router.back();
    })
  }

  @Builder
  NavBar() {
    Row() {
      this.BackButton()
      Text('系统权限管理')
        .fontSize(18)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Row()
        .width(44)
        .height(44)
    }
    .width('100%')
    .height(48)
    .padding({ left: 4, right: 4 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#E5E5E5' })
  }

  getIconText(icon: string): string {
    switch (icon) {
      case 'location':
        return '📍';
      case 'photo':
        return '🖼';
      case 'camera':
        return '📷';
      case 'microphone':
        return '🎤';
      case 'running':
        return '🏃';
      case 'bluetooth':
        return '📶';
      case 'network':
        return '🌐';
      default:
        return '›';
    }
  }

  @Builder
  PermissionItem(icon: string, title: string, description: string, onTap: () => void) {
    Row() {
      // Icon
      Row() {
        Text(this.getIconText(icon))
          .fontSize(18)
      }
      .width(36)
      .height(36)
      .justifyContent(FlexAlign.Center)

      // Title + Description
      Column() {
        Text(title)
          .fontSize(16)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(description)
          .fontSize(13)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      // Chevron
      Text('>')
        .fontSize(16)
        .fontColor('#C0C0C0')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      onTap();
    })
  }

  @Builder
  ItemDivider() {
    Row()
      .width('100%')
      .height(0.5)
      .backgroundColor('#E5E5E5')
      .margin({ left: 64 })
  }

  build() {
    Column() {
      this.NavBar()

      Scroll() {
        Column() {
          this.PermissionItem('location', '位置',
            '发送或共享位置，提供与地理位置相关的推荐和搜索服务如附近、视频号等。',
            () => { console.info('navigate to location permission detail'); }
          )
          this.ItemDivider()
          this.PermissionItem('photo', '照片',
            '发送相册内的图片与视频等功能。',
            () => { console.info('navigate to photo permission detail'); }
          )
          this.ItemDivider()
          this.PermissionItem('camera', '相机',
            '拍摄后发送图片或视频，使用视频通话、扫一扫等功能。',
            () => { console.info('navigate to camera permission detail'); }
          )
          this.ItemDivider()
          this.PermissionItem('microphone', '麦克风',
            '发送语音消息，进行音视频通话。',
            () => { console.info('navigate to microphone permission detail'); }
          )
          this.ItemDivider()
          this.PermissionItem('running', '运动与健身',
            '参与微信运动排行榜。',
            () => { console.info('navigate to running permission detail'); }
          )
          this.ItemDivider()
          this.PermissionItem('bluetooth', '蓝牙',
            '访问蓝牙设备以及读取设备中的数据。',
            () => { console.info('navigate to bluetooth permission detail'); }
          )
          this.ItemDivider()
          this.PermissionItem('network', '本地网络',
            '判断本地网络情况，以提高音视频通话质量，以及连接同局域网下其他设备进行聊天记录迁移或备份。',
            () => { console.info('navigate to local network permission detail'); }
          )
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

export default SystemPermissionsPage;
