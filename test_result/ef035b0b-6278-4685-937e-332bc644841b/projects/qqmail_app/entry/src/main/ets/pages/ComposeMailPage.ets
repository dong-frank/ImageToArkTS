/**
 * ComposeMailPage - Write a new email
 * Based on: Draft 5 (success)
 */
import router from '@ohos.router';

@Entry
@Component
struct ComposeMailPage {
  @State recipient: string = '';
  @State subject: string = '';
  @State body: string = '发自我的iPhone';

  readonly senderName: string = '蒋';
  readonly senderEmail: string = '9434@qq.com';
  @State canSend: boolean = false;

  handleCancel(): void {
    router.back();
  }

  handleSend(): void {
    // Placeholder: would send the email
  }

  build() {
    Column() {
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor('#4A90D9')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .onClick(() => { this.handleCancel(); })

        Text('写邮件')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('发送')
          .fontSize(16)
          .fontColor(this.canSend ? '#4A90D9' : '#B0B0B0')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .onClick(() => { this.handleSend(); })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .padding({ top: 4 })

      Divider().height(0.5).color('#E8E8E8')

      Row() {
        Text('收件人:')
          .fontSize(15).fontColor('#333333').width(60)
        TextInput({ placeholder: '' })
          .fontSize(15).layoutWeight(1).backgroundColor('#00000000').borderRadius(0)
        Text('抄送/密送')
          .fontSize(13).fontColor('#4A90D9').margin({ right: 6 })
        Text('+')
          .fontSize(18).fontColor('#4A90D9').width(24).height(24).textAlign(TextAlign.Center)
      }
      .width('100%').padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      Divider().height(0.5).color('#F0F0F0').margin({ left: 14 })

      Row() {
        Text('发件人:').fontSize(15).fontColor('#333333').width(60)
        Text(`${this.senderName} <${this.senderEmail}>`)
          .fontSize(14).fontColor('#666666').layoutWeight(1)
      }
      .width('100%').padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      Divider().height(0.5).color('#F0F0F0').margin({ left: 14 })

      Row() {
        Text('主题:').fontSize(15).fontColor('#333333').width(60)
        TextInput({ placeholder: '' })
          .fontSize(15).layoutWeight(1).backgroundColor('#00000000').borderRadius(0)
          .onChange((value: string) => { this.subject = value; })
      }
      .width('100%').padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      Divider().height(6).color('#F5F5F5')

      Scroll() {
        TextArea({ text: this.body })
          .fontSize(15).fontColor('#333333').width('100%')
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .backgroundColor('#00000000').constraintSize({ minHeight: 200 })
      }
      .layoutWeight(1).backgroundColor('#FFFFFF')

      Row() {
        Text('📎').fontSize(20).width(44).height(44).textAlign(TextAlign.Center)
        Text('📧').fontSize(20).width(44).height(44).textAlign(TextAlign.Center)
        Text('🕐').fontSize(20).width(44).height(44).textAlign(TextAlign.Center)
        Blank()
        Text('⌨').fontSize(20).width(44).height(44).textAlign(TextAlign.Center)
      }
      .width('100%').padding({ left: 8, right: 8, top: 6, bottom: 6 })
      .backgroundColor('#FAFAFA').border({ width: { top: 0.5 }, color: '#E8E8E8' })

      Column().width('100%').height(260).backgroundColor('#D1D3D9')
    }
    .width('100%').height('100%').backgroundColor('#FFFFFF')
  }
}