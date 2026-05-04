import router from '@ohos.router';

@Entry
@Component
struct QuestionDetailPage {
  @State questionTitle: string = '无大算力时，作为学生，LLM 还有哪些值得做的研究？';
  @State questionMeta: string = '知乎 · 62 个回答 · 1302 个关注';
  @State authorName: string = 'Cv大法代码酱';
  @State authorIntro: string = '被所有人都认同的文字，称不上…';
  @State following: boolean = false;
  @State upvotes: string = '3424';
  @State stars: string = '5917';
  @State comments: string = '95';
  @State listeners: string = '13';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      if (params['title']) {
        this.questionTitle = params['title'];
      }
      if (params['author']) {
        this.authorName = params['author'];
      }
    }
  }

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
          .fontSize(20)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })
        Blank()
        Text('邀请回答')
          .fontSize(13)
          .fontColor('#0066FF')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .border({ width: 1, color: '#0066FF', radius: 14 })
          .margin({ right: 8 })
        Text('写回答')
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor('#0066FF')
          .borderRadius(14)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .margin({ right: 8 })
        Text('\u{1F50D}')
          .fontSize(20)
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Scrollable content
      Scroll() {
        Column() {
          // Question header
          Column() {
            Text(this.questionTitle)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
              .width('100%')
              .lineHeight(26)
            Text(this.questionMeta)
              .fontSize(13)
              .fontColor('#999999')
              .margin({ top: 8 })
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 6 })

          // Answer card
          Column() {
            // Author section
            Row() {
              Text('\u{1F464}')
                .fontSize(28)
                .width(40)
                .height(40)
                .borderRadius(20)
                .backgroundColor('#E0E0E0')
                .textAlign(TextAlign.Center)
              Column() {
                Row() {
                  Text(this.authorName)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')
                  Text('\u{2714}')
                    .fontSize(14)
                    .fontColor('#0066FF')
                    .margin({ left: 4 })
                }
                Text(this.authorIntro)
                  .fontSize(12)
                  .fontColor('#999999')
                  .margin({ top: 2 })
              }
              .margin({ left: 10 })
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text(this.following ? '已关注' : '+ 关注')
                .fontSize(13)
                .fontColor(this.following ? '#999999' : '#0066FF')
                .border({ width: 1, color: this.following ? '#CCCCCC' : '#0066FF', radius: 14 })
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .onClick(() => {
                  this.following = !this.following;
                })
            }
            .width('100%')

            // Answer stats
            Row() {
              Text(this.upvotes + ' 人赞同了该回答')
                .fontSize(13)
                .fontColor('#666666')
              Blank()
              Text('\u{1F50A} ' + this.listeners + ' 人听过')
                .fontSize(12)
                .fontColor('#999999')
            }
            .width('100%')
            .margin({ top: 12 })
            .padding({ top: 10, bottom: 10 })
            .border({ width: { top: 0.5, bottom: 0.5 }, color: '#F0F0F0' })

            // Answer body
            Column() {
              Text('看到你说研0非LLM相关，手里没大算力，又觉得RAG和Agent偏工程没什么可研究的，我仿佛看到了五六年前那一波做CV的学生，也是对着ImageNet的大模型望洋兴叹。但其实，咱们得把思路打开，算力贫民窟里也能炼出金子，而且往往这地方出来的东西，比堆算力更有思考深度。')
                .fontSize(15)
                .fontColor('#333333')
                .lineHeight(24)
                .width('100%')

              Text('我们要先打破一个巨大的误区，就是觉得只有预训练Pre-training才叫研究，只有跑得动70B甚至更大的模型才叫搞LLM。这个观点在大厂里盛行，是因为他们有卡，他们有资本去烧。但作为学术界，尤其是作为一个独立的研究者，拼算力你永远拼不过OpenAI和Google，这就像你非要跟法拉利比谁跑直线跑得快，必输无疑。我们得比过弯，比技巧，比对原理的理解。')
                .fontSize(15)
                .fontColor('#333333')
                .lineHeight(24)
                .width('100%')
                .margin({ top: 12 })

              Row() {
                Text('\u{2228}')
                  .fontSize(18)
                  .fontColor('#0066FF')
                Text('展开全文')
                  .fontSize(13)
                  .fontColor('#0066FF')
                  .margin({ left: 4 })
              }
              .width('100%')
              .margin({ top: 8 })
              .onClick(() => {
                // Expand full answer
              })
            }
            .width('100%')
            .margin({ top: 12 })

            // Answer footer
            Row() {
              Text('\u{1F464}')
                .fontSize(24)
                .width(32)
                .height(32)
                .borderRadius(16)
                .backgroundColor('#E0E0E0')
                .textAlign(TextAlign.Center)
              Text('Cv…')
                .fontSize(13)
                .fontColor('#333333')
                .margin({ left: 8 })
              Text('+关注')
                .fontSize(12)
                .fontColor('#0066FF')
                .margin({ left: 8 })
              Blank()
              Row() {
                Text('\u{25B2}')
                  .fontSize(18)
                  .fontColor('#666666')
                Text(this.upvotes)
                  .fontSize(13)
                  .fontColor('#666666')
                  .margin({ left: 2 })
              }
              .margin({ right: 14 })
              Row() {
                Text('\u{2B50}')
                  .fontSize(18)
                  .fontColor('#FFD700')
                Text(this.stars)
                  .fontSize(13)
                  .fontColor('#666666')
                  .margin({ left: 2 })
              }
              .margin({ right: 14 })
              Row() {
                Text('\u{1F4AC}')
                  .fontSize(18)
                  .fontColor('#666666')
                Text(this.comments)
                  .fontSize(13)
                  .fontColor('#666666')
                  .margin({ left: 2 })
              }
              .margin({ right: 8 })
              Text('\u{22EE}')
                .fontSize(20)
                .fontColor('#666666')
            }
            .width('100%')
            .margin({ top: 14 })
            .padding({ top: 10 })
            .border({ width: { top: 0.5 }, color: '#F0F0F0' })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 6 })
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
}
