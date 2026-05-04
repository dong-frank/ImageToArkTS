import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct FeedbackPage {
  @State feedbackType: number = 0; // 0=问题反馈, 1=功能建议, 2=其他
  @State feedbackText: string = '';
  @State contactInfo: string = '';
  @State selectedImages: string[] = [];
  @State maxTextLength: number = 500;

  private feedbackTypes: string[] = ['问题反馈', '功能建议', '其他'];

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })

        Text('意见反馈')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('提交')
          .fontSize(14)
          .fontColor('#FF6600')
          .onClick(() => {
            this.submitFeedback();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // Feedback type selector
          this.FeedbackTypeSelector()

          // Feedback text area
          this.FeedbackTextArea()

          // Image upload area
          this.ImageUploadArea()

          // Contact info
          this.ContactInfoInput()

          // Common issues section
          this.CommonIssues()
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
  FeedbackTypeSelector() {
    Column() {
      Text('反馈类型')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 10 })
        .alignSelf(ItemAlign.Start)

      Row() {
        ForEach(this.feedbackTypes, (type: string, index: number) => {
          Text(type)
            .fontSize(13)
            .fontColor(this.feedbackType === index ? '#FFFFFF' : '#666666')
            .backgroundColor(this.feedbackType === index ? '#FF6600' : '#F0F0F0')
            .borderRadius(16)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .margin({ right: 10 })
            .onClick(() => {
              this.feedbackType = index;
            })
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 8 })
  }

  @Builder
  FeedbackTextArea() {
    Column() {
      Row() {
        Text('详细描述')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()

        Text(this.feedbackText.length + '/' + this.maxTextLength)
          .fontSize(12)
          .fontColor('#CCCCCC')
      }
      .width('100%')
      .margin({ bottom: 8 })

      TextArea({
        placeholder: '请详细描述您遇到的问题或建议，我们会认真对待每一条反馈...',
        text: this.feedbackText
      })
        .width('100%')
        .height(160)
        .fontSize(14)
        .fontColor('#333333')
        .placeholderColor('#CCCCCC')
        .backgroundColor('#F8F8F8')
        .borderRadius(8)
        .padding(12)
        .maxLength(this.maxTextLength)
        .onChange((value: string) => {
          this.feedbackText = value;
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 8 })
  }

  @Builder
  ImageUploadArea() {
    Column() {
      Text('添加截图（选填）')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 10 })
        .alignSelf(ItemAlign.Start)

      Row() {
        // Existing images
        ForEach(this.selectedImages, (img: string, index: number) => {
          Row() {
            Text('📷')
              .fontSize(24)
          }
          .width(72)
          .height(72)
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .margin({ right: 8 })
          .onClick(() => {
            // Remove image
            const updated: string[] = [];
            for (let i = 0; i < this.selectedImages.length; i++) {
              if (i !== index) {
                updated.push(this.selectedImages[i]);
              }
            }
            this.selectedImages = updated;
          })
        })

        // Add image button
        if (this.selectedImages.length < 4) {
          Column() {
            Text('📸')
              .fontSize(20)
            Text('添加图片')
              .fontSize(10)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
          .width(72)
          .height(72)
          .backgroundColor('#F8F8F8')
          .borderRadius(8)
          .border({ width: 1, color: '#E0E0E0', style: BorderStyle.Dashed })
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            // Simulate adding an image
            const updated: string[] = [];
            for (let i = 0; i < this.selectedImages.length; i++) {
              updated.push(this.selectedImages[i]);
            }
            updated.push('image_' + (this.selectedImages.length + 1));
            this.selectedImages = updated;
          })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 8 })
  }

  @Builder
  ContactInfoInput() {
    Column() {
      Text('联系方式（选填）')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 8 })
        .alignSelf(ItemAlign.Start)

      TextInput({
        placeholder: '请输入手机号或邮箱，方便我们联系您',
        text: this.contactInfo
      })
        .width('100%')
        .height(44)
        .fontSize(14)
        .fontColor('#333333')
        .placeholderColor('#CCCCCC')
        .backgroundColor('#F8F8F8')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .type(InputType.Normal)
        .onChange((value: string) => {
          this.contactInfo = value;
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 8 })
  }

  @Builder
  CommonIssues() {
    Column() {
      Text('常见问题')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start)

      this.IssueItem('🔐', '账号相关问题', '登录、注册、密码找回等')
      this.IssueItem('💳', '支付相关问题', '支付失败、退款、优惠券使用等')
      this.IssueItem('📋', '订单相关问题', '订单状态、取消订单、售后等')
      this.IssueItem('⭐', '评价与笔记', '写评价、发笔记、上传图片等')
      this.IssueItem('🔔', '消息与通知', '消息推送、系统通知设置等')
      this.IssueItem('⚙️', '其他问题', '版本更新、隐私政策、用户协议等')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 24 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 8 })
  }

  @Builder
  IssueItem(icon: string, title: string, subtitle: string) {
    Row() {
      Text(icon)
        .fontSize(20)
        .margin({ right: 12 })

      Column() {
        Text(title)
          .fontSize(14)
          .fontColor('#333333')
        Text(subtitle)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(18)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
    .onClick(() => {
      promptAction.showToast({ message: '正在加载「' + title + '」帮助内容', duration: 1500 });
    })
  }

  submitFeedback() {
    if (this.feedbackText.trim().length === 0) {
      promptAction.showToast({ message: '请输入反馈内容', duration: 1500 });
      return;
    }

    promptAction.showToast({ message: '感谢您的反馈，我们会尽快处理！', duration: 2000 });

    // Clear form and go back after a short delay
    setTimeout(() => {
      router.back();
    }, 1500);
  }
}
