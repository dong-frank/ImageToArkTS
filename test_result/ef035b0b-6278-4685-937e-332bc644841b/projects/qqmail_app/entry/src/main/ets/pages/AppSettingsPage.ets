/**
 * AppSettingsPage - Application feature toggle list
 * Based on: Draft 13 (success)
 */
import router from '@ohos.router';

interface AppFeature {
  name: string;
  status: string;
  route?: string;
}

@Entry
@Component
struct AppSettingsPage {
  readonly features: AppFeature[] = [
    { name: '通讯录', status: '开启' },
    { name: '文件云盘', status: '开启', route: 'pages/InvoiceOnboardingPage' },
    { name: '附件管理', status: '开启' },
    { name: '每日悦读', status: '开启' },
    { name: '发票', status: '开启' },
    { name: '记事本', status: '开启' },
    { name: '日历', status: '开启' },
    { name: '在线文档', status: '开启' },
    { name: '贺卡', status: '开启' }
  ];

  handleBackTap(): void {
    router.back();
  }

  handleFeatureTap(feature: AppFeature): void {
    if (feature.route) {
      router.pushUrl({ url: feature.route });
    }
  }

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('←')
          .fontSize(20).fontColor('#4A90D9')
          .width(40).height(40).textAlign(TextAlign.Center)
          .onClick(() => { this.handleBackTap(); })

        Text('应用设置')
          .fontSize(17).fontWeight(FontWeight.Medium).fontColor('#1A1A1A')
          .layoutWeight(1).textAlign(TextAlign.Center)

        Column().width(40)
      }
      .width('100%').height(48).backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          ForEach(this.features, (feature: AppFeature, index: number) => {
            Row() {
              Text(feature.name)
                .fontSize(16).fontColor('#1A1A1A').layoutWeight(1)

              Text(feature.status)
                .fontSize(14).fontColor('#999999').margin({ right: 4 })

              Text('>')
                .fontSize(16).fontColor('#C0C0C0')
            }
            .width('100%')
            .height(48)
            .padding({ left: 16, right: 10 })
            .backgroundColor('#FFFFFF')
            .onClick(() => { this.handleFeatureTap(feature); })
          })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%').height('100%')
  }
}
