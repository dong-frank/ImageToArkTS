import router from '@ohos.router';

@Entry
@Component
struct Index {
  aboutToAppear() {
    router.replaceUrl({ url: 'pages/ChatListPage' })
  }
  build() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
  }
}
