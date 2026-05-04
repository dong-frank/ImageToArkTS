/**
 * ServiceHubPage - QQ Mail main sidebar / service hub
 * Merged from: Draft 1 (partial/raw recovery), Draft 2 (success), Draft 4 (success, base)
 * Entry page of the app - shows user info, mail sections, app sections, folder sections
 * with popup menu triggered by '+' button
 */
import router from '@ohos.router';

interface MenuItem {
  icon: string;
  label: string;
  badge?: string;
  badgeType?: 'number' | 'dot';
}

interface PopupAction {
  icon: string;
  label: string;
  route?: string;
}

@Entry
@Component
struct ServiceHubPage {
  @State popupVisible: boolean = false;
  @State showOverlay: boolean = false;

  // User info
  readonly userName: string = '蒋';
  readonly userEmail: string = '9434@qq.com';
  readonly membershipStatus: string = '未开通';

  // 我的邮件 section
  readonly myMailItems: MenuItem[] = [
    { icon: '📧', label: '收件箱', badge: '360', badgeType: 'number' },
    { icon: '🔖', label: '重要联系人' },
    { icon: '⭐', label: '星标邮件' }
  ];

  // 我的应用 section
  readonly myAppsItems: MenuItem[] = [
    { icon: '☁️', label: '文件云盘', badge: '•', badgeType: 'dot' },
    { icon: '🧾', label: '发票', badge: '•', badgeType: 'dot' },
    { icon: '👤', label: '通讯录' },
    { icon: '📎', label: '附件管理' },
    { icon: '📖', label: '每日悦读', badge: '•', badgeType: 'dot' },
    { icon: '📝', label: '记事本' },
    { icon: '📅', label: '日历', badge: '25', badgeType: 'number' },
    { icon: '⋯', label: '更多应用' }
  ];

  // 文件夹 section
  readonly folderItems: MenuItem[] = [
    { icon: '📤', label: '已发送' },
    { icon: '📋', label: '草稿箱' },
    { icon: '🗑️', label: '垃圾箱' },
    { icon: '📦', label: '邮件归档' }
  ];

  // Popup menu actions
  readonly popupActions: PopupAction[] = [
    { icon: '✏️', label: '写邮件', route: 'pages/ComposeMailPage' },
    { icon: '📝', label: '写记事' },
    { icon: '📷', label: '扫一扫' },
    { icon: '⚙️', label: '设置', route: 'pages/SettingsPage' }
  ];

  handleItemTap(item: MenuItem): void {
    if (item.label === '收件箱') {
      router.pushUrl({ url: 'pages/InboxListPage' });
    } else if (item.label === '重要联系人') {
      router.pushUrl({ url: 'pages/ImportantContactsPage' });
    } else if (item.label === '文件云盘') {
      router.pushUrl({ url: 'pages/InvoiceOnboardingPage' });
    } else if (item.label === '应用设置' || item.label === '更多应用') {
      router.pushUrl({ url: 'pages/AppSettingsPage' });
    }
    // Other items: placeholder - would navigate to respective pages
  }

  handlePopupAction(action: PopupAction): void {
    this.popupVisible = false;
    if (action.route) {
      router.pushUrl({ url: action.route });
    }
  }

  handleMemberCenterTap(): void {
    router.pushUrl({ url: 'pages/VipBenefitsPage' });
  }

  build() {
    Stack() {
      Column() {
        // Header with user info
        Column() {
          Row() {
            // Avatar + user info
            Row() {
              // Avatar placeholder circle
              Text('蒋')
                .width(44)
                .height(44)
                .borderRadius(22)
                .backgroundColor('#4A90D9')
                .fontSize(18)
                .fontColor('#FFFFFF')
                .textAlign(TextAlign.Center)
            }
            .margin({ right: 10 })

            Column() {
              Row() {
                Text(this.userName)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1A1A1A')
                Text(this.membershipStatus)
                  .fontSize(11)
                  .fontColor('#999999')
                  .backgroundColor('#F0F0F0')
                  .borderRadius(4)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .margin({ left: 6 })
              }
              Text(this.userEmail)
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            // 会员中心 link
            Text('会员中心 >')
              .fontSize(12)
              .fontColor('#4A90D9')
              .onClick(() => { this.handleMemberCenterTap(); })

            // '+' button
            Text('+')
              .fontSize(22)
              .fontColor('#333333')
              .width(32)
              .height(32)
              .textAlign(TextAlign.Center)
              .margin({ left: 10 })
              .onClick(() => { this.popupVisible = !this.popupVisible; })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        }
        .width('100%')

        Divider()
          .height(1)
          .color('#F0F0F0')

        // Scrollable content
        Scroll() {
          Column() {
            // 我的邮件 section
            this.buildSection('我的邮件', this.myMailItems)

            // 我的应用 section
            this.buildSection('我的应用', this.myAppsItems)

            // 文件夹 section
            this.buildSection('文件夹', this.folderItems)

            // Bottom spacing
            Column().height(20)
          }
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // Popup overlay
      if (this.popupVisible) {
        Column() {
          Column() {
            ForEach(this.popupActions, (action: PopupAction, index: number) => {
              Row() {
                Text(action.icon)
                  .fontSize(16)
                  .margin({ right: 8 })
                Text(action.label)
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .onClick(() => { this.handlePopupAction(action); })
              if (index < this.popupActions.length - 1) {
                Divider()
                  .height(0.5)
                  .color('#E8E8E8')
              }
            })
          }
          .width(140)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 8, color: '#00000020', offsetX: 0, offsetY: 2 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000000')
        .alignItems(HorizontalAlign.End)
        .justifyContent(FlexAlign.Start)
        .padding({ top: 80, right: 12 })
        .onClick(() => { this.popupVisible = false; })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildSection(title: string, items: MenuItem[]) {
    Column() {
      // Section header
      Text(title)
        .fontSize(13)
        .fontColor('#888888')
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      Column() {
        ForEach(items, (item: MenuItem, index: number) => {
          this.buildMenuItem(item)
          if (index < items.length - 1) {
            Divider()
              .height(0.5)
              .color('#F0F0F0')
              .margin({ left: 48 })
          }
        })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .margin({ left: 12, right: 12 })
    }
  }

  @Builder
  buildMenuItem(item: MenuItem) {
    Row() {
      Text(item.icon)
        .fontSize(18)
        .width(32)
        .textAlign(TextAlign.Center)

      Text(item.label)
        .fontSize(15)
        .fontColor('#1A1A1A')
        .layoutWeight(1)

      if (item.badge) {
        if (item.badgeType === 'dot') {
          Text('')
            .width(8)
            .height(8)
            .borderRadius(4)
            .backgroundColor('#FF3B30')
            .margin({ right: 8 })
        } else {
          Text(item.badge)
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor('#4A90D9')
            .borderRadius(9)
            .padding({ left: 7, right: 7, top: 2, bottom: 2 })
            .margin({ right: 8 })
        }
      }

      Text('>')
        .fontSize(14)
        .fontColor('#C0C0C0')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .onClick(() => { this.handleItemTap(item); })
  }
}
