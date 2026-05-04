import router from '@ohos.router';

interface SecurityCardItem {
  icon: string;
  title: string;
  subtitle: string;
  route?: string;
}

@Entry
@Component
struct SecurityCenterPage {
  private cardItems: SecurityCardItem[] = [
    {
      icon: '\u{1F511}',
      title: '找回账号密码',
      subtitle: '申诉找回微信账号密码',
      route: 'pages/PasswordRecoveryPage'
    },
    {
      icon: '\u{1F6AB}',
      title: '解封账号',
      subtitle: '账号因违规或其他原因被限制登录，申请解封',
      route: 'pages/UnblockAccountPage'
    },
    {
      icon: '\u{1F512}',
      title: '冻结账号',
      subtitle: '自己或朋友的账号被盗、手机丢失，可以冻结微信',
      route: 'pages/FreezeAccountPage'
    },
    {
      icon: '\u{1F513}',
      title: '解冻账号',
      subtitle: '解除安全风险后，你可以解冻微信账号',
      route: 'pages/UnfreezeAccountPage'
    },
    {
      icon: '\u{26A0}',
      title: '投诉维权',
      subtitle: '了解如何投诉违规或侵权行为',
      route: 'pages/ComplaintPage'
    },
    {
      icon: '\u{2716}',
      title: '注销账号',
      subtitle: '提交申请，删除所有数据，永久注销',
      route: 'pages/DeleteAccountPage'
    }
  ];

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('×')
          .fontSize(28)
          .fontColor('#333333')
          .width(40)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.back();
          })

        Text('微信安全中心')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('⋯')
          .fontSize(20)
          .fontColor('#333333')
          .width(40)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(44)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#EDEDED')
      .justifyContent(FlexAlign.Center)

      // Scrollable card list
      Scroll() {
        Column({ space: 0 }) {
          // 6 action cards
          Column({ space: 0 }) {
            ForEach(this.cardItems, (item: SecurityCardItem, index: number) => {
              Column() {
                Row({ space: 12 }) {
                  // Icon
                  Text(item.icon)
                    .fontSize(28)
                    .width(44)
                    .height(44)
                    .textAlign(TextAlign.Center)
                    .borderRadius(8)
                    .backgroundColor('#E8F5E9')

                  // Text content
                  Column({ space: 4 }) {
                    Text(item.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#191919')
                    Text(item.subtitle)
                      .fontSize(13)
                      .fontColor('#808080')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  // Arrow
                  Text('›')
                    .fontSize(22)
                    .fontColor('#B0B0B0')
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                .alignItems(VerticalAlign.Center)

                // Divider between items (skip after last)
                if (index < this.cardItems.length - 1) {
                  Divider()
                    .strokeWidth(0.5)
                    .color('#E5E5E5')
                    .margin({ left: 72 })
                }
              }
              .onClick(() => {
                if (item.route) {
                  router.pushUrl({ url: item.route });
                }
              })
            })
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ left: 16, right: 16, top: 16 })

          // Footer link
          Text('进入帮助中心')
            .fontSize(15)
            .fontColor('#576B95')
            .decoration({ type: TextDecorationType.Underline })
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 32, bottom: 32 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/HelpCenterPage' });
            })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
