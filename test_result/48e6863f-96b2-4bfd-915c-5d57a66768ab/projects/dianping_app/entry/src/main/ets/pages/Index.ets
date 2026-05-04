import router from '@ohos.router';

@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('大众点评')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF6600')
        .margin({ bottom: 12 })

      Text('正在加载...')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ bottom: 24 })

      Button('进入首页')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor('#FF6600')
        .borderRadius(20)
        .padding({ left: 24, right: 24 })
        .onClick(() => {
          router.replaceUrl({ url: 'pages/HomePage' });
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
  }
}