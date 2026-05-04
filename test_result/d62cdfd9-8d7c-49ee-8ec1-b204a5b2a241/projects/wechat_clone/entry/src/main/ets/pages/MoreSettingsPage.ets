import router from '@ohos.router';

interface MoreSettingItem {
  label: string;
  itemType: 'navigation' | 'toggle';
  toggleState: boolean;
  targetRoute: string;
}

@Entry
@Component
struct MoreSettingsPage {
  @State autoSavePhotos: boolean = true;
  @State autoSaveVideos: boolean = true;

  private items: MoreSettingItem[] = [
    { label: '未成年人模式', itemType: 'navigation', toggleState: false, targetRoute: '' },
    { label: '关怀模式', itemType: 'navigation', toggleState: false, targetRoute: '' },
    { label: '自动保存拍摄或编辑后的图片', itemType: 'toggle', toggleState: true, targetRoute: '' },
    { label: '自动保存拍摄或编辑后的视频', itemType: 'toggle', toggleState: true, targetRoute: '' },
    { label: '系统权限', itemType: 'navigation', toggleState: false, targetRoute: 'pages/SystemPermissionsPage' },
    { label: '表情', itemType: 'navigation', toggleState: false, targetRoute: '' }
  ];

  onBackTap(): void {
    router.back();
  }

  onNavigationItemTap(item: MoreSettingItem): void {
    if (item.targetRoute && item.targetRoute.length > 0) {
      router.pushUrl({ url: item.targetRoute });
    } else {
      console.info(`Navigation to: ${item.label} — target route not yet available`);
    }
  }

  onToggleChange(index: number, isOn: boolean): void {
    if (index === 2) {
      this.autoSavePhotos = isOn;
    } else if (index === 3) {
      this.autoSaveVideos = isOn;
    }
  }

  @Builder
  NavigationRow(item: MoreSettingItem) {
    Row() {
      Text(item.label)
        .fontSize(16)
        .fontColor('#000000')
        .layoutWeight(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)

      Text('›')
        .fontSize(18)
        .fontColor('#BBBBBB')
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onNavigationItemTap(item);
    })
  }

  @Builder
  ToggleRow(item: MoreSettingItem, index: number) {
    Row() {
      Text(item.label)
        .fontSize(16)
        .fontColor('#000000')
        .layoutWeight(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)

      Toggle({
        type: ToggleType.Switch,
        isOn: index === 2 ? this.autoSavePhotos : this.autoSaveVideos
      })
        .selectedColor('#00c853')
        .onChange((isOn: boolean) => {
          this.onToggleChange(index, isOn);
        })
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  SeparatorLine() {
    Divider()
      .strokeWidth(0.5)
      .color('#E5E5E5')
      .margin({ left: 16 })
  }

  build() {
    Column() {
      // ── Navigation Bar ──
      Row() {
        Text('〈')
          .fontSize(20)
          .fontColor('#191919')
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onBackTap();
          })

        Text('更多')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#191919')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Spacer to balance the back button
        Row()
          .width(44)
          .height(44)
      }
      .width('100%')
      .height(44)
      .padding({ left: 4 })
      .backgroundColor('#EDEDED')

      // ── Scrollable Content ──
      Scroll() {
        Column() {
          Column() {
            ForEach(this.items, (item: MoreSettingItem, index: number) => {
              if (item.itemType === 'toggle') {
                this.ToggleRow(item, index)
              } else {
                this.NavigationRow(item)
              }
              if (index < this.items.length - 1) {
                this.SeparatorLine()
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 12 })
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
