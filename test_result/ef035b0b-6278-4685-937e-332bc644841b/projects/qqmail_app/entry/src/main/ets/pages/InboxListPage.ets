/**
 * InboxListPage - QQ Mail inbox list with folder drawer
 * Merged from: Draft 0 (success), Draft 10 (success, base), Draft 9 (partial/raw, drawer overlay)
 */
import router from '@ohos.router';

interface MailItem {
  senderIcon: string;
  senderName: string;
  senderSubtitle?: string;
  badge?: string;
  subject: string;
  preview: string;
  timestamp: string;
  unread: boolean;
}

interface FolderItem {
  icon: string;
  label: string;
  badge?: string;
  selected?: boolean;
}

@Entry
@Component
struct InboxListPage {
  @State activeTab: number = 0;
  @State showDrawer: boolean = false;
  @State selectedFolder: string = '收件箱';
  @State searchText: string = '';

  // Mail list from drafts 0 + 10
  readonly mailList: MailItem[] = [
    {
      senderIcon: '🏦',
      senderName: '招商银行信用卡',
      senderSubtitle: '每日信用管家',
      subject: '截至昨日最后一笔交易，您的额度和积分信息如下：',
      preview: '…30 … 可用…',
      timestamp: '12:11',
      unread: true
    },
    {
      senderIcon: '🤖',
      senderName: 'OpenAI',
      senderSubtitle: 'Introducing GPT-5.5',
      subject: 'A new class of intelligence for real work',
      preview: '',
      timestamp: '08:21',
      unread: true
    },
    {
      senderIcon: '🏦',
      senderName: '招商银行信用卡',
      senderSubtitle: '每日信用管家',
      subject: '截至昨日最后一笔交易，您的额度和积分信息如下：',
      preview: '…).58 … 可用…',
      timestamp: '昨天 12:08',
      unread: true
    },
    {
      senderIcon: '🏦',
      senderName: '招商银行信用卡',
      senderSubtitle: '每日信用管家',
      subject: '截至昨日最后一笔交易，您的额度和积分信息如下：',
      preview: '… 3.31 … 可用…',
      timestamp: '前天 12:08',
      unread: true
    },
    {
      senderIcon: '💳',
      senderName: '招商银行信用卡',
      senderSubtitle: '1544元露营车桌椅组合+50元还款金，推1人办...',
      subject: '',
      preview: '',
      timestamp: '4月22日',
      unread: true
    },
    {
      senderIcon: '🔄',
      senderName: 'OpenRouter, Inc',
      senderSubtitle: 'Your OpenRouter, Inc refund [#3480-9365]',
      subject: 'Refund from OpenRouter, Inc [#3480-9365]',
      preview: 'Refunded $30.00',
      timestamp: '4月22日',
      unread: true
    },
    {
      senderIcon: '🔄',
      senderName: 'OpenRouter, Inc',
      senderSubtitle: 'Your OpenRouter, Inc receipt [#1265-4960]',
      subject: 'Receipt from OpenRouter, Inc [#1265-4960]',
      preview: 'Amount paid $31.65',
      timestamp: '4月22日',
      unread: true
    },
    {
      senderIcon: '🔄',
      senderName: 'OpenRouter, Inc',
      senderSubtitle: 'Your OpenRouter, Inc receipt [#1335-1509]',
      subject: 'Receipt from OpenRouter, Inc [#1335-1509]',
      preview: 'Amount paid $10.80',
      timestamp: '4月22日',
      unread: true
    },
    {
      senderIcon: '📐',
      senderName: 'Overleaf',
      senderSubtitle: 'Overleaf Project Invite',
      subject: 'Association for Computing Machinery (ACM)...',
      preview: 'You have been invited to an Overleaf project.',
      timestamp: '前天 18:49',
      unread: true
    }
  ];

  // Drawer folder items from draft 9 raw data
  readonly folderItems: FolderItem[] = [
    { icon: '📥', label: '收件箱', badge: '357', selected: true },
    { icon: '⭐', label: '星标邮件' },
    { icon: '📤', label: '已发送' },
    { icon: '📋', label: '草稿箱' },
    { icon: '🗑️', label: '已删除' },
    { icon: '🚫', label: '垃圾箱', badge: '1' },
    { icon: '📩', label: '未读邮件', badge: '821' },
    { icon: '👥', label: '群邮件' },
    { icon: '🔖', label: '重要联系人' },
    { icon: '📬', label: 'QQ邮件订阅' },
    { icon: '📁', label: '邮件归档', badge: '69' },
    { icon: '⚙️', label: '管理' }
  ];

  readonly tabs: string[] = ['收件箱', '未读邮件', '管理'];

  handleBackTap(): void {
    router.back();
  }

  handleMailTap(item: MailItem): void {
    router.pushUrl({ url: 'pages/EmailDetailPage' });
  }

  handleDrawerToggle(): void {
    this.showDrawer = !this.showDrawer;
  }

