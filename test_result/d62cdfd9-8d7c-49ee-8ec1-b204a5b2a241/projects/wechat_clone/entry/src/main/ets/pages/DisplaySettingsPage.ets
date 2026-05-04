import router from '@ohos.router';
import { NavigationService } from '../common/services/NavigationService';

interface DisplaySettingItemData {
  label: string;
  trailingText: string;
  targetRoute: string;
}

@Entry
@Component
struct DisplaySettingsPage {
  private settingItems: DisplaySettingItemData[] = [
    {
      label: '深色模式',
      trailingText: '跟随系统',
      targetRoute: NavigationService.routeFor('深色模式')
    },
    {
      label: '字体大小',
      trailingText: '',
      targetRoute: ''
    },
    {
      label: '多语言',
      trailingText: '',
      targetRoute: ''
    },
    {
      label: '翻译',
      trailingText: '',
      targetRoute: ''
    }
  ];

  onBackTap(): void {
    router.back();
  }

  onItemTap(item: DisplaySettingItemData): void {
    if (item.targetRoute && item.targetRoute.length > 0) {
      router.pushUrl({ url: item.targetRoute });
    }
  }

  @Builder
  SettingRow(item: DisplaySettingItemData) {
    Row() {
      // Label
      Text(item.label)
        .fontSize(16)
        .fontColor('#191919')
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .layoutWeight(1)

      // Trailing text (e.g. current value)
      if (item.trailingText && item.trailingText.length > 0) {
        Text(item.trailingText)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ right: 4 })
      }

      // Chevron
      Text('›')
        .fontSize(18)
        .fontColor('#BBBBBB')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onItemTap(item);
    })
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
        Text('←')
          .fontSize(22)
          .fontColor('#191919')
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onBackTap();
          })

        Text('界面与显示')
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
          // ── Settings List ──
          Column() {
            ForEach(this.settingItems, (item: DisplaySettingItemData, index: number) => {
              this.SettingRow(item)
              if (index < this.settingItems.length - 1) {
                this.SeparatorLine()
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 16 })
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
}
