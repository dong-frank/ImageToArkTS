import router from '@ohos.router';

interface ToggleItem {
  label: string;
  enabled: boolean;
}

interface SectionGroup {
  title: string;
  items: ToggleItem[];
}

@Entry
@Component
struct MessageSettingsPage {
  @State sections: SectionGroup[] = [
    {
      title: '私信接收设置',
      items: [
        { label: '接收私信', enabled: true },
        { label: '接收陌生人的私信', enabled: false }
      ]
    },
    {
      title: '提及与互动',
      items: [
        { label: '有人@我', enabled: true },
        { label: '有人评论我', enabled: true }
      ]
    },
    {
      title: '内容收藏',
      items: [
        { label: '有人收藏我的内容', enabled: true }
      ]
    },
    {
      title: '关注动态',
      items: [
        { label: '关注的人有新动态', enabled: true }
      ]
    }
  ];

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor('#333333')
          .padding({ left: 16, right: 12, top: 12, bottom: 12 })
          .onClick(() => {
            router.back();
          })

        Text('消息设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center)

      // Divider below nav bar
      Divider()
        .strokeWidth(0.5)
        .color('#E5E5E5')

      // Scrollable settings list
      Scroll() {
        Column() {
          ForEach(this.sections, (section: SectionGroup, sectionIndex: number) => {
            Column() {
              // Section header
              Text(section.title)
                .fontSize(13)
                .fontColor('#888888')
                .padding({ left: 16, top: 24, bottom: 8 })
                .width('100%')

              // Section card
              Column() {
                ForEach(section.items, (item: ToggleItem, itemIndex: number) => {
                  Column() {
                    Row() {
                      Text(item.label)
                        .fontSize(16)
                        .fontColor('#333333')
                        .layoutWeight(1)

                      Toggle({ type: ToggleType.Switch, isOn: item.enabled })
                        .onChange((isOn: boolean) => {
                          this.sections[sectionIndex].items[itemIndex].enabled = isOn;
                        })
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
                    .alignItems(VerticalAlign.Center)

                    if (itemIndex < section.items.length - 1) {
                      Divider()
                        .strokeWidth(0.5)
                        .color('#F0F0F0')
                        .margin({ left: 16 })
                    }
                  }
                })
              }
              .width('100%')
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
            }
            .width('100%')
            .padding({ left: 12, right: 12 })
          })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