  handleFolderTap(folder: FolderItem): void {
    this.selectedFolder = folder.label;
    this.showDrawer = false;
    if (folder.label === '重要联系人') {
      router.pushUrl({ url: 'pages/ImportantContactsPage' });
    }
  }

  handleCloseDrawer(): void {
    this.showDrawer = false;
  }

  build() {
    Stack() {
      Column() {
        // Navigation bar
        Row() {
          Text('<')
            .fontSize(20)
            .fontColor('#4A90D9')
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.handleBackTap(); })

          Text('434@qq.com')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Text('✏️')
            .fontSize(18)
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height(48)
        .padding({ left: 4, right: 8 })
        .backgroundColor('#FFFFFF')

        // Search bar
        Row() {
          Text('🔍 搜索')
            .fontSize(14)
            .fontColor('#C0C0C0')
            .layoutWeight(1)
        }
        .width('100%')
        .height(36)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
        .margin({ left: 12, right: 12, top: 6, bottom: 6 })
        .padding({ left: 12 })

        // Tab/Segment bar with folder dropdown trigger
        Row() {
          // Dropdown trigger for folder drawer
          Row() {
            Text(this.selectedFolder + ' ↑')
              .fontSize(14)
              .fontColor('#4A90D9')
          }
          .onClick(() => { this.handleDrawerToggle(); })

          Blank()

          ForEach(this.tabs, (tab: string, index: number) => {
            Text(tab)
              .fontSize(13)
              .fontColor(index === this.activeTab ? '#4A90D9' : '#888888')
              .padding({ left: 12, right: 12, top: 4, bottom: 4 })
              .borderRadius(4)
              .backgroundColor(index === this.activeTab ? '#EBF5FF' : '#00000000')
              .margin({ left: 4 })
              .onClick(() => { this.activeTab = index; })
          })
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 4, bottom: 8 })
        .backgroundColor('#FFFFFF')

        Divider()
          .height(0.5)
          .color('#E8E8E8')

        // Mail list
        Scroll() {
          Column() {
            ForEach(this.mailList, (item: MailItem, index: number) => {
              this.buildMailItem(item)
              if (index < this.mailList.length - 1) {
                Divider()
                  .height(0.5)
                  .color('#F0F0F0')
                  .margin({ left: 56 })
              }
            })
          }
        }
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')

      // Folder drawer overlay (from draft 9)
      if (this.showDrawer) {
        Row() {
          Column() {
            Scroll() {
              Column() {
                ForEach(this.folderItems, (folder: FolderItem, index: number) => {
                  this.buildDrawerItem(folder)
                })
              }
            }
            .layoutWeight(1)
          }
          .width('60%')
          .height('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius({ topRight: 12, bottomRight: 12 })
          .shadow({ radius: 10, color: '#00000030', offsetX: 4, offsetY: 0 })

          // Tap outside to close drawer
          Column()
            .width('40%')
            .height('100%')
            .onClick(() => { this.handleCloseDrawer(); })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000040')
        .onClick(() => { this.handleCloseDrawer(); })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildMailItem(item: MailItem) {
    Row() {
      // Unread indicator
      if (item.unread) {
        Text('')
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor('#4A90D9')
          .margin({ right: 8 })
      } else {
        Column().width(8).margin({ right: 8 })
      }

      // Sender avatar
      Text(item.senderIcon)
        .fontSize(22)
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor('#F0F4FF')
        .textAlign(TextAlign.Center)
        .margin({ right: 10 })

      // Content
      Column() {
        Row() {
          Text(item.senderName)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .maxLines(1)
            .layoutWeight(1)

          if (item.badge) {
            Text(item.badge)
              .fontSize(10)
              .fontColor('#FF6B35')
              .backgroundColor('#FFF3EC')
              .borderRadius(3)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .margin({ left: 4 })
          }

          Text(item.timestamp)
            .fontSize(11)
            .fontColor('#999999')
        }
        .width('100%')

        Text(item.subject || item.senderSubtitle || '')
          .fontSize(14)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 2 })

        if (item.preview) {
          Text(item.preview)
            .fontSize(12)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ top: 1 })
        }
      }
      .layoutWeight(1)

      Text('>')
        .fontSize(16)
        .fontColor('#C0C0C0')
        .margin({ left: 4 })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .onClick(() => { this.handleMailTap(item); })
  }

  @Builder
  buildDrawerItem(folder: FolderItem) {
    Row() {
      Text(folder.icon)
        .fontSize(16)
        .width(28)

      Text(folder.label)
        .fontSize(14)
        .fontColor('#333333')
        .layoutWeight(1)

      if (folder.badge) {
        Text(folder.badge)
          .fontSize(11)
          .fontColor('#999999')
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
          .padding({ left: 7, right: 7, top: 2, bottom: 2 })
      }
    }
    .width('100%')
    .height(42)
    .padding({ left: 16, right: 12 })
    .backgroundColor(folder.selected ? '#EBF5FF' : '#00000000')
    .borderRadius(6)
    .onClick(() => { this.handleFolderTap(folder); })
  }
}
