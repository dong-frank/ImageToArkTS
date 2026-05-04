import router from '@ohos.router';

// Scenario card data model
interface ScenarioItem {
  label: string;
  icon: string;
  selected: boolean;
}

@Entry
@Component
struct FeedbackForm {
  @State scenarios: ScenarioItem[] = [
    { label: '功能异常', icon: 'bug_report', selected: false },
    { label: '体验问题', icon: 'sentiment_dissatisfied', selected: false },
    { label: '商家信息', icon: 'store', selected: false },
    { label: '其他', icon: 'more_horiz', selected: false }
  ];
  @State feedbackText: string = '';
  @State contactText: string = '';
  @State imageCount: number = 0;
  @State selectedScenarioIndex: number = -1;

  build() {
    Column() {
      // Navigation bar: back button + title
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ left: 16, right: 8, top: 12, bottom: 12 })
          .onClick(() => {
            router.back();
          })

        Text('意见反馈')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')

        Blank()
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center)

      Divider()
        .height(0.5)
        .color('#E5E5E5')

      // Scrollable form content
      Scroll() {
        Column() {
          // Alert banner
          Row() {
            Text('请选择反馈类型并详细描述您遇到的问题，我们会尽快处理')
              .fontSize(13)
              .fontColor('#666666')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .backgroundColor('#FFF8E1')
          .borderRadius(8)
          .margin({ left: 16, right: 16, top: 16 })

          // Scenario grid: 2×2
          Text('选择问题发生的场景')
            .fontSize(15)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 16, top: 20, bottom: 12 })
            .alignSelf(ItemAlign.Start)

          Grid() {
            ForEach(this.scenarios, (item: ScenarioItem, index: number) => {
              GridItem() {
                Column() {
                  Text(item.icon)
                    .fontSize(28)
                    .margin({ bottom: 8 })

                  Text(item.label)
                    .fontSize(14)
                    .fontColor(this.selectedScenarioIndex === index ? '#FF6600' : '#333333')
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .backgroundColor(this.selectedScenarioIndex === index ? '#FFF5EB' : '#F5F5F5')
                .borderRadius(8)
                .border({
                  width: this.selectedScenarioIndex === index ? 1.5 : 0,
                  color: '#FF6600'
                })
                .onClick(() => {
                  this.selectedScenarioIndex = index;
                })
              }
            })
          }
          .columnsTemplate('1fr 1fr')
          .rowsTemplate('1fr 1fr')
          .columnsGap(12)
          .rowsGap(12)
          .width('100%')
          .height(160)
          .padding({ left: 16, right: 16 })

          // Text area section
          Text('请描述你的建议和想法，我们会不断优化改进')
            .fontSize(15)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 16, top: 20, bottom: 4 })
            .alignSelf(ItemAlign.Start)

          Text('还有更多建议和想法？快告诉我们吧～')
            .fontSize(12)
            .fontColor('#999999')
            .padding({ left: 16, bottom: 10 })
            .alignSelf(ItemAlign.Start)

          Column() {
            TextArea({ placeholder: '请详细描述您的问题（300字以内）', text: this.feedbackText })
              .height(140)
              .fontSize(14)
              .fontColor('#333333')
              .placeholderColor('#CCCCCC')
              .backgroundColor('#F9F9F9')
              .borderRadius(8)
              .padding(12)
              .maxLength(300)
              .onChange((value: string) => {
                this.feedbackText = value;
              })

            // Character counter
            Row() {
              Blank()
              Text(`${this.feedbackText.length}/300`)
                .fontSize(12)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ right: 4, top: 6 })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })

          // Image upload section
          Text('添加图片（选填）')
            .fontSize(15)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 16, top: 20, bottom: 4 })
            .alignSelf(ItemAlign.Start)

          Text('上传图片以便详细解释建议和想法')
            .fontSize(12)
            .fontColor('#999999')
            .padding({ left: 16, bottom: 10 })
            .alignSelf(ItemAlign.Start)

          Row() {
            // Add image button
            Column() {
              Text('+')
                .fontSize(32)
                .fontColor('#CCCCCC')
                .fontWeight(FontWeight.Lighter)

              Text(`${this.imageCount}/9`)
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 4 })
            }
            .width(80)
            .height(80)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0', style: BorderStyle.Dashed })
            .onClick(() => {
              console.info('[FeedbackForm] 图片上传 - 系统相册/相机选择未接入');
            })

            Blank()
          }
          .width('100%')
          .padding({ left: 16, right: 16 })

          // Contact input section
          Text('联系方式')
            .fontSize(15)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 16, top: 20, bottom: 10 })
            .alignSelf(ItemAlign.Start)

          TextInput({ placeholder: '请输入联系方式（选填）', text: this.contactText })
            .height(44)
            .fontSize(14)
            .fontColor('#333333')
            .placeholderColor('#CCCCCC')
            .backgroundColor('#F9F9F9')
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .margin({ left: 16, right: 16 })
            .onChange((value: string) => {
              this.contactText = value;
            })

          // Submit button
          Button('提交')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF6600')
            .borderRadius(24)
            .margin({ left: 16, right: 16, top: 32, bottom: 32 })
            .onClick(() => {
              console.info('[FeedbackForm] 提交反馈 - 提交成功页未覆盖');
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
