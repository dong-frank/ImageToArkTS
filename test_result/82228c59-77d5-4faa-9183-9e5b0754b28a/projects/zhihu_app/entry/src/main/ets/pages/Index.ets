import router from '@ohos.router';

@Entry
@Component
struct Index {
  onPageShow(): void {
    router.replaceUrl({ url: 'pages/HomePage' });
  }

  build() {
    Column() {
      Text('加载中...')
        .fontSize(16)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}