import router from '@ohos.router';

interface IndexFolderItem {
  icon: string;
  name: string;
  count: number;
  route: string;
}

interface IndexSection {
  title: string;
  expanded: boolean;
  items: Array<IndexFolderItem>;
}

@Entry
@Component
struct Index {
  @State sections: Array<IndexSection> = [
    {
      title: 'iCloud',
      expanded: true,
      items: [
        { icon: '📁', name: '备忘录', count: 0, route: 'pages/MemoList' }
      ]
    },
    {
      title: '我的 iPhone',
      expanded: true,
      items: [
        { icon: '📁', name: '备忘录', count: 209, route: 'pages/MemoList' },
        { icon: '🗑️', name: '最近删除', count: 2, route: 'pages/MemoList' }
      ]
    }
  ];
  @State isEditMode: boolean = false;
  @State searchText: string = '';
  @State showSearchSuggestions: boolean = false;

  @Builder
  FolderCard(item: IndexFolderItem) {
    Row() {
      Text(item.icon)
        .fontSize(20)
        .margin({ right: 12 })
      Text(item.name)
        .fontSize(16)
        .fontColor('#000000')
        .layoutWeight(1)
      Text(item.count.toString())
        .fontSize(14)
        .fontColor('#999999')
        .margin({ right: 8 })
      Text('>')
        .fontSize(14)
        .fontColor('#999999')
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      if (!this.isEditMode) {
        router.pushUrl({ url: item.route })
          .then(() => {})
          .catch((err: Error) => {});
      }
    })
  }

  @Builder
  SectionHeader(section: IndexSection, index: number) {
    Row() {
      Text(section.title)
        .fontSize(18)
        .fontColor('#000000')
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
      Text(section.expanded ? '▼' : '▶')
        .fontSize(14)
        .fontColor('#FFB800')
    }
    .padding({ top: 24, bottom: 12, left: 16, right: 16 })
    .onClick(() => {
      this.sections[index].expanded = !this.sections[index].expanded;
    })
  }

  @Builder
  SearchSuggestionsPanel() {
    Column() {
      Text('🧑‍🤝‍🧑 共享的备忘录')
        .fontSize(16)
        .fontColor('#000000')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .width('100%')
        .backgroundColor('#FFFFFF')
        .onClick(() => {})
      Divider().strokeWidth(1).color('#E0E0E0')
      Text('🔒 已锁定备忘录')
        .fontSize(16)
        .fontColor('#000000')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .width('100%')
        .backgroundColor('#FFFFFF')
        .onClick(() => {})
      Divider().strokeWidth(1).color('#E0E0E0')
      Text('✅ 含核对清单的备忘录')
        .fontSize(16)
        .fontColor('#000000')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .width('100%')
        .backgroundColor('#FFFFFF')
        .onClick(() => {})
      Divider().strokeWidth(1).color('#E0E0E0')
      Text('# 含标签的备忘录')
        .fontSize(16)
        .fontColor('#000000')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .width('100%')
        .backgroundColor('#FFFFFF')
        .onClick(() => {})
      Divider().strokeWidth(1).color('#E0E0E0')
      Text('🎨 含涂鸦的备忘录')
        .fontSize(16)
        .fontColor('#000000')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .width('100%')
        .backgroundColor('#FFFFFF')
        .onClick(() => {})
      Divider().strokeWidth(1).color('#E0E0E0')
      Text('📄 含扫描文稿的备忘录')
        .fontSize(16)
        .fontColor('#000000')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .width('100%')
        .backgroundColor('#FFFFFF')
        .onClick(() => {})
    }
    .borderRadius(12)
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor('#FFFFFF')
  }

  build() {
    Column() {
      Column() {
        Row() {
          Column() {
            Text('文件夹')
              .fontSize(22)
              .fontColor('#000000')
              .fontWeight(FontWeight.Medium)
            Row() {
              Text('☁️')
                .fontSize(12)
              Text('储存空间已满')
                .fontSize(12)
                .fontColor('#999999')
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Row() {
            Button({ type: ButtonType.Circle }) {
              Text('📁+')
                .fontSize(16)
            }
            .width(40)
            .height(40)
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#CCCCCC' })
            .margin({ right: 12 })
            .onClick(() => {})

            Button(this.isEditMode ? '✓' : '编辑') {
              Text(this.isEditMode ? '✓' : '编辑')
                .fontSize(16)
                .fontColor('#000000')
            }
            .padding({ left: 16, right: 16 })
            .height(40)
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#CCCCCC' })
            .borderRadius(12)
            .onClick(() => {
              this.isEditMode = !this.isEditMode;
            })
          }
        }
        .padding({ top: 20, left: 16, right: 16, bottom: 20 })

        Column() {
          ForEach(this.sections, (section: IndexSection, index: number) => {
            Column() {
              this.SectionHeader(section, index)
              if (section.expanded) {
                Column() {
                  ForEach(section.items, (item: IndexFolderItem) => {
                    Column() {
                      this.FolderCard(item)
                      if (section.items.indexOf(item) < section.items.length - 1) {
                        Divider()
                          .strokeWidth(1)
                          .color('#E0E0E0')
                          .margin({ left: 16, right: 16 })
                      }
                    }
                  })
                }
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .margin({ left: 16, right: 16 })
              }
            }
          })
        }
        .layoutWeight(1)
      }

      if (this.showSearchSuggestions) {
        this.SearchSuggestionsPanel()
      }

      Column() {
        Row() {
          Text('🔍')
            .fontSize(18)
            .fontColor('#999999')
            .margin({ left: 16, right: 12 })
          TextInput({ placeholder: '搜索', text: this.searchText })
            .placeholderFont({ size: 16, weight: FontWeight.Normal })
            .placeholderColor('#999999')
            .fontSize(16)
            .fontColor('#000000')
            .layoutWeight(1)
            .onChange((value: string) => {
              this.searchText = value;
            })
            .onEditChange((isEditing: boolean) => {
              this.showSearchSuggestions = isEditing;
            })
          Text('🎤')
            .fontSize(18)
            .fontColor('#999999')
            .margin({ left: 12, right: 16 })
            .onClick(() => {})
        }
        .height(48)
        .borderRadius(16)
        .backgroundColor('#FFFFFF')
        .margin({ left: 16, right: 16, bottom: 24 })

        Button({ type: ButtonType.Circle }) {
          Text('✏️')
            .fontSize(20)
            .fontColor('#000000')
        }
        .width(56)
        .height(56)
        .backgroundColor('#FFFFFF')
        //.alignSelf(HorizontalAlign.End)
        .margin({ right: 24 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/NewMemo' })
            .then(() => {})
            .catch((err: Error) => {});
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}