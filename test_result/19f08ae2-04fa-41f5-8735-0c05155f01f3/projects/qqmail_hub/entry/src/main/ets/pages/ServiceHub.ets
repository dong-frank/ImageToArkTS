import router from '@ohos.router';

// ─── Data Models ──────────────────────────────────────────────

class QuickActionItem {
  icon: string = ''
  text: string = ''
  route?: string
  action?: () => void
}

class SectionItem {
  icon: string = ''
  text: string = ''
  badge?: string
  redDot?: boolean
  route?: string
  action?: () => void
}

class SectionGroup {
  header: string = ''
  items: SectionItem[] = []
}

// ─── Component ────────────────────────────────────────────────

@Entry
@Component
struct ServiceHub {
  @State showOverlay: boolean = false

  navigateTo(route: string) {
    router.pushUrl({ url: route })
  }

  // ── Quick-action overlay items ────────────────────────────
  getQuickActions(): QuickActionItem[] {
    return [
      { icon: '✏️', text: '写邮件', route: 'pages/MailCompose' } as QuickActionItem,
      { icon: '📝', text: '写记事', action: () => { this.showOverlay = false } } as QuickActionItem,
      { icon: '📷', text: '扫一扫', action: () => { this.showOverlay = false } } as QuickActionItem,
      { icon: '⚙️', text: '设置', route: 'pages/SettingsRoot' } as QuickActionItem
    ]
  }

  // ── Section data ──────────────────────────────────────────
  getMailSection(): SectionGroup {
    return {
      header: '我的邮件',
      items: [
        { icon: '📥', text: '收件箱', badge: '360', route: 'pages/EmailInbox' } as SectionItem,
        { icon: '🔖', text: '重要联系人', route: 'pages/ImportantContacts' } as SectionItem,
        { icon: '⭐', text: '星标邮件', action: () => {} } as SectionItem
      ]
    }
  }

  getAppSection(): SectionGroup {
    return {
      header: '我的应用',
      items: [
        { icon: '☁️', text: '文件云盘', redDot: true, action: () => {} } as SectionItem,
        { icon: '🧾', text: '发票', redDot: true, route: 'pages/InvoiceSetup' } as SectionItem,
        { icon: '👤', text: '通讯录', action: () => {} } as SectionItem,
        { icon: '📎', text: '附件管理', action: () => {} } as SectionItem,
        { icon: '📖', text: '每日悦读', redDot: true, action: () => {} } as SectionItem,
        { icon: '📓', text: '记事本', action: () => {} } as SectionItem,
        { icon: '📅', text: '日历', badge: '25', action: () => {} } as SectionItem,
        { icon: '⊞', text: '更多应用', action: () => {} } as SectionItem
      ]
    }
  }

  getFolderSection(): SectionGroup {
    return {
      header: '文件夹',
      items: [
        { icon: '📤', text: '已发送', action: () => {} } as SectionItem,
        { icon: '📝', text: '草稿箱', action: () => {} } as SectionItem,
        { icon: '🗑️', text: '已删除', action: () => {} } as SectionItem,
        { icon: '🗑️', text: '垃圾箱', badge: '1', action: () => {} } as SectionItem,
        { icon: '📁', text: '群邮件', action: () => {} } as SectionItem,
        { icon: '📁', text: 'QQ邮件订阅', action: () => {} } as SectionItem,
        { icon: '📁', text: 'dear', action: () => {} } as SectionItem,
        { icon: '📦', text: '邮件归档', badge: '69', action: () => {} } as SectionItem,
        { icon: '📁', text: '招商银行信用卡', badge: '395', action: () => {} } as SectionItem
      ]
    }
  }

  // ── Handlers ──────────────────────────────────────────────
  handleQuickAction(item: QuickActionItem) {
    this.showOverlay = false
    if (item.route) {
      this.navigateTo(item.route)
    } else if (item.action) {
      item.action()
    }
  }

  handleSectionItemTap(item: SectionItem) {
    if (item.route) {
      this.navigateTo(item.route)
    } else if (item.action) {
      item.action()
    }
  }

