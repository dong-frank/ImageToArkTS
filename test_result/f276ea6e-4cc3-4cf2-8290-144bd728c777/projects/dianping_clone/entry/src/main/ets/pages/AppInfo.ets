import router from '@ohos.router';

interface AppInfoItem {
  key: string;
  value: string;
}

@Entry
@Component
struct AppInfo {
  private appInfoList: AppInfoItem[] = [
    { key: '名称', value: '大众点评' },
    { key: '下载渠道', value: 'App Store' },
    { key: '版本号', value: '11.62.3' },
    { key: '语言', value: '中文' }
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

        Text('应用相关信息')
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
        ForEach(this.appInfoList, (item: AppInfoItem, index: number) => {
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
          .border({ width: { bottom: index < this.appInfoList.length - 1 ? 0.5 : 0 }, color: '#F0F0F0' })
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
