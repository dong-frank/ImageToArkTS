/**
 * SettingsPage - QQ Mail settings root page
 * Based on: Draft 6 (partial, raw recovery - rich structure)
 */
import router from '@ohos.router';

interface SettingItem {
  text: string;
  trailingText?: string;
  hasChevron: boolean;
  route?: string;
}

interface SettingSection {
  title: string;
  items: SettingItem[];
}

@Entry
@Component
struct SettingsPage {
  readonly sections: SettingSection[] = [
    {
      title: '',
      items: [
        { text: '新邮件提醒', hasChevron: true, route: 'pages/NotificationSettingsPage' }
      ]
    },
    {
      title: '通用',
      items: [
        { text: '通用', hasChevron: true, route: 'pages/GeneralSettingsPage' },
        { text: '邮件', hasChevron: true },
        { text: '储存', hasChevron: true }
      ]
    },
    {
      title: '个人信息与权限',
      items: [
        { text: '个人信息与权限', hasChevron: true },
        { text: '个人信息收集清单', hasChevron: true },
        { text: '第三方共享个人信息清单', hasChevron: true },
        { text: '手势密码与面容识别', trailingText: '关闭', hasChevron: true }
      ]
    },
    {
      title: '帮助与反馈',
      items: [
        { text: '帮助与反馈', hasChevron: true },
        { text: '关于', hasChevron: true }
      ]
    }
  ];

  readonly userName: string = '蒋';
  readonly userEmail: string = '1434@qq.com';

  handleClose(): void {
    router.back();
  }

  handleItemTap(item: SettingItem): void {
    if (item.route) {
      router.pushUrl({ url: item.route });
    }
  }

  handleUpgradeTap(): void {
    // Navigate to VIP page
    router.pushUrl({ url: 'pages/VipBenefitsPage' });
  }

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('关闭')
          .fontSize(16)
          .fontColor('#4A90D9')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .onClick(() => { this.handleClose(); })

        Text('设置')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Column().width(60)
      }
      .width('100%')
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // Account section
          Column() {
            // Current account
            Row() {
              Text(this.userName)
                .fontColor('#FFFFFF')
                .width(52)
                .height(52)
                .borderRadius(26)
                .backgroundColor('#4A90D9')
                .textAlign(TextAlign.Center)
                .fontSize(20)
                .margin({ right: 12 })

              Column() {
                Text(this.userName)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1A1A1A')
                Text(this.userEmail)
                  .fontSize(12)
                  .fontColor('#999999')
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              Text('升级')
                .fontSize(13)
                .fontColor('#7B3FF2')
                .border({ width: 1, color: '#7B3FF2', style: BorderStyle.Solid })
                .borderRadius(12)
                .padding({ left: 10, right: 10, top: 3, bottom: 3 })
                .margin({ right: 6 })
                .onClick(() => { this.handleUpgradeTap(); })

              Text('>')
                .fontSize(16)
                .fontColor('#C0C0C0')
            }
            .width('100%')
            .padding({ left: 16, right: 10, top: 14, bottom: 14 })

            Divider()
              .height(0.5)
              .color('#E8E8E8')

            // Add account
            Row() {
              Text('+')
                .fontSize(18)
                .fontColor('#4A90D9')
                .width(24)
                .height(24)
                .textAlign(TextAlign.Center)
                .margin({ right: 10 })

              Text('添加账号')
                .fontSize(15)
                .fontColor('#4A90D9')
                .layoutWeight(1)

              Text('>')
                .fontSize(16)
                .fontColor('#C0C0C0')
            }
            .width('100%')
            .padding({ left: 16, right: 10, top: 12, bottom: 12 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 12, right: 12, top: 12 })

          // Setting sections
          ForEach(this.sections, (section: SettingSection, sIndex: number) => {
            Column() {
              if (section.title) {
                Text(section.title)
                  .fontSize(12)
                  .fontColor('#888888')
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 16, bottom: 6 })
              }
              Column() {
                ForEach(section.items, (item: SettingItem, iIndex: number) => {
                  this.buildSettingItem(item)
                  if (iIndex < section.items.length - 1) {
                    Divider()
                      .height(0.5)
                      .color('#F0F0F0')
                      .margin({ left: 16 })
                  }
                })
              }
              .width('100%')
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 8 })
          })

          Column().height(30)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildSettingItem(item: SettingItem) {
    Row() {
      Text(item.text)
        .fontSize(16)
        .fontColor('#1A1A1A')
        .layoutWeight(1)

      if (item.trailingText) {
        Text(item.trailingText)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ right: 4 })
      }

      if (item.hasChevron) {
        Text('>')
          .fontSize(16)
          .fontColor('#C0C0C0')
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 10 })
    .onClick(() => { this.handleItemTap(item); })
  }
}
