import router from '@ohos.router';

// --- Data model for settings list items ---
interface SettingsItem {
  label: string;
  trailingText?: string;
  hasChevron: boolean;
  route?: string;
  targetHint?: string;
}

interface SettingsSection {
  sectionLabel: string;
  items: SettingsItem[];
}

@Entry
@Component
struct SettingsRoot {
  @State sections: SettingsSection[] = [
    {
      sectionLabel: '新邮件提醒',
      items: [
        { label: '通用', hasChevron: true, route: 'pages/SettingsGeneral' },
        { label: '邮件', hasChevron: true, targetHint: '邮件设置页' },
        { label: '储存', hasChevron: true, targetHint: '储存管理页' }
      ]
    },
    {
      sectionLabel: '个人信息与权限',
      items: [
        { label: '个人信息收集清单', hasChevron: true, targetHint: '隐私清单页' },
        { label: '第三方共享个人信息清单', hasChevron: true, targetHint: '第三方共享清单页' },
        { label: '手势密码与面容识别', trailingText: '关闭', hasChevron: true, targetHint: '生物认证设置页' }
      ]
    },
    {
      sectionLabel: '帮助与反馈',
      items: [
        { label: '关于', hasChevron: true, targetHint: '关于页' }
      ]
    }
  ];

  handleClose() {
    router.back();
  }

  handleAccountDetail() {
    console.info('[SettingsRoot] 账户详情页 — 目标页未覆盖');
  }

  handleUpgrade() {
    console.info('[SettingsRoot] 升级按钮 → 会员开通/升级流程 — 目标页未覆盖');
  }

  handleAddAccount() {
    console.info('[SettingsRoot] 添加账号 — 目标页未覆盖');
  }

  handleItemTap(item: SettingsItem) {
    if (item.route) {
      router.pushUrl({ url: item.route });
    } else {
      console.info(`[SettingsRoot] ${item.label} → ${item.targetHint || '目标页未覆盖'}`);
    }
  }

  @Builder
  buildHeader() {
    Row() {
      Text('关闭')
        .fontSize(16)
        .fontColor('#333333')
        .onClick(() => { this.handleClose(); })

      Blank()

      Text('设置')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1a1a1a')

      Blank()

      Text('关闭')
        .fontSize(16)
        .fontColor(Color.Transparent)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#ffffff')
  }

  @Builder
  buildAccountSection() {
    Column() {
      Row() {
        Circle()
          .width(48)
          .height(48)
          .fill('#e0e0ff')

        Column() {
          Text('蒋')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1a1a1a')
          Text('1434@qq.com')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })

        Blank()

        Button('升级')
          .fontSize(12)
          .fontColor('#7b61ff')
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: '#7b61ff', radius: 12, style: BorderStyle.Solid })
          .height(28)
          .padding({ left: 12, right: 12 })
          .onClick(() => { this.handleUpgrade(); })

        Text('>')
          .fontSize(16)
          .fontColor('#cccccc')
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .onClick(() => { this.handleAccountDetail(); })

      Divider()
        .strokeWidth(0.5)
        .color('#eeeeee')
        .margin({ left: 16 })

      Row() {
        Text('+')
          .fontSize(20)
          .fontColor('#7b61ff')
          .width(24)
          .height(24)
          .textAlign(TextAlign.Center)

        Text('添加账号')
          .fontSize(15)
          .fontColor('#333333')
          .margin({ left: 10 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .onClick(() => { this.handleAddAccount(); })
    }
    .width('100%')
    .backgroundColor('#ffffff')
  }

  @Builder
  buildSectionHeader(label: string) {
    Text(label)
      .fontSize(13)
      .fontColor('#999999')
      .padding({ left: 16, top: 24, bottom: 8 })
      .width('100%')
      .backgroundColor('#f5f5f5')
      .onClick(() => {
        if (label === '新邮件提醒') {
          router.pushUrl({ url: 'pages/NotificationNewMail' });
        }
      })
  }

  @Builder
  buildListItem(item: SettingsItem) {
    Row() {
      Text(item.label)
        .fontSize(15)
        .fontColor('#333333')

      Blank()

      if (item.trailingText) {
        Text(item.trailingText)
          .fontSize(13)
          .fontColor('#999999')
          .margin({ right: 6 })
      }

      if (item.hasChevron) {
        Text('>')
          .fontSize(16)
          .fontColor('#cccccc')
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#ffffff')
    .onClick(() => { this.handleItemTap(item); })
  }

  @Builder
  buildSection(section: SettingsSection) {
    Column() {
      this.buildSectionHeader(section.sectionLabel)

      ForEach(section.items, (item: SettingsItem, index: number) => {
        Column() {
          this.buildListItem(item)
          if (index < section.items.length - 1) {
            Divider()
              .strokeWidth(0.5)
              .color('#f0f0f0')
              .margin({ left: 16 })
          }
        }
      })
    }
    .width('100%')
  }

  build() {
    Column() {
      this.buildHeader()

      Scroll() {
        Column() {
          this.buildAccountSection()

          Divider()
            .strokeWidth(8)
            .color('#f5f5f5')

          ForEach(this.sections, (section: SettingsSection) => {
            this.buildSection(section)
          })

          Column()
            .height(40)
            .width('100%')
            .backgroundColor('#f5f5f5')
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#f5f5f5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
