import router from '@ohos.router';

// --- Feature toggle entry data ---
class FeatureEntry {
  label: string = '';
  status: string = '开启';

  constructor(label: string) {
    this.label = label;
  }
}

@Entry
@Component
struct AppSettingsList {
  // --- Feature list data ---
  private featureList: FeatureEntry[] = [
    new FeatureEntry('通讯录'),
    new FeatureEntry('文件云盘'),
    new FeatureEntry('附件管理'),
    new FeatureEntry('每日悦读'),
    new FeatureEntry('发票'),
    new FeatureEntry('记事本'),
    new FeatureEntry('日历'),
    new FeatureEntry('在线文档'),
    new FeatureEntry('贺卡'),
  ];

  // --- Confirmed navigation obligations ---
  // back → returns to pages/SettingsGeneral (high confidence)
  goBack() {
    router.back()
  }

  // --- Unresolved navigation targets (target pages not in page set) ---
  openFeatureSetting(label: string) {
    console.info('[AppSettingsList] openFeatureSetting: ' + label + ' — target page not covered')
  }

  build() {
    Column() {
      // --- Navigation bar ---
      Row() {
        Text('<')
          .fontSize(20)
          .fontColor('#007AFF')
          .padding({ left: 8, right: 12, top: 4, bottom: 4 })
          .onClick(() => this.goBack())

        Text('应用设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')

        Blank()
      }
      .width('100%')
      .height(44)
      .padding({ left: 8, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')

      // --- Feature list ---
      List() {
        ForEach(this.featureList, (item: FeatureEntry, index: number) => {
          ListItem() {
            Column() {
              Row() {
                Text(item.label)
                  .fontSize(16)
                  .fontColor('#000000')

                Blank()

                Text(item.status)
                  .fontSize(16)
                  .fontColor('#999999')
                  .padding({ right: 4 })

                Text('>')
                  .fontSize(18)
                  .fontColor('#C7C7CC')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .alignItems(VerticalAlign.Center)
              .onClick(() => this.openFeatureSetting(item.label))

              // Separator line (not after last item)
              if (index < this.featureList.length - 1) {
                Divider()
                  .strokeWidth(0.5)
                  .color('#E5E5EA')
                  .margin({ left: 16 })
              }
            }
            .width('100%')
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')
      .listDirection(Axis.Vertical)
      .divider({ strokeWidth: 0 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
