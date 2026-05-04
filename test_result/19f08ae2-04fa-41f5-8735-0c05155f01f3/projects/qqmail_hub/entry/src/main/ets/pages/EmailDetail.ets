import router from '@ohos.router';

// --- Data types ---

interface EmailHeaderData {
  subject: string
  senderName: string
  senderEmail: string
  senderProxy: string
  recipientName: string
  recipientEmail: string
  timestamp: string
}

@Component
struct EmailHeaderSection {
  @Prop headerData: EmailHeaderData
  @State headerExpanded: boolean = true

  build() {
    Column({ space: 0 }) {
      // Subject line
      Text(this.headerData.subject)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 4 })

      if (this.headerExpanded) {
        // Sender info
        Row() {
          Text('发件人：')
            .fontSize(14)
            .fontColor('#888888')
          Text(this.headerData.senderName)
            .fontSize(14)
            .fontColor('#333333')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 2, bottom: 1 })

        Text(this.headerData.senderEmail)
          .fontSize(13)
          .fontColor('#888888')
          .width('100%')
          .padding({ left: 16, right: 16, top: 1, bottom: 1 })

        Text(this.headerData.senderProxy)
          .fontSize(12)
          .fontColor('#AAAAAA')
          .width('100%')
          .padding({ left: 16, right: 16, top: 1, bottom: 1 })

        // Recipient info
        Row() {
          Text('收件人：')
            .fontSize(14)
            .fontColor('#888888')
          Text(this.headerData.recipientName)
            .fontSize(14)
            .fontColor('#333333')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 1 })

        Text(this.headerData.recipientEmail)
          .fontSize(13)
          .fontColor('#888888')
          .width('100%')
          .padding({ left: 16, right: 16, top: 1, bottom: 1 })

        // Timestamp
        Text(this.headerData.timestamp)
          .fontSize(13)
          .fontColor('#888888')
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 4 })
      }

      // Hide / Show toggle
      Row() {
        Blank()
        Text(this.headerExpanded ? '隐藏' : '显示详情')
          .fontSize(13)
          .fontColor('#2B7BD6')
          .padding({ left: 8, right: 16, top: 4, bottom: 8 })
          .onClick(() => {
            this.headerExpanded = !this.headerExpanded
          })
      }
      .width('100%')

      // Divider line
      Divider()
        .color('#E5E5E5')
        .width('100%')
        .strokeWidth(0.5)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}

@Entry
@Component
struct EmailDetail {
  // --- Navigation stubs ---
  // back → returns to pages/EmailInbox

  goBack() {
    router.back()
  }

  // --- Header data ---
  @State headerData: EmailHeaderData = {
    subject: 'Introducing GPT-5.5',
    senderName: 'OpenAI',
    senderEmail: 'noreply@email.openai.com',
    senderProxy: '(由 bounces+54382...ail.openai.com 代发)',
    recipientName: '蒋',
    recipientEmail: '****434@qq.com',
    timestamp: '时间：2026年4月25日 08:21'
  }

  // --- Translation overlay state ---
  @State showTranslationOverlay: boolean = false

  @Builder
  buildNavBar() {
    Row() {
      Text('<')
        .fontSize(24)
        .fontColor('#333333')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .onClick(() => {
          this.goBack()
        })

      Blank()

      Text('邮件详情')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A1A')

      Blank()

      // Placeholder to balance the back arrow
      Text('  ')
        .fontSize(24)
        .padding({ left: 8, right: 8 })
    }
    .width('100%')
    .height(48)
    .backgroundColor('#FFFFFF')
    .padding({ left: 4, right: 4 })
  }

