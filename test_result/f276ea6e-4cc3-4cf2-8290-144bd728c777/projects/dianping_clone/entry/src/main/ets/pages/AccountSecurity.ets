import router from '@ohos.router';

@Entry
@Component
struct AccountSecurity {
  build() {
    Column() {
      // Navigation bar: back button + title
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ left: 16, right: 8, top: 12, bottom: 12 })
          .onClick(() => {
            router.back();
          })

        Text('账号与安全')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')

        Blank()
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center)

      // Divider below nav bar
      Divider()
        .height(0.5)
        .color('#E5E5E5')

      // Scrollable settings list
      Scroll() {
        Column() {
          // Group 1: Account info
          Column() {
            // 手机号
            Row() {
              Text('手机号')
                .fontSize(16)
                .fontColor('#1A1A1A')

              Blank()

              Text('135****3087')
                .fontSize(14)
                .fontColor('#999999')

              Text('>')
                .fontSize(16)
                .fontColor('#CCCCCC')
                .padding({ left: 6 })
            }
            .width('100%')
            .height(52)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              console.info('[AccountSecurity] 手机号 - 修改手机号页未覆盖');
            })

            Divider()
              .height(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            // 密码
            Row() {
              Text('密码')
                .fontSize(16)
                .fontColor('#1A1A1A')

              Blank()

              Text('修改')
                .fontSize(14)
                .fontColor('#007AFF')

              Text('>')
                .fontSize(16)
                .fontColor('#CCCCCC')
                .padding({ left: 6 })
            }
            .width('100%')
            .height(52)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              console.info('[AccountSecurity] 密码 - 修改密码页未覆盖');
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(0)

          // Section gap
          Column()
            .width('100%')
            .height(10)
            .backgroundColor('#F5F5F5')

          // Group 2: Third-party account binding
          Column() {
            // Section header
            Row() {
              Text('第三方账号绑定')
                .fontSize(13)
                .fontColor('#999999')
                .padding({ left: 16, top: 14, bottom: 8 })
            }
            .width('100%')

            // 微信
            Row() {
              Text('微信')
                .fontSize(16)
                .fontColor('#1A1A1A')

              Blank()

              Text('已绑定')
                .fontSize(14)
                .fontColor('#999999')

              Text('>')
                .fontSize(16)
                .fontColor('#CCCCCC')
                .padding({ left: 6 })
            }
            .width('100%')
            .height(52)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              console.info('[AccountSecurity] 微信 - 微信绑定管理页未覆盖');
            })

            Divider()
              .height(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            // QQ
            Row() {
              Text('QQ')
                .fontSize(16)
                .fontColor('#1A1A1A')

              Blank()

              Text('未绑定')
                .fontSize(14)
                .fontColor('#999999')

              Text('>')
                .fontSize(16)
                .fontColor('#CCCCCC')
                .padding({ left: 6 })
            }
            .width('100%')
            .height(52)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              console.info('[AccountSecurity] QQ - QQ绑定页未覆盖');
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          // Section gap
          Column()
            .width('100%')
            .height(10)
            .backgroundColor('#F5F5F5')

          // Group 3: Account management
          Column() {
            // Section header
            Row() {
              Text('账号管理')
                .fontSize(13)
                .fontColor('#999999')
                .padding({ left: 16, top: 14, bottom: 8 })
            }
            .width('100%')

            // 注销账号 (danger style)
            Row() {
              Text('注销账号')
                .fontSize(16)
                .fontColor('#FF3B30')

              Blank()

              Text('>')
                .fontSize(16)
                .fontColor('#CCCCCC')
                .padding({ left: 6 })
            }
            .width('100%')
            .height(52)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              console.info('[AccountSecurity] 注销账号 - 注销账号确认页未覆盖');
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
