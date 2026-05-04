import router from '@ohos.router';

@Entry
@Component
struct ThirdPartySharePage {

  thirdPartyList: ShareItem[] = [
    {
      name: '微信支付',
      purpose: '支付服务',
      dataType: '设备标识符、交易金额、商品信息',
      privacyUrl: 'https://weixin.qq.com/privacy'
    },
    {
      name: '支付宝',
      purpose: '支付服务',
      dataType: '设备标识符、交易金额、交易流水号',
      privacyUrl: 'https://www.alipay.com/privacy'
    },
    {
      name: '极光推送',
      purpose: '消息推送',
      dataType: '设备标识符、应用列表、推送令牌',
      privacyUrl: 'https://www.jiguang.cn/privacy'
    },
    {
      name: '友盟统计',
      purpose: '数据分析',
      dataType: '设备信息、使用行为数据、页面浏览记录',
      privacyUrl: 'https://www.umeng.com/privacy'
    },
    {
      name: '华为移动服务',
      purpose: '推送服务 / 账号登录',
      dataType: '设备标识符、账号信息、网络状态',
      privacyUrl: 'https://developer.huawei.com/privacy'
    },
    {
      name: 'Bugly',
      purpose: '崩溃监控',
      dataType: '设备信息、应用版本、崩溃日志',
      privacyUrl: 'https://bugly.qq.com/privacy'
    },
  ];

  build() {
    Column() {
      // Status bar
      Row() {
        Text('15:17')
          .fontSize(12)
          .fontColor('#333333')
        Blank()
        Text('56%')
          .fontSize(12)
          .fontColor('#333333')
      }
      .width('100%')
      .height(28)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F5F5F5')

      // Navigation bar
      Row() {
        Text('<')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ right: 12 })
          .onClick(() => {
            router.back();
          })
        Text('第三方信息共享清单')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // Description card
          Column() {
            Text('说明')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 10 })

            Text('为保障知乎 App 相关功能的实现和应用的安全稳定运行，我们会接入由第三方提供的软件开发包（SDK）以实现相关目的。以下列出知乎 App 接入的第三方 SDK 及其信息处理情况。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 8 })

            Text('我们会对第三方 SDK 进行严格的安全检测，并与第三方约定严格的数据保护措施，要求其按照本指引及法律法规的要求处理个人信息。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Third party list
          ForEach(this.thirdPartyList, (item: ShareItem) => {
            Column() {
              Row() {
                Text(item.name)
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                  .layoutWeight(1)
                Text('>')
                  .fontSize(14)
                  .fontColor('#CCCCCC')
              }
              .width('100%')
              .margin({ bottom: 10 })

              this.InfoRow('用途', item.purpose)
              this.InfoRow('数据类型', item.dataType)

              Text('查看隐私政策')
                .fontSize(12)
                .fontColor('#0066FF')
                .margin({ top: 4 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ top: 8 })
          })

          // Footer info
          Column() {
            Text('更新日期：2025 年 1 月 1 日')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 16, bottom: 24 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(12)
        .fontColor('#999999')
        .width(70)
      Text(value)
        .fontSize(12)
        .fontColor('#666666')
        .layoutWeight(1)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .margin({ bottom: 4 })
  }
}

interface ShareItem {
  name: string;
  purpose: string;
  dataType: string;
  privacyUrl: string;
}