  @Builder
  buildEmailBody() {
    Column({ space: 12 }) {
      // OpenAI brand logo
      Column() {
        Text('OpenAI')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 24, bottom: 16 })

      // Paragraph 1
      Text("We're excited to introduce GPT-5.5, our smartest and most intuitive to use model yet. GPT-5.5 delivers significant improvements across reasoning, coding, vision, tool use, and instruction following — all while being faster and more efficient than previous models.")
        .fontSize(15)
        .fontColor('#333333')
        .lineHeight(24)
        .width('100%')
        .padding({ left: 16, right: 16 })

      // Paragraph 2
      Text("GPT-5.5 understands what you're trying to do faster, follows complex instructions with greater precision, and produces more reliable structured outputs. It excels at multi-step reasoning, code generation, and analysis across large contexts.")
        .fontSize(15)
        .fontColor('#333333')
        .lineHeight(24)
        .width('100%')
        .padding({ left: 16, right: 16 })

      // Paragraph 3 (rich: text + hyperlinks + code block)
      Column({ space: 0 }) {
        Row() {
          Text('To get the most out of GPT-5.5 in the API, check out our API ')
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(24)
          Text('prompt guide')
            .fontSize(15)
            .fontColor('#2B7BD6')
            .lineHeight(24)
            .decoration({ type: TextDecorationType.Underline })
            .onClick(() => {
              // open_url → external browser, not app navigation
            })
          Text(' and ')
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(24)
          Text('migration guide')
            .fontSize(15)
            .fontColor('#2B7BD6')
            .lineHeight(24)
            .decoration({ type: TextDecorationType.Underline })
            .onClick(() => {
              // open_url → external browser, not app navigation
            })
          Text(', or use the command: ')
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(24)
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        // Code block
        Text('[$openai-docs migrate this project to gpt-5.5]')
          .fontSize(13)
          .fontColor('#333333')
          .fontFamily('monospace')
          .backgroundColor('#F5F5F5')
          .borderRadius(6)
          .padding(12)
          .width('100%')
          .margin({ top: 12, left: 16, right: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // Paragraph 4
      Text('GPT-5.5 is now the default model in Codex, ChatGPT, and the API. All paid users can access GPT-5.5 starting today, with free tier access rolling out over the coming weeks.')
        .fontSize(15)
        .fontColor('#333333')
        .lineHeight(24)
        .width('100%')
        .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .padding({ bottom: 80 })
  }

  @Builder
  buildTranslateButton() {
    Button() {
      Row({ space: 6 }) {
        Text('🌐')
          .fontSize(16)
        Text('翻译邮件')
          .fontSize(14)
          .fontColor('#FFFFFF')
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    }
    .backgroundColor('#34C759')
    .borderRadius(20)
    .onClick(() => {
      this.showTranslationOverlay = !this.showTranslationOverlay
    })
    .position({ right: 16, bottom: 80 })
    .shadow({
      radius: 8,
      color: '#34000000',
      offsetY: 2
    })
  }

  @Builder
  buildBottomActionBar() {
    Row() {
      // Delete
      Column({ space: 2 }) {
        Text('🗑️')
          .fontSize(20)
        Text('删除')
          .fontSize(11)
          .fontColor('#666666')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        // delete_mail → delete email, may pop back to list
        router.back()
      })

      // Share
      Column({ space: 2 }) {
        Text('📤')
          .fontSize(20)
        Text('分享')
          .fontSize(11)
          .fontColor('#666666')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        // share_mail → system share sheet
      })

      // Reply / Forward
      Column({ space: 2 }) {
        Text('↩️')
          .fontSize(20)
        Text('回复转发')
          .fontSize(11)
          .fontColor('#666666')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        // reply_forward → action sheet / reply options (not navigation per unresolved hints)
      })

      // More
      Column({ space: 2 }) {
        Text('⋯')
          .fontSize(20)
          .fontColor('#333333')
        Text('更多')
          .fontSize(11)
          .fontColor('#666666')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        // more_actions → open action menu overlay (non-navigation)
      })
    }
    .width('100%')
    .height(56)
    .backgroundColor('#FAFAFA')
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .border({ width: { top: 0.5 }, color: '#E5E5E5' })
  }

  @Builder
  buildTranslationOverlay() {
    Column() {
      // Overlay header
      Row() {
        Text('翻译结果')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')

        Blank()

        Text('✕')
          .fontSize(18)
          .fontColor('#666666')
          .padding(8)
          .onClick(() => {
            this.showTranslationOverlay = false
          })
      }
      .width('100%')
      .padding({ left: 16, right: 8, top: 12, bottom: 8 })

      Divider()
        .color('#E5E5E5')
        .strokeWidth(0.5)

      // Translated content
      Scroll() {
        Column({ space: 12 }) {
          Text('我们很高兴推出 GPT-5.5，这是迄今为止我们最智能、最直观的模型。GPT-5.5 在推理、编码、视觉、工具使用和指令遵循方面提供了显著改进，同时比之前的模型更快、更高效。')
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(24)
            .width('100%')

          Text('GPT-5.5 能更快地理解您的意图，更精确地遵循复杂指令，并生成更可靠的结构化输出。它擅长多步推理、代码生成和大上下文分析。')
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(24)
            .width('100%')

          Text('GPT-5.5 现在是 Codex、ChatGPT 和 API 中的默认模型。所有付费用户即日起均可使用 GPT-5.5，免费层级访问将在未来几周内逐步推出。')
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(24)
            .width('100%')
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('70%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
    .shadow({ radius: 16, color: '#20000000', offsetY: -4 })
  }

  build() {
    Stack() {
      Column() {
        // Navigation bar
        this.buildNavBar()

        // Scrollable content area
        Scroll() {
          Column({ space: 0 }) {
            // Email header section
            EmailHeaderSection({ headerData: this.headerData })

            // Email body content
            this.buildEmailBody()
          }
          .width('100%')
        }
        .layoutWeight(1)
        .backgroundColor('#F8F8F8')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        // Fixed bottom action bar
        this.buildBottomActionBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F8F8')

      // Floating translate button (positioned absolute within Stack)
      this.buildTranslateButton()

      // Translation overlay backdrop + bottom sheet
      if (this.showTranslationOverlay) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#60000000')
          .onClick(() => {
            this.showTranslationOverlay = false
          })

        Column() {
          Blank()
          this.buildTranslationOverlay()
        }
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.None)
      }
    }
    .width('100%')
    .height('100%')
  }
}
