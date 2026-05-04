import { router } from '@kit.ArkUI';

interface PreferenceItemData {
  label: string;
  selectedIndex: number; // 0=减少, 1=默认, 2=增加
}

@Entry
@Component
struct InterestPreferencePage {
  @State preferenceItems: PreferenceItemData[] = [
    { label: '社会/时政', selectedIndex: 1 },
    { label: '科技互联网', selectedIndex: 1 },
    { label: '职场', selectedIndex: 1 },
    { label: '娱乐', selectedIndex: 1 },
    { label: '人文', selectedIndex: 1 },
    { label: '情感', selectedIndex: 1 },
    { label: '体育竞技', selectedIndex: 1 },
    { label: '家居生活', selectedIndex: 1 }
  ];

  onBack(): void {
    router.back();
  }

  onResetDefaults(): void {
    const reset: PreferenceItemData[] = [];
    for (let i = 0; i < this.preferenceItems.length; i++) {
      reset.push({
        label: this.preferenceItems[i].label,
        selectedIndex: 1
      });
    }
    this.preferenceItems = reset;
  }

  onSelectPreference(index: number, newSelectedIndex: number): void {
    this.preferenceItems[index] = {
      label: this.preferenceItems[index].label,
      selectedIndex: newSelectedIndex
    };
  }

  onEditTags(): void {
    // 编辑兴趣标签页在当前阶段尚未覆盖，预留导航
    console.info('[InterestPreferencePage] 编辑标签入口 - 目标页 InterestTagsEditorPage 尚未注册');
  }

  build() {
    Column() {
      // Header: back button + title + reset button
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor('#1A1A1A')
          .padding({ left: 4, right: 12, top: 8, bottom: 8 })
          .onClick(() => {
            this.onBack();
          })

        Text('内容兴趣偏好')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .layoutWeight(1)

        Text('恢复默认')
          .fontSize(15)
          .fontColor('#0066CC')
          .padding({ left: 12, right: 8, top: 8, bottom: 8 })
          .onClick(() => {
            this.onResetDefaults();
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#FFFFFF')
      .border({
        width: { bottom: 0.5 },
        color: '#E0E0E0'
      })

      // Scrollable content area
      Scroll() {
        Column() {
          // Subtitle
          Text('为你推荐可能感兴趣的内容')
            .fontSize(14)
            .fontColor('#999999')
            .padding({ left: 16, top: 12, bottom: 8 })
            .width('100%')

          // 8 preference rows
          ForEach(this.preferenceItems, (item: PreferenceItemData, index: number) => {
            Row() {
              // Category label
              Text(item.label)
                .fontSize(16)
                .fontColor('#1A1A1A')
                .layoutWeight(1)

              // Three-state segmented control
              Row({ space: 0 }) {
                // "减少" button
                Text('减少')
                  .fontSize(13)
                  .fontColor(item.selectedIndex === 0 ? '#1A1A1A' : '#999999')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor(item.selectedIndex === 0 ? '#FFFFFF' : '#F0F0F0')
                  .borderRadius({ topLeft: 6, bottomLeft: 6 })
                  .border({
                    width: 0.5,
                    color: '#D0D0D0'
                  })
                  .onClick(() => {
                    this.onSelectPreference(index, 0);
                  })

                // "默认" button
                Text('默认')
                  .fontSize(13)
                  .fontColor(item.selectedIndex === 1 ? '#1A1A1A' : '#999999')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor(item.selectedIndex === 1 ? '#FFFFFF' : '#F0F0F0')
                  .border({
                    width: 0.5,
                    color: '#D0D0D0'
                  })
                  .onClick(() => {
                    this.onSelectPreference(index, 1);
                  })

                // "增加" button
                Text('增加')
                  .fontSize(13)
                  .fontColor(item.selectedIndex === 2 ? '#1A1A1A' : '#999999')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor(item.selectedIndex === 2 ? '#FFFFFF' : '#F0F0F0')
                  .borderRadius({ topRight: 6, bottomRight: 6 })
                  .border({
                    width: 0.5,
                    color: '#D0D0D0'
                  })
                  .onClick(() => {
                    this.onSelectPreference(index, 2);
                  })
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .backgroundColor('#FFFFFF')

            // Divider between rows
            if (index < this.preferenceItems.length - 1) {
              Divider()
                .strokeWidth(0.5)
                .color('#E8E8E8')
                .margin({ left: 16 })
            }
          })

          // Footer: "编辑兴趣标签 >" entry
          Text('编辑兴趣标签 >')
            .fontSize(15)
            .fontColor('#0066CC')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            .width('100%')
            .backgroundColor('#FFFFFF')
            .margin({ top: 12 })
            .onClick(() => {
              this.onEditTags();
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
