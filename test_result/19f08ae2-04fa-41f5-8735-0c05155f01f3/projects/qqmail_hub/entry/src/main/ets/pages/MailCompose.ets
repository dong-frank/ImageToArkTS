import router from '@ohos.router';

@Entry
@Component
struct MailCompose {
  @State recipient: string = ''
  @State subject: string = ''
  @State body: string = '发自我的iPhone'
  @State showCcBcc: boolean = false
  @State ccField: string = ''
  @State bccField: string = ''

  // Send button enabled only when recipient is non-empty
  private get isSendEnabled(): boolean {
    return this.recipient.trim().length > 0
  }

  onCancel() {
    router.back()
  }

  onSend() {
    if (!this.isSendEnabled) {
      return
    }
    // TODO: send email logic (out of scope for this stage)
    router.back()
  }

  build() {
    Column() {
      // --- Navigation Bar ---
      Row() {
        Text('取消')
          .fontSize(17)
          .fontColor('#007AFF')
          .onClick(() => this.onCancel())

        Blank()

        Text('写邮件')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')

        Blank()

        Text('发送')
          .fontSize(17)
          .fontColor(this.isSendEnabled ? '#007AFF' : '#CCCCCC')
          .onClick(() => this.onSend())
          .hitTestBehavior(this.isSendEnabled ? HitTestMode.Default : HitTestMode.None)
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F7F7F7')
      .borderWidth({ bottom: 0.5 })
      .borderColor('#C8C8C8')

      // --- Scrollable Content ---
      Scroll() {
        Column() {
          // --- Form Section ---
          Column() {
            // Recipient row
            Row() {
              Text('收件人:')
                .fontSize(15)
                .fontColor('#000000')
                .width(56)

              TextInput({ text: this.recipient, placeholder: '' })
                .fontSize(15)
                .fontColor('#000000')
                .placeholderColor('#C7C7CC')
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
                .caretColor('#007AFF')
                .defaultFocus(true)
                .onChange((value: string) => {
                  this.recipient = value
                })
            }
            .width('100%')
            .height(44)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)

            Divider()
              .strokeWidth(0.5)
              .color('#E0E0E0')
              .margin({ left: 16 })

            // CC/BCC toggle row
            Row() {
              Text(this.showCcBcc ? '抄送/密送 ▲' : '抄送/密送')
                .fontSize(15)
                .fontColor('#007AFF')
                .onClick(() => {
                  this.showCcBcc = !this.showCcBcc
                })
            }
            .width('100%')
            .height(44)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)

            Divider()
              .strokeWidth(0.5)
              .color('#E0E0E0')
              .margin({ left: 16 })

            // CC field (conditionally shown)
            if (this.showCcBcc) {
              Row() {
                Text('抄送:')
                  .fontSize(15)
                  .fontColor('#000000')
                  .width(56)

                TextInput({ text: this.ccField, placeholder: '' })
                  .fontSize(15)
                  .fontColor('#000000')
                  .placeholderColor('#C7C7CC')
                  .backgroundColor(Color.Transparent)
                  .layoutWeight(1)
                  .onChange((value: string) => {
                    this.ccField = value
                  })
              }
              .width('100%')
              .height(44)
              .padding({ left: 16, right: 16 })
              .alignItems(VerticalAlign.Center)

              Divider()
                .strokeWidth(0.5)
                .color('#E0E0E0')
                .margin({ left: 16 })

              // BCC field
              Row() {
                Text('密送:')
                  .fontSize(15)
                  .fontColor('#000000')
                  .width(56)

                TextInput({ text: this.bccField, placeholder: '' })
                  .fontSize(15)
                  .fontColor('#000000')
                  .placeholderColor('#C7C7CC')
                  .backgroundColor(Color.Transparent)
                  .layoutWeight(1)
                  .onChange((value: string) => {
                    this.bccField = value
                  })
              }
              .width('100%')
              .height(44)
              .padding({ left: 16, right: 16 })
              .alignItems(VerticalAlign.Center)

              Divider()
                .strokeWidth(0.5)
                .color('#E0E0E0')
                .margin({ left: 16 })
            }

            // Sender row (read-only)
            Row() {
              Text('发件人:')
                .fontSize(15)
                .fontColor('#000000')
                .width(56)

              Text('蒋*9434@qq.com')
                .fontSize(15)
                .fontColor('#888888')
                .layoutWeight(1)
            }
            .width('100%')
            .height(44)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)

            Divider()
              .strokeWidth(0.5)
              .color('#E0E0E0')
              .margin({ left: 16 })

            // Subject row
            Row() {
              Text('主题:')
                .fontSize(15)
                .fontColor('#000000')
                .width(56)

              TextInput({ text: this.subject, placeholder: '' })
                .fontSize(15)
                .fontColor('#000000')
                .placeholderColor('#C7C7CC')
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
                .onChange((value: string) => {
                  this.subject = value
                })
            }
            .width('100%')
            .height(44)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
          }
          .backgroundColor('#FFFFFF')
          .margin({ top: 12 })

          // --- Body Area ---
          Column() {
            TextArea({ text: this.body, placeholder: '正文' })
              .fontSize(15)
              .fontColor('#000000')
              .placeholderColor('#C7C7CC')
              .backgroundColor(Color.Transparent)
              .height(240)
              .padding(16)
              .onChange((value: string) => {
                this.body = value
              })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 12 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor('#EFEFF4')

      // --- Bottom Toolbar ---
      Column() {
        Row() {
          // Paperclip icon with red dot
          Stack() {
            Text('\uD83D\uDCCE')
              .fontSize(22)

            // Red dot badge
            Circle({ width: 8, height: 8 })
              .fill('#FF3B30')
              .position({ x: 18, y: -2 })
          }
          .width(44)
          .height(44)
          .alignContent(Alignment.Center)
          .onClick(() => {
            // Open attachment picker (non-navigation, same-page overlay/picker)
          })

          Blank()

          // Envelope icon
          Text('\u2709\uFE0F')
            .fontSize(22)
            .width(44)
            .height(44)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              // Insert template/draft (non-navigation)
            })

          Blank()

          // Clock icon
          Text('\uD83D\uDD52')
            .fontSize(22)
            .width(44)
            .height(44)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              // Open schedule picker (non-navigation, overlay/picker)
            })
        }
        .width('100%')
        .height(44)
        .padding({ left: 24, right: 24 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#F9F9F9')
        .borderWidth({ top: 0.5 })
        .borderColor('#C8C8C8')
      }
      .width('100%')
      .backgroundColor('#F9F9F9')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#EFEFF4')
  }
}
