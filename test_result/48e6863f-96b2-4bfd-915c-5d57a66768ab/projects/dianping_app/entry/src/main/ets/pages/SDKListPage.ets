import router from '@ohos.router';

class SDKItem {
  company: string;
  sdkName: string;
  personalInfo: string;
  purpose: string;
  shareMethod: string;
  link: string;

  constructor(
    company: string,
    sdkName: string,
    personalInfo: string,
    purpose: string,
    shareMethod: string,
    link: string
  ) {
    this.company = company;
    this.sdkName = sdkName;
    this.personalInfo = personalInfo;
    this.purpose = purpose;
    this.shareMethod = shareMethod;
    this.link = link;
  }
}

@Entry
@Component
struct SDKListPage {
  private sdkList: SDKItem[] = [
    new SDKItem(
      '中移互联网有限公司',
      '号码认证SDK',
      '网络类型、网络地址（ip地址）、运营商类型、本机号码信息、SIM卡状态、手机设备类型、手机操作系统、硬件厂商',
      '根据用户选择，为用户提供一键登录功能',
      'SDK本机采集',
      'https://www.cmpassport.com/'
    ),
    new SDKItem(
      '腾讯科技（深圳）有限公司',
      '微信OpenSDK',
      '设备标识信息、网络信息',
      '用于微信登录、分享、支付功能',
      'SDK本机采集',
      'https://open.weixin.qq.com/'
    ),
    new SDKItem(
      '高德软件有限公司',
      '高德地图SDK',
      '位置信息、设备标识信息、网络信息',
      '用于地图展示、定位、导航功能',
      'SDK本机采集',
      'https://lbs.amap.com/'
    ),
  ];

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
        Text('第三方SDK清单')
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
          // Title
          Text('大众点评App内嵌SDK名单')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')
            .padding({ left: 16, right: 16, top: 20, bottom: 12 })

          // Description paragraph
          Text('为保障大众点评App相关功能的实现与应用的稳定运行，我们可能会接入由第三方提供的软件开发包（SDK）以实现相关目的。不同设备系统（如IOS、Android、HarmonyOS等）的第三方SDK会有所不同，一般包括一键登录类、第三方账号登录类、推送通知消息类、第三方支付类、地图导航类、厂商推送类、分享类、统计类等。我们会对合作方获取信息的软件工具开发包（SDK）进行严格的安全监测，以保障数据安全。您可以通过以下链接查看第三方的数据使用和保护规则。')
            .fontSize(13)
            .fontColor('#666666')
            .lineHeight(20)
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 20 })

          // SDK list
          ForEach(this.sdkList, (item: SDKItem, index: number) => {
            Column() {
              this.SDKCard(item)
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ left: 12, right: 12, bottom: 12 })
          })

          // Footer
          Text('以上为部分SDK清单，完整列表请查看官网')
            .fontSize(12)
            .fontColor('#CCCCCC')
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 8, bottom: 40 })
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
  SDKCard(item: SDKItem) {
    Column() {
      this.SDKInfoRow('第三方公司', item.company)
      this.SDKInfoRow('SDK名称', item.sdkName)
      this.SDKInfoRow('涉及个人信息', item.personalInfo)
      this.SDKInfoRow('使用目的', item.purpose)
      this.SDKInfoRow('共享方式', item.shareMethod)
      this.SDKInfoRow('第三方链接', item.link)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }

  @Builder
  SDKInfoRow(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ bottom: 4 })
      Text(value)
        .fontSize(13)
        .fontColor('#333333')
        .margin({ bottom: 10 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
