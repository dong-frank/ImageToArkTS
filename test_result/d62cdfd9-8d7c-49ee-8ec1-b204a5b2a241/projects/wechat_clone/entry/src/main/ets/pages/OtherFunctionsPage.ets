import router from '@ohos.router';
import { NavigationService } from '../common/services/NavigationService';

interface FunctionItemData {
  label: string;
  targetRoute: string;
}

@Entry
@Component
struct OtherFunctionsPage {
  private functionItems: FunctionItemData[] = [
    {
      label: '朋友圈',
      targetRoute: ''
    },
    {
      label: '听一听',
      targetRoute: ''
    },
    {
      label: '发现页',
      targetRoute: ''
    },
    {
      label: '辅助功能',
      targetRoute: NavigationService.routeFor('辅助功能')
    }
  ];

  onBackTap(): void {
    router.back();
  }

  onItemTap(item: FunctionItemData): void {
    if (item.targetRoute && item.targetRoute.length > 0) {
      router.pushUrl({ url: item.targetRoute });
    }
  }

  @Builder
  FunctionRow(item: FunctionItemData) {
    Row() {
      Text(item.label)
        .fontSize(17)
        .fontColor('#191919')
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .layoutWeight(1)

      Text('›')
        .fontSize(20)
        .fontColor('#BBBBBB')
        .margin({ right: 2 })
    }
    .width('100%')
    .height(56)
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

        Text('其他功能')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#191919')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

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
            ForEach(this.functionItems, (item: FunctionItemData, index: number) => {
              this.FunctionRow(item)
              if (index < this.functionItems.length - 1) {
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
