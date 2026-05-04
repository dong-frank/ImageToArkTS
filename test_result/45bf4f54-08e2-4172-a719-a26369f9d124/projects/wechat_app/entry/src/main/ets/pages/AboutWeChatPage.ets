import router from '@ohos.router';

@Entry
@Component
struct AboutWeChatPage {
  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })
        Text('关于微信')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Row()
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#EDEDED')

      Scroll() {
        Column() {
          Column() {
            Text('微信')
              .fontSize(20)
              .fontColor('#333333')
              .fontWeight(FontWeight.Bold)
            Text('Version 8.0.71')
              .fontSize(13)
              .fontColor('#B3B3B3')
              .margin({ top: 6 })
          }
          .width('100%')
          .padding({ top: 32, bottom: 32 })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            this.MenuItem('去评分', () => {
              // Placeholder - external app store
            })
            this.MenuItem('功能介绍', () => {
              router.pushUrl({ url: 'pages/FeatureIntroPage' });
            })
            this.MenuItem('投诉', () => {
              // Placeholder
            })
            this.MenuItem('版本更新', () => {
              // Placeholder
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })

          Column() {
            this.FooterLink('《软件许可及服务协议》')
            this.FooterLink('《隐私保护指引摘要》')
            this.FooterLink('《隐私保护指引》')
            this.FooterItem('客服电话：400 670 0700', false)
            this.FooterItem('ICP备案信息：粤B2-20090059-1621A', true)
            this.FooterItem('算法备案信息', true)
            this.FooterItem('腾讯公司 版权所有', false)
            this.FooterItem('Copyright © 2011-2026 Tencent. All Rights Reserved.', false)
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16, bottom: 16 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#EDEDED')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MenuItem(title: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#333333')
      Blank()
      Text('›')
        .fontSize(18)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      onClick();
    })
    .border({
      width: { bottom: 0.5 },
      color: '#F1F1F1'
    })
  }

  @Builder
  FooterItem(text: string, showArrow: boolean) {
    Row() {
      Text(text)
        .fontSize(12)
        .fontColor('#999999')
      Blank()
      if (showArrow) {
        Text('›')
          .fontSize(14)
          .fontColor('#CCCCCC')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .border({
      width: { bottom: 0.5 },
      color: '#F1F1F1'
    })
  }

  @Builder
  FooterLink(text: string) {
    Row() {
      Text(text)
        .fontSize(12)
        .fontColor('#576B95')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .border({
      width: { bottom: 0.5 },
      color: '#F1F1F1'
    })
  }
}
