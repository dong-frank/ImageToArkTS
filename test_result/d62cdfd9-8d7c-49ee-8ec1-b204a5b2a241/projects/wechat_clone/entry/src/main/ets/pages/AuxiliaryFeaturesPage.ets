import router from '@ohos.router';
import { NavigationService } from '../common/services/NavigationService';

interface FeatureItemData {
  label: string;
  iconColor: string;
  iconInitial: string;
  targetRoute: string;
}

@Entry
@Component
struct AuxiliaryFeaturesPage {
  private enabledFeatures: FeatureItemData[] = [
    {
      label: 'QQ邮箱提醒',
      iconColor: '#3385FF',
      iconInitial: '邮',
      targetRoute: ''
    },
    {
      label: '群发助手',
      iconColor: '#00C853',
      iconInitial: '群',
      targetRoute: ''
    },
    {
      label: '微信支付',
      iconColor: '#00C853',
      iconInitial: '付',
      targetRoute: ''
    }
  ];

  private disabledFeatures: FeatureItemData[] = [
    {
      label: '腾讯新闻',
      iconColor: '#FF6B6B',
      iconInitial: '新',
      targetRoute: ''
    },
    {
      label: '微信运动',
      iconColor: '#00C853',
      iconInitial: '动',
      targetRoute: ''
    },
    {
      label: '微信游戏',
      iconColor: '#FF9800',
      iconInitial: '游',
      targetRoute: ''
    }
  ];

  onBackTap(): void {
    router.back();
  }

  onItemTap(item: FeatureItemData): void {
    if (item.targetRoute && item.targetRoute.length > 0) {
      router.pushUrl({ url: item.targetRoute });
    }
  }

  @Builder
  SectionHeader(label: string, dotColor: string) {
    Row() {
      Circle({ width: 8, height: 8 })
        .fill(dotColor)
        .margin({ right: 8 })

      Text(label)
        .fontSize(13)
        .fontColor('#999999')
    }
    .width('100%')
    .padding({ left: 16, top: 16, bottom: 6 })
  }

  @Builder
  FeatureRow(item: FeatureItemData) {
    Row() {
      // Icon
      Row() {
        Text(item.iconInitial)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
      }
      .width(28)
      .height(28)
      .backgroundColor(item.iconColor)
      .borderRadius(4)
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      // Label
      Text(item.label)
        .fontSize(17)
        .fontColor('#191919')
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .layoutWeight(1)

      // Chevron
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
      .margin({ left: 56 })
  }

  @Builder
  FeatureGroup(features: FeatureItemData[]) {
    Column() {
      ForEach(features, (item: FeatureItemData, index: number) => {
        this.FeatureRow(item)
        if (index < features.length - 1) {
          this.SeparatorLine()
        }
      })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .margin({ left: 0, right: 0 })
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

        Text('辅助功能')
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
          // ── 已启用的功能 Section ──
          this.SectionHeader('已启用的功能', '#07C160')
          this.FeatureGroup(this.enabledFeatures)

          // ── 未启用的功能 Section ──
          this.SectionHeader('未启用的功能', '#BBBBBB')
          this.FeatureGroup(this.disabledFeatures)

          // Bottom spacer
          Row()
            .width('100%')
            .height(16)
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
