import router from '@ohos.router';

interface PermissionItemData {
  label: string;
  hasToggle: boolean;
  toggleOn: boolean;
  hasDescription: boolean;
  description: string;
  hasChevron: boolean;
}

@Entry
@Component
struct FriendPermissionPage {
  @State private isVerifyEnabled: boolean = true;
  @State private isRecommendEnabled: boolean = false;

  // Top section: 加好友设置
  private topSectionItems: PermissionItemData[] = [
    {
      label: '加我为朋友时需要验证',
      hasToggle: true,
      toggleOn: true,
      hasDescription: false,
      description: '',
      hasChevron: false
    },
    {
      label: '添加我的方式',
      hasToggle: false,
      toggleOn: false,
      hasDescription: false,
      description: '',
      hasChevron: true
    },
    {
      label: '向我推荐通讯录朋友',
      hasToggle: true,
      toggleOn: false,
      hasDescription: true,
      description: '开启后，在「通讯录 > 新的朋友」为你推荐已经注册账号的手机联系人。',
      hasChevron: false
    }
  ];

  // Bottom section: 朋友权限
  private permissionItems: PermissionItemData[] = [
    { label: '仅聊天', hasToggle: false, toggleOn: false, hasDescription: false, description: '', hasChevron: true },
    { label: '朋友圈', hasToggle: false, toggleOn: false, hasDescription: false, description: '', hasChevron: true },
    { label: '视频号', hasToggle: false, toggleOn: false, hasDescription: false, description: '', hasChevron: true },
    { label: '看一看', hasToggle: false, toggleOn: false, hasDescription: false, description: '', hasChevron: true },
    { label: '微信运动', hasToggle: false, toggleOn: false, hasDescription: false, description: '', hasChevron: true },
    { label: '通讯录黑名单', hasToggle: false, toggleOn: false, hasDescription: false, description: '', hasChevron: true }
  ];

  onBackTap(): void {
    router.back();
  }

  onChevronItemTap(item: PermissionItemData): void {
    // Child pages for these targets are outside the current 22-page scope.
    // Log the navigation intent; real routes would be wired when target pages exist.
    console.info(`[FriendPermissionPage] navigate to: ${item.label}`);
  }

  @Builder
  NavBar() {
    Row() {
      // Back button
      Text('←')
        .fontSize(22)
        .fontColor('#333333')
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.onBackTap();
        })

      // Title
      Text('朋友权限')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#191919')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // Spacer for symmetry
      Row()
        .width(44)
        .height(44)
    }
    .width('100%')
    .height(48)
    .padding({ left: 4, right: 4 })
    .backgroundColor('#EDEDED')
  }

  @Builder
  ToggleRow(item: PermissionItemData, isOn: boolean, onChange: (isOn: boolean) => void) {
    Column() {
      Row() {
        // Label
        Text(item.label)
          .fontSize(16)
          .fontColor('#191919')
          .layoutWeight(1)

        // Toggle switch
        Toggle({ type: ToggleType.Switch, isOn: isOn })
          .selectedColor('#07C160')
          .onChange((value: boolean) => {
            onChange(value);
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      // Description text
      if (item.hasDescription && item.description.length > 0) {
        Text(item.description)
          .fontSize(13)
          .fontColor('#999999')
          .lineHeight(20)
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 12 })
      }
    }
    .width('100%')
  }

  @Builder
  ChevronRow(item: PermissionItemData) {
    Row() {
      Text(item.label)
        .fontSize(16)
        .fontColor('#191919')

      Blank()

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
      this.onChevronItemTap(item);
    })
  }

  @Builder
  ItemDivider() {
    Divider()
      .strokeWidth(0.5)
      .color('#E5E5E5')
      .margin({ left: 16 })
  }

  @Builder
  SectionGap() {
    Row()
      .width('100%')
      .height(8)
      .backgroundColor('#F5F5F5')
  }

  build() {
    Column() {
      // ── Navigation Bar ──
      this.NavBar()

      // ── Scrollable Content ──
      Scroll() {
        Column() {
          // ── Top Section: 加好友设置 ──
          Column() {
            // Item 0: 加我为朋友时需要验证 (Toggle ON)
            this.ToggleRow(this.topSectionItems[0], this.isVerifyEnabled, (isOn: boolean) => {
              this.isVerifyEnabled = isOn;
            })

            this.ItemDivider()

            // Item 1: 添加我的方式 (Chevron)
            this.ChevronRow(this.topSectionItems[1])

            this.ItemDivider()

            // Item 2: 向我推荐通讯录朋友 (Toggle OFF + description)
            this.ToggleRow(this.topSectionItems[2], this.isRecommendEnabled, (isOn: boolean) => {
              this.isRecommendEnabled = isOn;
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 12 })

          // ── Section Header: 朋友权限 ──
          Row() {
            Text('朋友权限')
              .fontSize(13)
              .fontColor('#999999')
              .padding({ left: 16 })
          }
          .width('100%')
          .height(32)
          .alignItems(VerticalAlign.Center)

          // ── Bottom Section: 朋友权限 list ──
          Column() {
            ForEach(this.permissionItems, (item: PermissionItemData, index: number) => {
              this.ChevronRow(item)
              if (index < this.permissionItems.length - 1) {
                this.ItemDivider()
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          // Bottom safe padding
          Row()
            .width('100%')
            .height(32)
            .backgroundColor('#F5F5F5')
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

export default FriendPermissionPage;
