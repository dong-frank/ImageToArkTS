/**
 * EmailDetailPage - Email reading/detail view
 * Based on: Draft 11 (partial, raw recovery - rich structure)
 */
import router from '@ohos.router';

@Entry
@Component
struct EmailDetailPage {
  @State showTranslate: boolean = true;

  readonly subject: string = 'Introducing GPT-5.5';
  readonly senderName: string = 'OpenAI';
  readonly senderEmail: string = 'noreply@email.openai.com';
  readonly proxyInfo: string = '(由 bounces+54382...ail.openai.com 代发)';
  readonly recipientName: string = '蒋';
  readonly recipientEmail: string = '****434@qq.com';
  readonly timestamp: string = '2026年4月25日 08:21';

  readonly bodyParagraphs: string[] = [
    "We're excited to introduce GPT-5.5, our smartest and most intuitive to use model yet, and the next step toward a new way of getting work done on a computer. GPT-5.5 is now available in the API, Codex, and ChatGPT.",
    "GPT-5.5 understands what you're trying to do faster and can carry more of the work itself. It also uses significantly fewer tokens to complete the same tasks, making it more efficient as well as more capable.",
    "To get the most out of GPT-5.5 in the API, check out our API prompt guide and migration guide, or use the command below to kick off a plan to migrate your API integration via Codex.",
    "GPT-5.5 is now the default model in Codex"
  ];

  readonly actions: string[] = ['删除', '分享', '回复转发', '更多'];
  readonly actionIcons: string[] = ['🗑️', '📤', '↩️', '⋯'];

  handleBackTap(): void {
    router.back();
  }

  handleHideProxy(): void {
    // Placeholder: hide proxy info
  }

  handleTranslate(): void {
    this.showTranslate = false;
  }

  handleDismissTranslate(): void {
    this.showTranslate = false;
  }

  handleReplyForward(): void {
    router.pushUrl({ url: 'pages/ComposeMailPage' });
  }

  build() {
    Stack() {
      Column() {
        // Navigation header with expand/collapse buttons
      Row() {
        Text('<')
          .fontSize(20)
          .fontColor('#4A90D9')
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.handleBackTap(); })

        Blank()

        Text('▲')
          .fontSize(14)
          .fontColor('#888888')
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)

        Text('▼')
          .fontSize(14)
          .fontColor('#888888')
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(44)
      .padding({ left: 4, right: 8 })
      .backgroundColor('#FFFFFF')

      Divider()
        .height(0.5)
        .color('#E8E8E8')

      Scroll() {
        Column() {
          // Email header
          Column() {
            // Subject
            Text(this.subject)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
              .width('100%')
              .padding({ left: 14, right: 14, top: 12 })

            // Sender info
            Column() {
              Row() {
                Text('发件人：')
                  .fontSize(13)
                  .fontColor('#666666')
                  .width(56)
                Column() {
                  Text(this.senderName)
                    .fontSize(14)
                    .fontColor('#333333')
                  Text(this.senderEmail)
                    .fontSize(11)
                    .fontColor('#999999')
                  Text(this.proxyInfo)
                    .fontSize(10)
                    .fontColor('#AAAAAA')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text('隐藏')
                  .fontSize(12)
                  .fontColor('#4A90D9')
                  .onClick(() => { this.handleHideProxy(); })
              }
              .width('100%')

              // Recipient
              Row() {
                Text('收件人：')
                  .fontSize(13)
                  .fontColor('#666666')
                  .width(56)
                Column() {
                  Text(this.recipientName)
                    .fontSize(14)
                    .fontColor('#333333')
                  Text(this.recipientEmail)
                    .fontSize(11)
                    .fontColor('#999999')
                }
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .margin({ top: 8 })

              // Timestamp
              Row() {
                Text('时间：')
                  .fontSize(13)
                  .fontColor('#666666')
                  .width(56)
                Text(this.timestamp)
                  .fontSize(13)
                  .fontColor('#333333')
              }
              .width('100%')
              .margin({ top: 8 })
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 8, bottom: 10 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          Divider()
            .height(6)
            .color('#F5F5F5')

          // Email body
          Column() {
            Text('OpenAI')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
              .width('100%')
              .padding({ left: 14, right: 14, top: 16, bottom: 12 })

            ForEach(this.bodyParagraphs, (para: string, index: number) => {
              Column() {
                Text(para)
                  .fontSize(15)
                  .fontColor('#333333')
                  .lineHeight(22)
                  .width('100%')

                if (index === 2) {
                  // Code snippet
                  Text('[$openai-docs migrate this project to gpt-5.5]')
                    .fontSize(13)
                    .fontColor('#333333')
                    .backgroundColor('#F5F5F5')
                    .borderRadius(4)
                    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
                    .width('100%')
                    .margin({ top: 8, bottom: 8 })
                    .fontFamily('monospace')
                }
              }
              .width('100%')
              .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            })

            // Links
            Row() {
              Text('prompt guide')
                .fontSize(14)
                .fontColor('#4A90D9')
                .decoration({ type: TextDecorationType.Underline })
                .margin({ right: 16 })
              Text('migration guide')
                .fontSize(14)
                .fontColor('#4A90D9')
                .decoration({ type: TextDecorationType.Underline })
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 8 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          Column().height(80)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')

      // Bottom action bar
      Row() {
        ForEach(this.actions, (action: string, index: number) => {
          Column() {
            Text(this.actionIcons[index])
              .fontSize(20)
            Text(action)
              .fontSize(11)
              .fontColor('#666666')
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            if (action === '回复转发') {
              this.handleReplyForward();
            }
          })
        })
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      .backgroundColor('#FAFAFA')
      .border({ width: { top: 0.5 }, color: '#E8E8E8' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')

    // Floating translate badge
    if (this.showTranslate) {
      Row() {
        Text('翻译邮件')
          .fontSize(12)
          .fontColor('#4A90D9')
          .margin({ right: 4 })
        Text('×')
          .fontSize(14)
          .fontColor('#999999')
          .onClick(() => { this.handleDismissTranslate(); })
      }
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 4, color: '#00000020', offsetX: 0, offsetY: 2 })
      .onClick(() => { this.handleTranslate(); })
      .position({ x: '60%', y: '85%' })
    }
    }
  }
}
