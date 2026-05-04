import router from '@ohos.router';

// Settings item data model
interface SettingsItemData {
  label: string;
  subtitle?: string;
  trailingText?: string;
  badge?: string;
  route?: string;
  isDanger?: boolean;
}

@Entry
@Component
struct SettingsRoot {
  // Group 1: 账户与安全
  private accountGroup: SettingsItemData[] = [
    { label: '个人资料', route: '' },
    { label: '账号与安全', route: 'pages/AccountSecurity' },
    { label: '消息通知设置', route: 'pages/NotificationSettings' },
    { label: '隐私管理', route: 'pages/PrivacyManagement' }
  ];

  // Group 2: 通用
  private generalGroup: SettingsItemData[] = [
    { label: '通用', route: 'pages/GeneralSettings' },
    { label: '长辈版', subtitle: '字大看得清，使用更简单', trailingText: '未开启', route: '' },
    { label: '未成年人模式', badge: '新功能', trailingText: '未开启', route: '' },
    { label: '多语言', route: 'pages/LanguageSettings' },
    { label: '存储空间', badge: '新功能', trailingText: '1.2 GB', route: 'pages/StorageSpace' },
    { label: '诊断网络', route: '' }
  ];

  // Group 3: 隐私与协议
  private privacyGroup: SettingsItemData[] = [
    { label: '隐私政策', route: 'pages/PrivacyPolicyDetail' },
    { label: '个人信息收集清单', route: '' },
    { label: '第三方信息数据共享', route: 'pages/ThirdPartySdkList' },
    { label: '意见反馈', route: 'pages/FeedbackForm' }
  ];

  // Group 4: 其他
  private otherGroup: SettingsItemData[] = [
    { label: '关于我们', route: 'pages/AboutUs' },
    { label: '热线电话', trailingText: '10100011', route: '' }
  ];

  // Unresolved items that should not create real routes
  private unresolvedLabels: Set<string> = new Set([
    '个人资料',
    '长辈版',
    '未成年人模式',
    '个人信息收集清单',
    '诊断网络'
  ]);

  handleItemTap(item: SettingsItemData): void {
    // Hotline - system dial action, not page navigation
    if (item.label === '热线电话') {
      console.info('热线电话 tapped - would trigger system dialer for 10100011');
      return;
    }

    // Logout - global state change, not simple page navigation
    if (item.label === '退出登录') {
      console.info('退出登录 tapped - would trigger logout flow and navigate to login page');
      return;
    }

    // Confirmed routes
    if (item.route && item.route.length > 0) {
      router.pushUrl({ url: item.route });
      return;
    }

    // Unresolved items - log and keep as placeholder
    if (this.unresolvedLabels.has(item.label)) {
      console.info(`${item.label} tapped - target page not yet available`);
      return;
    }
  }

  @Builder
  SectionHeader(text: string) {
    Text(text)
      .fontSize(13)
      .fontColor('#999999')
      .padding({ left: 16, top: 16, bottom: 8 })
      .width('100%')
  }

  @Builder
  SettingsRow(item: SettingsItemData) {
    Row() {
      // Left: label + optional badge
      Row({ space: 6 }) {
        Text(item.label)
          .fontSize(16)
          .fontColor('#333333')

        if (item.badge) {
          Text(item.badge)
            .fontSize(10)
            .fontColor('#FF4D4F')
            .backgroundColor('#FFF0F0')
            .borderRadius(4)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
        }
      }

      Blank()

      // Right: subtitle/trailing text + chevron
      Row({ space: 4 }) {
        if (item.subtitle) {
          Text(item.subtitle)
            .fontSize(13)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: 120 })
        }

        if (item.trailingText) {
          Text(item.trailingText)
            .fontSize(13)
            .fontColor('#999999')
        }

        Text('>')
          .fontSize(14)
          .fontColor('#CCCCCC')
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.handleItemTap(item);
    })
  }

  @Builder
  DividerLine() {
    Divider()
      .strokeWidth(0.5)
      .color('#F0F0F0')
      .margin({ left: 16 })
  }

  @Builder
  SettingsGroup(group: SettingsItemData[], sectionTitle?: string) {
    Column() {
      if (sectionTitle) {
        this.SectionHeader(sectionTitle)
      }

      Column() {
        ForEach(group, (item: SettingsItemData, index: number) => {
          Column() {
            this.SettingsRow(item)
            if (index < group.length - 1) {
              this.DividerLine()
            }
          }
        })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
  }

  @Builder
  LogoutButton() {
    Text('退出登录')
      .fontSize(16)
      .fontColor('#FF4D4F')
      .width('100%')
      .height(48)
      .textAlign(TextAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .onClick(() => {
        this.handleItemTap({ label: '退出登录', isDanger: true });
      })
  }

  build() {
    Column() {
      // ===== Navigation Bar =====
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.back();
          })

        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()
      }
      .width('100%')
      .height(44)
      .padding({ left: 4, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')

      // ===== Scrollable Settings List =====
      Scroll() {
        Column() {
          // Group 1: 账户与安全 (no section header)
          this.SettingsGroup(this.accountGroup)

          // Group 2: 通用
          this.SettingsGroup(this.generalGroup, '通用')

          // Group 3: 隐私与协议
          this.SettingsGroup(this.privacyGroup, '隐私与协议')

          // Group 4: 其他
          this.SettingsGroup(this.otherGroup, '其他')

          // Logout button
          Column() {
            this.LogoutButton()
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 16, bottom: 32 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
