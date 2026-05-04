import { router } from '@kit.ArkUI';

interface PrivacyListItem {
  label: string;
  subtitle?: string;
  route?: string;
  isToggle?: boolean;
  toggleState?: boolean;
}

interface PrivacySection {
  sectionTitle: string;
  items: PrivacyListItem[];
}

@Entry
@Component
struct PrivacySettingsPage {
  @State ipLocationToggle: boolean = true;

  private sections: PrivacySection[] = [
    {
      sectionTitle: '屏蔽设置',
      items: [
        { label: '屏蔽用户', route: '' },
        { label: '屏蔽话题', route: '' }
      ]
    },
    {
      sectionTitle: '互动设置',
      items: [
        { label: '谁可以评论我', route: '' },
        { label: '谁可以给我发私信', route: '' }
      ]
    },
    {
      sectionTitle: '隐私信息',
      items: [
        { label: '个人信息收集清单', route: '' },
        {
          label: '与第三方共享个人信息清单',
          route: 'pages/ThirdPartyDataSharingPage'
        }
      ]
    },
    {
      sectionTitle: '隐私政策',
      items: [
        {
          label: '个人信息保护指引',
          route: 'pages/PrivacyGuidePage'
        },
        {
          label: '知乎协议',
          route: 'pages/ZhihuAgreementPage'
        }
      ]
    },
    {
      sectionTitle: '隐私设置',
      items: [
        {
          label: '在回答中显示IP属地',
          isToggle: true,
          toggleState: true
        }
      ]
    }
  ];

  build() {
    Column() {
      // ── Top Navigation Bar ──
      this.buildNavBar();

      // ── Scrollable Content ──
      Scroll() {
        Column() {
          // Sections
          ForEach(this.sections, (section: PrivacySection, sectionIndex: number) => {
            this.buildSection(section, sectionIndex);
          }, (section: PrivacySection, sectionIndex: number) => sectionIndex.toString())

          // Bottom safe area spacer
          Blank().height(32);
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  // ─── Navigation Bar ───
  @Builder
  buildNavBar() {
    Row() {
      // Back button
      Text('\uE0D9')
        .fontSize(28)
        .fontColor('#1A1A1A')
        .padding({ left: 16, right: 12, top: 12, bottom: 12 })
        .onClick(() => {
          router.back();
        })

      // Title
      Text('隐私')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A1A')

      Blank()
    }
    .width('100%')
    .height(56)
    .backgroundColor('#FFFFFF')
    .border({
      width: { bottom: 0.5 },
      color: '#E5E5E5'
    })
  }

  // ─── Section Builder ───
  @Builder
  buildSection(section: PrivacySection, sectionIndex: number) {
    Column() {
      // Top spacer for section separation (not for first section)
      if (sectionIndex > 0) {
        Blank().height(16);
      }

      // Section header label
      Text(section.sectionTitle)
        .fontSize(13)
        .fontColor('#6D6D72')
        .padding({ left: 32, right: 16, top: 8, bottom: 6 })
        .width('100%')

      // Section container with white background and rounded corners
      Column() {
        ForEach(section.items, (item: PrivacyListItem, itemIndex: number) => {
          if (item.isToggle) {
            this.buildToggleItem(item, itemIndex, section.items.length);
          } else {
            this.buildNavItem(item, itemIndex, section.items.length);
          }
        }, (item: PrivacyListItem, itemIndex: number) => `${sectionIndex}_${itemIndex}`)
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 16, right: 16 })
    }
    .width('100%')
  }

  // ─── Navigation List Item (with chevron) ───
  @Builder
  buildNavItem(item: PrivacyListItem, itemIndex: number, totalItems: number) {
    Column() {
      Row() {
        Text(item.label)
          .fontSize(16)
          .fontColor('#1A1A1A')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        if (item.subtitle && item.subtitle.length > 0) {
          Text(item.subtitle)
            .fontSize(13)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ right: 6 })
        }

        // Chevron right arrow
        Text('\uE0E1')
          .fontSize(18)
          .fontColor('#C7C7CC')
      }
      .width('100%')
      .padding({
        left: 16,
        right: 12,
        top: 13,
        bottom: 13
      })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onNavItemClick(item);
      })

      // Divider between items (not after last)
      if (itemIndex < totalItems - 1) {
        Divider()
          .color('#E5E5E5')
          .width('100%')
          .margin({ left: 16 })
      }
    }
    .width('100%')
  }

  // ─── Toggle List Item ───
  @Builder
  buildToggleItem(item: PrivacyListItem, itemIndex: number, totalItems: number) {
    Column() {
      Row() {
        Text(item.label)
          .fontSize(16)
          .fontColor('#1A1A1A')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.ipLocationToggle })
          .onChange((isOn: boolean) => {
            this.ipLocationToggle = isOn;
          })
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 13,
        bottom: 13
      })
      .alignItems(VerticalAlign.Center)

      // Divider between items (not after last)
      if (itemIndex < totalItems - 1) {
        Divider()
          .color('#E5E5E5')
          .width('100%')
          .margin({ left: 16 })
      }
    }
    .width('100%')
  }

  // ─── Navigation Item Click Handler ───
  private onNavItemClick(item: PrivacyListItem): void {
    if (item.route && item.route.length > 0) {
      router.pushUrl({ url: item.route });
    } else {
      console.info(`隐私设置项 "${item.label}" 被点击，暂无目标路由`);
    }
  }
}
