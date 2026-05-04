import router from '@ohos.router';

// --- Data Models ---

interface MessageSender {
  avatar: string;
  name: string;
  avatarColor: string;
}

interface MessageCardData {
  sender: MessageSender;
  timestamp: string;
  title: string;
  body: string;
  cta: string;
}

// --- Mock Data ---

const MOCK_MESSAGES: MessageCardData[] = [
  {
    sender: { avatar: '🦊', name: '点小二', avatarColor: '#FF8C42' },
    timestamp: '14:44',
    title: '重要提醒！您已进入本期春日好礼抽取名单 >>',
    body: '官方检测到您尚未领取本期春日好礼，现金红包、0探礼盒、青团花茶、野餐垫、露营椅等惊喜待确认，点击立即领取 >>',
    cta: '点击参与'
  },
  {
    sender: { avatar: '🐼', name: '大众评审', avatarColor: '#E84040' },
    timestamp: '09:52',
    title: '快来看看！您入选了！>>',
    body: '您已入选「大众评审官」候选人，热门争议案件、内部讨论区、限定称号都在等您，快来开启专属体验～',
    cta: '查看详情'
  },
  {
    sender: { avatar: '🐼', name: '大众评审', avatarColor: '#E84040' },
    timestamp: '04/26',
    title: '限定掉落！「大众评审官」资格>>',
    body: '您的账号触发「大众评审官」解锁条件，热门争议案件、内部讨论区、限定称号都在等您，快来开启专属体验～',
    cta: '查看详情'
  },
  {
    sender: { avatar: '🦊', name: '点小二', avatarColor: '#FF8C42' },
    timestamp: '04/25',
    title: '您的春日礼包领取流程中断，需要本人处理 >>',
    body: '您的春日限定礼包（露营椅/野餐垫/青团花茶/现金红包）领取机会将于近日到期，点击立即处理 >>',
    cta: '点击参与'
  },
  {
    sender: { avatar: '🦊', name: '点小二', avatarColor: '#FF8C42' },
    timestamp: '04/21',
    title: '重要提醒！您已进入本期春日好礼抽取名单 >>',
    body: '',
    cta: ''
  }
];

// --- Constants ---

const NAV_BAR_HEIGHT = 56;
const AVATAR_SIZE = 44;
const CARD_PADDING = 16;
const CARD_RADIUS = 12;

@Entry
@Component
struct ActivityMessages {
  @State showMoreMenu: boolean = false;

  build() {
    Stack() {
      Column() {
        // --- Navigation Bar ---
        Row() {
          // Back button
          Text('←')
            .fontSize(22)
            .fontColor('#333333')
            .width(44)
            .height(44)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              router.back();
            })

          Blank()

          // Title
          Text('活动消息')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')

          Blank()

          // More button
          Text('⋯')
            .fontSize(22)
            .fontColor('#333333')
            .width(44)
            .height(44)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.showMoreMenu = !this.showMoreMenu;
            })
        }
        .width('100%')
        .height(NAV_BAR_HEIGHT)
        .padding({ left: 8, right: 8 })
        .backgroundColor('#FFFFFF')
        .borderWidth({ bottom: 0.5 })
        .borderColor('#E5E5E5')

        // --- Message List ---
        Scroll() {
          Column({ space: 12 }) {
            ForEach(MOCK_MESSAGES, (msg: MessageCardData, index: number) => {
              Column() {
                // Sender row: avatar + name + timestamp
                Row() {
                  // Avatar
                  Text(msg.sender.avatar)
                    .fontSize(24)
                    .width(AVATAR_SIZE)
                    .height(AVATAR_SIZE)
                    .borderRadius(AVATAR_SIZE / 2)
                    .backgroundColor(msg.sender.avatarColor)
                    .textAlign(TextAlign.Center)

                  // Name
                  Text(msg.sender.name)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#1A1A1A')
                    .margin({ left: 10 })

                  Blank()

                  // Timestamp
                  Text(msg.timestamp)
                    .fontSize(12)
                    .fontColor('#999999')
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)

                // Title
                Text(msg.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1A1A1A')
                  .lineHeight(22)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 10 })
                  .width('100%')

                // Body (if present)
                if (msg.body.length > 0) {
                  Text(msg.body)
                    .fontSize(14)
                    .fontColor('#666666')
                    .lineHeight(20)
                    .maxLines(3)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 6 })
                    .width('100%')
                }

                // CTA link (if present)
                if (msg.cta.length > 0) {
                  Text(msg.cta)
                    .fontSize(14)
                    .fontColor('#007AFF')
                    .margin({ top: 8 })
                    .onClick(() => {
                      // CTA targets (春日好礼活动页/大众评审官详情页) are unresolved
                      console.info(`[ActivityMessages] CTA tapped: ${msg.cta} from ${msg.sender.name}`);
                    })
                }
              }
              .width('100%')
              .padding(CARD_PADDING)
              .backgroundColor('#FFFFFF')
              .borderRadius(CARD_RADIUS)
              .onClick(() => {
                // Message card tap target (消息详情/活动页) is unresolved
                console.info(`[ActivityMessages] Card tapped: ${msg.title} from ${msg.sender.name}`);
              })
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // --- More Menu Overlay ---
      if (this.showMoreMenu) {
        Column() {
          Column() {
            Text('全部已读')
              .fontSize(15)
              .fontColor('#333333')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .width('100%')
              .onClick(() => {
                this.showMoreMenu = false;
                console.info('[ActivityMessages] 全部已读 tapped');
              })

            Divider()
              .strokeWidth(0.5)
              .color('#E5E5E5')

            Text('筛选')
              .fontSize(15)
              .fontColor('#333333')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .width('100%')
              .onClick(() => {
                this.showMoreMenu = false;
                console.info('[ActivityMessages] 筛选 tapped');
              })

            Divider()
              .strokeWidth(0.5)
              .color('#E5E5E5')

            Text('设置')
              .fontSize(15)
              .fontColor('#333333')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .width('100%')
              .onClick(() => {
                this.showMoreMenu = false;
                console.info('[ActivityMessages] 设置 tapped');
              })
          }
          .width(140)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .shadow({ radius: 8, color: '#00000020', offsetX: 0, offsetY: 2 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.End)
        .padding({ top: NAV_BAR_HEIGHT + 4, right: 8 })
        .onClick(() => {
          this.showMoreMenu = false;
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
