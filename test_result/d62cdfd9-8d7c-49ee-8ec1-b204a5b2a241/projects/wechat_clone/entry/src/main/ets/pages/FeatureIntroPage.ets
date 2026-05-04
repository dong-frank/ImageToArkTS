import { router } from '@kit.ArkUI';

interface FeatureCardData {
  icon: string;
  title: string;
  description: string;
  bgColor: string;
}

@Entry
@Component
struct FeatureIntroPage {
  private featureCards: FeatureCardData[] = [
    {
      icon: '\uE101',
      title: '微信电话',
      description: '高清稳定的音视频通话；国际长途电话更省心。',
      bgColor: '#07C160'
    },
    {
      icon: '\uE102',
      title: '语音文字消息',
      description: '快捷发送语音或文字消息；用有趣的表情和动画丰富聊天体验。',
      bgColor: '#07C160'
    },
    {
      icon: '\uE103',
      title: '朋友圈',
      description: '与朋友轻松分享生活点滴，记录珍贵时刻。',
      bgColor: '#07C160'
    },
    {
      icon: '\uE104',
      title: '隐私安全',
      description: '多重安全保护，确保您的个人信息和聊天内容安全。',
      bgColor: '#07C160'
    }
  ];

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('\uE900')
          .fontSize(20)
          .fontColor('#191919')
          .width(24)
          .height(24)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.back();
          })

        Text('功能介绍')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#191919')
          .textAlign(TextAlign.Center)
          .flexGrow(1)

        // Placeholder to balance the back button width
        Row()
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#EDEDED')

      // Scrollable content
      Scroll() {
        Column({ space: 16 }) {
          // Top spacing
          Row()
            .height(8)

          // Feature cards
          ForEach(this.featureCards, (card: FeatureCardData, index: number) => {
            this.FeatureCardItem(card)
          })

          // Spacing before buttons
          Row()
            .height(16)

          // Bottom action buttons
          Button('了解更多')
            .width('80%')
            .height(44)
            .fontSize(16)
            .fontColor('#07C160')
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: '#07C160', style: BorderStyle.Solid })
            .borderRadius(6)
            .onClick(() => {
              // Navigate to help/webview page - currently placeholder
              console.info('了解更多 tapped');
            })

          Button('意见反馈')
            .fontSize(14)
            .fontColor('#888888')
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              // Open feedback form - currently placeholder
              console.info('意见反馈 tapped');
            })

          // Bottom spacing
          Row()
            .height(24)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
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
  FeatureCardItem(card: FeatureCardData) {
    Column({ space: 10 }) {
      // Icon area
      Text(card.icon)
        .fontSize(40)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width(56)
        .height(56)

      // Title
      Text(card.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .maxLines(1)
        .textAlign(TextAlign.Center)

      // Description
      Text(card.description)
        .fontSize(13)
        .fontColor('#E8F5E9')
        .maxLines(3)
        .textAlign(TextAlign.Center)
        .lineHeight(20)
        .padding({ left: 16, right: 16 })
    }
    .width('90%')
    .padding({ top: 32, bottom: 32, left: 16, right: 16 })
    .backgroundColor(card.bgColor)
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
