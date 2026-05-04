import { router } from '@kit.ArkUI';

@Entry
@Component
struct MinorModeOnboardingPage {
  @State isAgreementChecked: boolean = false;

  build() {
    Column() {
      // 顶部导航栏：返回箭头
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#1a1a1a')
          .padding({ left: 16, top: 12, bottom: 8 })
          .onClick(() => {
            router.back();
          })
        Blank()
      }
      .width('100%')

      // 可滚动内容区
      Scroll() {
        Column({ space: 0 }) {
          // 插图区域 - 圆形灰底插画占位
          Column() {
            Text('🐶')
              .fontSize(64)
          }
          .width(120)
          .height(120)
          .borderRadius(60)
          .backgroundColor('#F0F0F0')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 20, bottom: 8 })

          // 页面标题
          Text('未成年人模式')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1a1a1a')
            .margin({ top: 16, bottom: 8 })
            .width('100%')
            .textAlign(TextAlign.Center)

          // 规则说明列表 - 4项
          Column({ space: 14 }) {
            RuleItem({
              index: '1',
              text: '我们为您推荐了教育类和知识类的内容，并对不适宜未成年人的内容进行过滤。'
            })
            RuleItem({
              index: '2',
              text: '无法使用直播、打赏、充值等功能。'
            })
            RuleItem({
              index: '3',
              text: '每天使用时长累计不得超过 40 分钟，晚上 10 点至早上 6 点无法使用知乎。'
            })
            RuleItem({
              index: '4',
              text: '未成年人模式是知乎为未成年人健康成长做出的一次尝试，我们将优先在主场景进行优化，后续会致力于优化更多场景。'
            })
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
          .margin({ top: 16, bottom: 24 })

          // CTA 按钮
          Button('开启未成年人模式')
            .width('100%')
            .height(46)
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor(this.isAgreementChecked ? '#0066FF' : '#B0C4DE')
            .borderRadius(23)
            .enabled(this.isAgreementChecked)
            .padding({ left: 20, right: 20 })
            .onClick(() => {
              if (this.isAgreementChecked) {
                // 开启未成年人模式
                console.info('Minor mode enabled');
              }
            })

          // 协议勾选区域
          Row() {
            Checkbox()
              .select(this.isAgreementChecked)
              .selectedColor('#0066FF')
              .onChange((value: boolean) => {
                this.isAgreementChecked = value;
              })

            Text() {
              Span('我已阅读并同意遵守')
                .fontSize(13)
                .fontColor('#666666')
              Span('《知乎儿童隐私保护政策》')
                .fontSize(13)
                .fontColor('#0066FF')
                .onClick(() => {
                  console.info('Open privacy policy');
                })
            }
            .margin({ left: 6 })
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
          .margin({ top: 16 })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}

@Component
struct RuleItem {
  @Prop index: string = '';
  @Prop text: string = '';

  build() {
    Row() {
      Text(this.index + '.')
        .fontSize(14)
        .fontColor('#8a8a8a')
        .width(24)
        .textAlign(TextAlign.Center)

      Text(this.text)
        .fontSize(14)
        .fontColor('#3a3a3a')
        .lineHeight(22)
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }
}

export default MinorModeOnboardingPage;
