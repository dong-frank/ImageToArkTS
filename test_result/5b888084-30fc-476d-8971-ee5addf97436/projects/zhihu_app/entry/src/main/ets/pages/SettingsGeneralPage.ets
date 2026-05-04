import { router } from '@kit.ArkUI';

interface ToggleItemData {
  label: string;
  isOn: boolean;
}

@Entry
@Component
struct SettingsGeneralPage {
  @State toggleItems: ToggleItemData[] = [
    { label: '查看通讯录好友', isOn: false },
    { label: '水印图片', isOn: true },
    { label: '内置音效', isOn: true },
    { label: '无图模式', isOn: false },
    { label: '双击赞同', isOn: true },
    { label: '夜间模式', isOn: false },
    { label: '调节字体大小', isOn: false },
    { label: '全屏阅读', isOn: false },
    { label: '页面自动跳转', isOn: false },
    { label: '知乎热榜推送', isOn: false },
    { label: '消息免打扰', isOn: false },
    { label: '图片质量', isOn: false },
    { label: '视频自动播放', isOn: false },
    { label: '清理缓存', isOn: false }
  ];

  onBack(): void {
    router.back();
  }

  build() {
    Column() {
      // Top navigation bar
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor('#1A1A1A')
          .padding({ left: 4, right: 12, top: 8, bottom: 8 })
          .onClick(() => {
            this.onBack();
          })

        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .layoutWeight(1)

        // Spacer to balance the row
        Row()
          .width(48)
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#FFFFFF')
      .border({
        width: { bottom: 0.5 },
        color: '#E0E0E0'
      })

      // Content: scrollable toggle list
      Scroll() {
        Column() {
          ForEach(this.toggleItems, (item: ToggleItemData, index: number) => {
            Row() {
              Text(item.label)
                .fontSize(16)
                .fontColor('#1A1A1A')
                .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: item.isOn })
                .selectedColor('#007AFF')
                .onChange((value: boolean) => {
                  this.toggleItems[index].isOn = value;
                })
            }
            .width('100%')
            .height(48)
            .padding({ left: 16, right: 16 })
            .backgroundColor('#FFFFFF')

            if (index < this.toggleItems.length - 1) {
              Divider()
                .strokeWidth(0.5)
                .color('#E8E8E8')
                .margin({ left: 16 })
            }
          })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
