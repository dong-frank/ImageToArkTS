import router from '@ohos.router';

interface DeviceInfoItem {
  key: string;
  value: string;
}

@Entry
@Component
struct DeviceInfo {
  private deviceInfoList: DeviceInfoItem[] = [
    { key: '操作系统', value: 'iOS' },
    { key: '系统版本', value: '26.3.1' },
    { key: '分辨率', value: '1179*2556' },
    { key: '语言', value: '简体中文' },
    { key: '地区', value: '中国' },
    { key: '时区', value: 'Asia/Shanghai' }
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

        Text('当前设备信息')
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

      // Key-value list
      List({ space: 0 }) {
        ForEach(this.deviceInfoList, (item: DeviceInfoItem, index: number) => {
          ListItem() {
            Row() {
              Text(item.key)
                .fontSize(16)
                .fontColor('#333333')

              Blank()

              Text(item.value)
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            .backgroundColor('#FFFFFF')
          }
          .border({ width: { bottom: index < this.deviceInfoList.length - 1 ? 0.5 : 0 }, color: '#F0F0F0' })
        })
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
