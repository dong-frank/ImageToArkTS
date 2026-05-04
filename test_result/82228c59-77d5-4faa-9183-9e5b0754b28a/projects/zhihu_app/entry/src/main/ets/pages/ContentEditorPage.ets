import router from '@ohos.router';

@Entry
@Component
struct ContentEditorPage {
  @State titleText: string = '';
  @State contentText: string = '';
  @State isAnonymous: boolean = false;
  @State selectedTopic: string = '';

  build() {
    Column() {
      // Top bar
      Row() {
        Text('\u{2715}')
          .fontSize(20)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })

        Blank()

        Text('写回答')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')

        Blank()

        Button('发布')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#0066FF')
          .borderRadius(16)
          .height(32)
          .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Divider()
        .height(1)
        .color('#F0F0F0')

      Scroll() {
        Column() {
          // Question context
          Row() {
            Text('Q')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0066FF')
              .width(24)
              .height(24)
              .borderRadius(12)
              .backgroundColor('#E8F2FF')
              .textAlign(TextAlign.Center)
              .margin({ right: 8 })

            Text('如何评价苹果公司最新发布的 M4 芯片？')
              .fontSize(14)
              .fontColor('#666666')
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#F8F8F8')
          .borderRadius(8)
          .margin({ left: 16, right: 16, top: 12 })

          // Editor toolbar
          Row() {
            this.ToolbarButton('\u{1D401}', 0)
            this.ToolbarButton('\u{1D402}', 1)
            this.ToolbarButton('\u{1D403}', 2)
            this.ToolbarButton('\u{1F4F7}', 3)
            this.ToolbarButton('\u{1F517}', 4)
            this.ToolbarButton('\u{25B6}', 5)
            Blank()
            Text('\u{22EE}')
              .fontSize(18)
              .fontColor('#999999')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })

          // Content text area
          TextArea({ text: this.contentText, placeholder: '分享你的知识、经验和见解...' })
            .fontSize(16)
            .fontColor('#1A1A1A')
            .placeholderColor('#CCCCCC')
            .width('100%')
            .height(300)
            .padding(16)
            .backgroundColor('#FFFFFF')
            .onChange((value: string) => {
              this.contentText = value;
            })

          Divider()
            .height(8)
            .color('#F5F5F5')

          // Options section
          Column() {
            Text('发布设置')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A1A')
              .width('100%')
              .padding({ left: 16, right: 16, top: 14 })

            // Anonymous toggle
            Row() {
              Text('匿名发布')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.isAnonymous })
                .onChange((value: boolean) => {
                  this.isAnonymous = value;
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })

            Divider()
              .height(1)
              .color('#F0F0F0')
              .margin({ left: 16, right: 16 })

            // Topic selection
            Row() {
              Text('添加话题')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text(this.selectedTopic ? this.selectedTopic : '选择话题')
                .fontSize(14)
                .fontColor(this.selectedTopic ? '#0066FF' : '#999999')
              Text('\u{276F}')
                .fontSize(14)
                .fontColor('#CCCCCC')
                .margin({ left: 4 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })

            Divider()
              .height(1)
              .color('#F0F0F0')
              .margin({ left: 16, right: 16 })

            // Copyright notice
            Row() {
              Text('\u{24B8}')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ right: 6 })
              Text('原创声明')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text('已开启')
                .fontSize(13)
                .fontColor('#0066FF')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ToolbarButton(icon: string, index: number) {
    Text(icon)
      .fontSize(20)
      .fontColor('#666666')
      .padding({ left: 6, right: 6 })
      .onClick(() => {
        // Toolbar action
      })
  }
}
