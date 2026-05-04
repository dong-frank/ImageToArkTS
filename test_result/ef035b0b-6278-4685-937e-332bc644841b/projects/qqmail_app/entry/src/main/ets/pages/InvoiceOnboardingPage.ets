/**
 * InvoiceOnboardingPage - Invoice feature onboarding/activation
 * Based on: Draft 12 (success)
 */
import router from '@ohos.router';

@Entry
@Component
struct InvoiceOnboardingPage {
  @State agreementChecked: boolean = false;
  @State autoDetect: boolean = true;

  handleBackTap(): void {
    router.back();
  }

  handleConfirm(): void {
    if (this.agreementChecked) {
      // Proceed with activation
    }
  }

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor('#4A90D9')
          .width(40).height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.handleBackTap(); })

        Text('文件云盘')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Column().width(40)
      }
      .width('100%').height(48).backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // Illustration
          Text('🧾')
            .fontSize(56)
            .margin({ top: 30, bottom: 16 })

          Text('开启并使用发票')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .margin({ bottom: 20 })

          // Feature bullets
          Column() {
            Row() {
              Text('✓')
                .fontSize(14).fontColor('#34C759')
                .margin({ right: 8 })
              Text('邮件中的发票自动同步，一目了然')
                .fontSize(14).fontColor('#333333')
            }
            .width('100%').padding({ top: 6, bottom: 6 })

            Row() {
              Text('✓')
                .fontSize(14).fontColor('#34C759')
                .margin({ right: 8 })
              Text('关联微信发票后，两端同步更便捷')
                .fontSize(14).fontColor('#333333')
            }
            .width('100%').padding({ top: 6, bottom: 6 })

            Row() {
              Text('✓')
                .fontSize(14).fontColor('#34C759')
                .margin({ right: 8 })
              Text('一键生成报销单，发票批量省心管')
                .fontSize(14).fontColor('#333333')
            }
            .width('100%').padding({ top: 6, bottom: 6 })

            // Auto-detect checkbox
            Row() {
              Checkbox({ name: 'autoDetect', group: 'invoiceGroup' })
                .select(this.autoDetect)
                .margin({ right: 8 })
                .width(18).height(18)
              Text('自动识别下载发票邮件附件的发票')
                .fontSize(13).fontColor('#666666')
            }
            .width('100%').padding({ top: 10, bottom: 10 })
            .margin({ top: 8 })
          }
          .width('100%')
          .backgroundColor('#F8F8F8')
          .borderRadius(10)
          .padding(14)
          .margin({ top: 8 })

          // Agreement
          Row() {
            Checkbox({ name: 'agreement', group: 'agreementGroup' })
              .select(this.agreementChecked)
              .width(18).height(18)
              .margin({ right: 6 })
              .onChange((value: boolean) => { this.agreementChecked = value; })

            Text('我已阅读并同意')
              .fontSize(12).fontColor('#888888')
            Text('《腾讯邮箱发票授权须知》')
              .fontSize(12).fontColor('#4A90D9')
          }
          .width('100%')
          .padding({ top: 16, bottom: 16 })

          // Confirm button
          Button('确定')
            .width('100%')
            .height(44)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(this.agreementChecked ? '#4A90D9' : '#B0C4DE')
            .borderRadius(22)
            .onClick(() => { this.handleConfirm(); })

          Column().height(20)
        }
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 24, right: 24 })
      }
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')

      // Bottom tab bar
      Row() {
        Column() {
          Text('📁').fontSize(18)
          Text('文件').fontSize(10).fontColor('#888888')
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)

        Column() {
          Text('🔄').fontSize(18)
          Text('中转站').fontSize(10).fontColor('#888888')
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)

        Column() {
          Text('🧾').fontSize(18)
          Text('发票').fontSize(10).fontColor('#4A90D9')
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      .backgroundColor('#FAFAFA')
      .border({ width: { top: 0.5 }, color: '#E8E8E8' })
    }
    .width('100%').height('100%').backgroundColor('#FFFFFF')
  }
}