  // ── Sub-builders ──────────────────────────────────────────
  @Builder
  buildHeaderBlock() {
    Column() {
      Row() {
        // Avatar
        Text('👤')
          .fontSize(28)
          .width(48)
          .height(48)
          .borderRadius(24)
          .backgroundColor('#D0D0D0')
          .textAlign(TextAlign.Center)

        // Name + badge + email
        Column() {
          Row({ space: 6 }) {
            Text('蒋')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A1A')

            Text('未开通')
              .fontSize(10)
              .fontColor('#999999')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(4)
              .backgroundColor('#EEEEEE')
          }

          Text('9434@qq.com')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })

        Blank()

        // "+" FAB
        Text('+')
          .fontSize(28)
          .fontColor('#333333')
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.showOverlay = !this.showOverlay
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // "会员中心 >" link
      Row() {
        Text('会员中心 >')
          .fontSize(14)
          .fontColor('#007AFF')
          .onClick(() => {
            this.navigateTo('pages/VipBenefits')
          })
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 8 })
  }

  @Builder
  buildSectionHeader(header: string) {
    Text(header)
      .fontSize(13)
      .fontColor('#888888')
      .fontWeight(FontWeight.Medium)
      .padding({ left: 16, right: 16, top: 16, bottom: 6 })
      .width('100%')
  }

  @Builder
  buildListItem(item: SectionItem) {
    Row() {
      Text(item.icon)
        .fontSize(20)
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)

      Text(item.text)
        .fontSize(16)
        .fontColor('#1A1A1A')
        .margin({ left: 10 })

      Blank()

      if (item.redDot) {
        Text('●')
          .fontSize(10)
          .fontColor('#FF3B30')
          .margin({ right: 4 })
      }

      if (item.badge && item.badge.length > 0) {
        Text(item.badge)
          .fontSize(11)
          .fontColor('#FFFFFF')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(8)
          .backgroundColor('#FF3B30')
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      this.handleSectionItemTap(item)
    })
  }

  @Builder
  buildSectionBlock(section: SectionGroup) {
    Column() {
      this.buildSectionHeader(section.header)

      Column() {
        ForEach(section.items, (item: SectionItem) => {
          this.buildListItem(item)
        }, (item: SectionItem) => item.text)
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
  }

  // ── Main build ────────────────────────────────────────────
  build() {
    Stack() {
      // ── Background page content ──────────────────────────
      Column() {
        // Fixed header area
        this.buildHeaderBlock()

        Divider()
          .height(1)
          .color('#F0F0F0')
          .margin({ left: 16, right: 16 })

        // Scrollable sections
        Scroll() {
          Column({ space: 4 }) {
            this.buildSectionBlock(this.getMailSection())
            this.buildSectionBlock(this.getAppSection())
            this.buildSectionBlock(this.getFolderSection())
          }
          .width('100%')
          .margin({ top: 4 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F2F2F7')

      // ── Overlay backdrop (tappable to dismiss) ───────────
      if (this.showOverlay) {
        Column() {
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000000')
        .onClick(() => {
          this.showOverlay = false
        })
      }

      // ── Overlay menu panel (above backdrop) ───────────────
      if (this.showOverlay) {
        Column() {
          Column() {
            ForEach(this.getQuickActions(), (item: QuickActionItem) => {
              Row() {
                Text(item.icon)
                  .fontSize(18)
                  .margin({ right: 10 })

                Text(item.text)
                  .fontSize(15)
                  .fontColor('#1A1A1A')

                Blank()

                if (item.route) {
                  Text('›')
                    .fontSize(16)
                    .fontColor('#CCCCCC')
                }
              }
              .width('100%')
              .height(44)
              .padding({ left: 14, right: 14 })
              .onClick(() => {
                this.handleQuickAction(item)
              })
            }, (item: QuickActionItem) => item.text)
          }
          .width(150)
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .shadow({
            radius: 16,
            color: '#33000000',
            offsetX: 0,
            offsetY: 4
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.End)
        .padding({ right: 12, top: 8 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
