import router from '@ohos.router';

@Entry
@Component
struct Index {
  aboutToAppear() {
    try {
      router.replaceUrl({ url: 'pages/HomeDiscovery' })
    } catch (error) {
      console.error('Navigation failed:', error);
    }
  }

  build() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
  }
}
