import { router } from '@kit.ArkUI';

interface ToolButtonItem {
  label: string;
  icon: string;
}

@Entry
@Component
struct ContentEditorPage {
  @State activeTab: string = '写回答';
  @State showTooltip: boolean = true;
  private tabLabels: string[] = ['提问题', '写回答', '发文章'];
  private toolbarItems: ToolButtonItem[] = [
    { label: '文字转图', icon: '🪄' },
    { label: '插入链接', icon: '🔗' },
    { label: '@', icon: '@' }
  ];

  aboutToAppear(): void {
    this.showTooltip = true;
  }

  onCloseTap(): void {
    router.back();
  }

  onPublishTap(): void {
    // Placeholder: publish action
    console.info('[ContentEditor] 发布按钮点击');
  }

  onTabTap(tab: string): void {
    this.activeTab = tab;
  }

  onToolbarTap(item: ToolButtonItem): void {
    if (item.label === '文字转图') {
      this.showTooltip = false;
    }
    console.info('[ContentEditor] 工具栏点击: ' + item.label);
  }

  onDismissTooltip(): void {
    this.showTooltip = false;
  }

  build() {
    Column() {
      // Top Navigation Bar
      Row() {
        // Close button (left)
        Text('×')
          .fontSize(26)
          .fontColor('#333333')
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onCloseTap();
          })

        // Draft indicator (center)
        Text('草稿(5)')
          .fontSize(14)
          .fontColor('#888888')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Publish button (right)
        Text('发布')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor('#0066FF')
          .borderRadius(16)
          .padding({ left: 18, right: 18, top: 7, bottom: 7 })
          .onClick(() => {
            this.onPublishTap();
          })
      }
      .width('100%')
      .height(50)
      .padding({ left: 8, right: 12 })
      .backgroundColor('#FFFFFF')

      // Divider after navbar
      Divider()
        .height(0.5)
        .color('#E5E5E5')

      // Scrollable editor content
      Scroll() {
        Column() {
          // Distribution Selector
          Row() {
            Text('选择发布范围')
              .fontSize(15)
              .fontColor('#333333')
              .layoutWeight(1)
            Text('›')
              .fontSize(18)
              .fontColor('#AAAAAA')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 14 })
          .backgroundColor('#FFFFFF')
          .onClick(() => {
            console.info('[ContentEditor] 发布范围选择器点击');
          })

          Divider()
            .height(0.5)
            .color('#F0F0F0')
            .margin({ left: 16 })

          // Title Input
          TextArea({ placeholder: '输入标题' })
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#111111')
            .placeholderColor('#CCCCCC')
            .backgroundColor('#FFFFFF')
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .maxLength(50)

          Divider()
            .height(0.5)
            .color('#F0F0F0')
            .margin({ left: 16 })

          // Body Input
          TextArea({ placeholder: '输入正文' })
            .fontSize(16)
            .fontColor('#333333')
            .placeholderColor('#CCCCCC')
            .backgroundColor('#FFFFFF')
            .width('100%')
            .height(200)
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .maxLength(5000)

          // Media Placeholder
          Row() {
            Column() {
              Text('+')
                .fontSize(32)
                .fontColor('#CCCCCC')
              Text('添加图片/视频')
                .fontSize(13)
                .fontColor('#AAAAAA')
                .margin({ top: 6 })
            }
            .width(100)
            .height(100)
            .border({ width: 1, color: '#E5E5E5', style: BorderStyle.Dashed })
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              console.info('[ContentEditor] 媒体占位区点击');
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 12 })
          .backgroundColor('#FFFFFF')
          .justifyContent(FlexAlign.Start)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#FFFFFF')

      // Bottom Toolbar
      Column() {
        // Toolbar buttons row
        Row() {
          ForEach(this.toolbarItems, (item: ToolButtonItem, index: number) => {
            Row() {
              Text(item.icon)
                .fontSize(16)
                .fontColor(index === 0 ? '#7C3AED' : '#666666')
              Text(item.label)
                .fontSize(14)
                .fontColor(index === 0 ? '#7C3AED' : '#666666')
                .margin({ left: 4 })
            }
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('#F5F5F5')
            .borderRadius(18)
            .margin({ right: 10 })
            .onClick(() => {
              this.onToolbarTap(item);
            })
          })

          // Feature tooltip overlay anchored near toolbar
          if (this.showTooltip) {
            Stack() {
              Column() {
                Row() {
                  Text('🪄')
                    .fontSize(14)
                  Text('试试文字转图新功能')
                    .fontSize(12)
                    .fontColor('#FFFFFF')
                    .margin({ left: 4 })
                  Text('×')
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                    .margin({ left: 8 })
                    .onClick(() => {
                      this.onDismissTooltip();
                    })
                }
              }
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor('#7C3AED')
              .borderRadius(8)
            }
            .position({ x: 0, y: -44 })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .justifyContent(FlexAlign.Start)

        Divider()
          .height(0.5)
          .color('#E5E5E5')

        // Content Type Tabs
        Row() {
          ForEach(this.tabLabels, (tab: string) => {
            Text(tab)
              .fontSize(14)
              .fontWeight(tab === this.activeTab ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(tab === this.activeTab ? '#0066FF' : '#666666')
              .padding({ left: 16, right: 16, top: 10, bottom: 10 })
              .borderRadius(20)
              .backgroundColor(tab === this.activeTab ? '#EBF3FF' : '#F5F5F5')
              .margin({ right: 12 })
              .onClick(() => {
                this.onTabTap(tab);
              })
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 12 })
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .backgroundColor('#FAFAFA')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
