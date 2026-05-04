/**
 * GeneralSettingsPage - General settings
 * Based on: Draft 14 (partial, raw recovery - rich structure)
 */
import router from '@ohos.router';

interface GeneralSettingItem {
  type: 'navigate' | 'switch';
  label: string;
  detailText?: string;
  switchState?: boolean;
  route?: string;
}

@Entry
@Component
struct GeneralSettingsPage {
  readonly settings: GeneralSettingItem[] = [
    { type: 'navigate', label: '首页管理', route: '' },
    { type: 'navigate', label: '应用设置', route: 'pages/AppSettingsPage' },
    { type: 'switch', label: '发信音效', switchState: true },
    { type: 'switch', label: '邮件列表头像', switchState: true },
    { type: 'navigate', label: '文字大小', detailText: '跟随系统' },
    { type: 'navigate', label: '加载邮件图片', detailText: '所有网络' },
    { type: 'navigate', label: '语言' }
  ];

  handleBackTap(): void {
    router.back();
  }

  handleItemTap(item: GeneralSettingItem): void {
    if (item.route && item.route.length > 0) {
      router.pushUrl({ url: item.route });
    }
  }

  @Builder
  buildSwitchItem(item: GeneralSettingItem) {
    Row() {
      Text(item.label)
        .fontSize(16).fontColor('#1A1A1A').layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: item.switchState ?? false })
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 10 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildNavItem(item: GeneralSettingItem) {
    Row() {
      Text(item.label)
        .fontSize(16).fontColor('#1A1A1A').layoutWeight(1)

      if (item.detailText) {
        Text(item.detailText)
          .fontSize(14).fontColor('#999999').margin({ right: 4 })
      }

      Text('>')
        .fontSize(16).fontColor('#C0C0C0')
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 10 })
    .backgroundColor('#FFFFFF')
    .onClick(() => { this.handleItemTap(item); })
  }

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('<')
          .fontSize(20).fontColor('#4A90D9')
          .width(40).height(40).textAlign(TextAlign.Center)
          .onClick(() => { this.handleBackTap(); })

        Text('通用')
          .fontSize(17).fontWeight(FontWeight.Medium).fontColor('#1A1A1A')
          .layoutWeight(1).textAlign(TextAlign.Center)

        Column().width(40)
      }
      .width('100%').height(48).backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // Section 1: Navigation items
          Column() {
            this.buildNavItem(this.settings[0])
            Divider().height(0.5).color('#F0F0F0').margin({ left: 16 })
            this.buildNavItem(this.settings[1])
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 12, right: 12, top: 12 })

          // Section 2: Switches + nav items
          Column() {
            this.buildSwitchItem(this.settings[2])
            Divider().height(0.5).color('#F0F0F0').margin({ left: 16 })
            this.buildSwitchItem(this.settings[3])
            Divider().height(0.5).color('#F0F0F0').margin({ left: 16 })
            this.buildNavItem(this.settings[4])
            Divider().height(0.5).color('#F0F0F0').margin({ left: 16 })
            this.buildNavItem(this.settings[5])
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 12, right: 12, top: 12 })

          // Section 3: Language
          Column() {
            this.buildNavItem(this.settings[6])
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 12, right: 12, top: 12 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%').height('100%')
  }
}
