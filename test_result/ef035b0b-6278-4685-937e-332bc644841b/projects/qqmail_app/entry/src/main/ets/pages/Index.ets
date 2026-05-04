/**
 * Index - Launch redirect page
 * Immediately navigates to the app entry: ServiceHubPage
 */
import router from '@ohos.router';

@Entry
@Component
struct Index {
  aboutToAppear(): void {
    router.replaceUrl({ url: 'pages/ServiceHubPage' });
  }

  build() {
    Column() {
      Text('QQ Mail')
        .fontSize(20)
        .fontColor('#4A90D9')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
  }
}