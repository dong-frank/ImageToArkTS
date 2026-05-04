import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct AboutPage {
  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })
        Text('关于我们')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Row()
          .width(22)
          .height(22)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // Brand section
          Column() {
            // Logo placeholder
            Circle()
              .width(64)
              .height(64)
              .fill('#FF6600')

            Text('大众点评')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ top: 12 })

            Text('V11.61.13')
              .fontSize(13)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
          .width('100%')
          .padding({ top: 40, bottom: 30 })
          .alignItems(HorizontalAlign.Center)

          // Menu list
          Column() {
            this.MenuItem('检查新版本', '新版本已发布，立即升级', () => {
              promptAction.showToast({ message: '正在检查更新...' });
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.MenuItem('喜欢我们，打分鼓励', '', () => {
              promptAction.showToast({ message: '感谢您的支持！' });
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.MenuItem('帮助商户', '', () => {
              // Navigate to merchant help
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.MenuItem('协议与声明', '', () => {
              router.pushUrl({ url: 'pages/PrivacyPolicyPage' });
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.MenuItem('营业执照', '', () => {
              // Show business license
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.MenuItem('意见反馈', '', () => {
              router.pushUrl({ url: 'pages/FeedbackPage' });
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 12, right: 12 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  MenuItem(label: string, trailingText: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)

      if (trailingText !== '') {
        Text(trailingText)
          .fontSize(12)
          .fontColor('#FF6600')
          .margin({ right: 8 })
      }

      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      onClick();
    })
  }
}
