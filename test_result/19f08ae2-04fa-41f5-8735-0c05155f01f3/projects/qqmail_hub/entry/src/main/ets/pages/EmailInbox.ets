import router from '@ohos.router'

// --- Data Models ---
interface MailItemData {
  id: string
  senderIconType: 'ad' | 'avatar' | 'circle'
  senderIconChar?: string
  senderIconColor?: string
  senderName: string
  senderSubtitle?: string
  senderBadge?: string
  senderBadgeColor?: string
  subject: string
  preview: string
  timestamp: string
  unread: boolean
  hasAttachment: boolean
  isAd: boolean
}

interface FolderItemData {
  id: string
  label: string
  badge: string
  iconName: string
}

@Entry
@Component
struct EmailInbox {
  // --- State ---
  @State activeTabIndex: number = 0
  @State showDrawer: boolean = false
  @State selectedFolderId: string = 'inbox'
  @State showStatusBanner: boolean = true

  // --- Navigation ---
  goBack() {
    router.back()
  }

  openEmailDetail() {
    router.pushUrl({ url: 'pages/EmailDetail' })
  }

  // --- Folder Drawer ---
  toggleDrawer() {
    this.showDrawer = !this.showDrawer
  }

  closeDrawer() {
    this.showDrawer = false
  }

  selectFolder(folderId: string) {
    this.selectedFolderId = folderId
    this.showDrawer = false
  }

  // --- All Mails (收件箱 tab) ---
  private allMails: MailItemData[] = [
    {
      id: '1',
      senderIconType: 'ad',
      senderIconChar: '鲸',
      senderIconColor: '#E8A838',
      senderName: '鲸匠装饰',
      senderBadge: '广告',
      senderBadgeColor: '#999999',
      subject: '地点：南京 项目：旧房翻新 活动：一价全包 附：2026价目表[机智]',
      preview: '',
      timestamp: '08:21',
      unread: false,
      hasAttachment: true,
      isAd: true
    },
    {
      id: '2',
      senderIconType: 'ad',
      senderIconChar: 'AD',
      senderIconColor: '#E8A838',
      senderName: '广告邮件',
      senderBadge: '156',
      senderBadgeColor: '#999999',
      subject: 'OpenAI, 招商银行信用卡, Kaggle, 华盛证券, ...',
      preview: 'A new class of intelligence for real work',
      timestamp: '08:21',
      unread: true,
      hasAttachment: false,
      isAd: true
    },
    {
      id: '3',
      senderIconType: 'circle',
      senderIconChar: 'Ov',
      senderIconColor: '#4A90D9',
      senderName: 'Overleaf',
      subject: '"Association for Computing Machinery (ACM)..."',
      preview: 'Overleaf Project Invite You have been invited to an Overleaf project. Project:...',
      timestamp: '前天 18:49',
      unread: true,
      hasAttachment: false,
      isAd: false
    },
    {
      id: '4',
      senderIconType: 'circle',
      senderIconChar: 'Op',
      senderIconColor: '#4A90D9',
      senderName: 'OpenRouter, Inc',
      subject: 'Your OpenRouter, Inc refund [#3044-8440]',
      preview: 'Refund from OpenRouter, Inc [#3044-8440] Refunded $10.00 Date issued Apr 22, 2026, 5...',
      timestamp: '4月22日',
      unread: true,
      hasAttachment: false,
      isAd: false
    },
    {
      id: '5',
      senderIconType: 'circle',
      senderIconChar: 'Op',
      senderIconColor: '#4A90D9',
      senderName: 'OpenRouter, Inc',
      subject: 'Your OpenRouter, Inc refund [#3480-9365]',
      preview: 'Refund from OpenRouter, Inc [#3480-9365] Refunded $30.00 Date issued Apr 22, 2026, 5...',
      timestamp: '4月22日',
      unread: true,
      hasAttachment: false,
      isAd: false
    },
    {
      id: '6',
      senderIconType: 'circle',
      senderIconChar: 'Op',
      senderIconColor: '#4A90D9',
      senderName: 'OpenRouter, Inc',
      subject: 'Your OpenRouter, Inc receipt [#1265-4960]',
      preview: 'Receipt from OpenRouter, Inc [#1265-4960] Amount paid $31.65 Date paid Apr 22, 2026,...',
      timestamp: '4月22日',
      unread: true,
      hasAttachment: false,
      isAd: false
    },
    {
      id: '7',
      senderIconType: 'circle',
      senderIconChar: 'Op',
      senderIconColor: '#4A90D9',
      senderName: 'OpenRouter, Inc',
      subject: 'Your OpenRouter, Inc receipt [#1335-1509]',
      preview: 'Receipt from OpenRouter, Inc [#1335-1509] Amount paid $10.80 Date paid Apr 22, 2026,...',
      timestamp: '4月22日',
      unread: true,
      hasAttachment: false,
      isAd: false
    }
  ]

  // --- Unread-only Mails (未读邮件 tab) ---
  private unreadMails: MailItemData[] = [
    {
      id: 'u1',
      senderIconType: 'avatar',
      senderIconChar: '招',
      senderIconColor: '#D94040',
      senderName: '招商银行信用卡',
      senderSubtitle: '每日信用管家',
      subject: '截至昨日最后一笔交易，您的额度和积分信息如下：',
      preview: '…30 … 可用…',
      timestamp: '12:11',
      unread: true,
      hasAttachment: false,
      isAd: false
    },
    {
      id: 'u2',
      senderIconType: 'circle',
      senderIconChar: 'Op',
      senderIconColor: '#4A90D9',
      senderName: 'OpenAI',
      senderSubtitle: 'Introducing GPT-5.5',
      subject: 'A new class of intelligence for real work',
      preview: '',
      timestamp: '08:21',
      unread: true,
      hasAttachment: false,
      isAd: false
    },
    {
      id: 'u3',
      senderIconType: 'avatar',
      senderIconChar: '招',
      senderIconColor: '#D94040',
      senderName: '招商银行信用卡',
      senderSubtitle: '每日信用管家',
      subject: '截至昨日最后一笔交易，您的额度和积分信息如下：',
      preview: '…).58 … 可用…',
      timestamp: '昨天 12:08',
      unread: true,
      hasAttachment: false,
      isAd: false
    },
    {
      id: 'u4',
      senderIconType: 'avatar',
      senderIconChar: '招',
      senderIconColor: '#D94040',
      senderName: '招商银行信用卡',
      senderSubtitle: '每日信用管家',
      subject: '截至昨日最后一笔交易，您的额度和积分信息如下：',
      preview: '…3.31 … 可用…',
      timestamp: '前天 12:08',
      unread: true,
      hasAttachment: false,
      isAd: false
    },
    {
      id: 'u5',
      senderIconType: 'avatar',
      senderIconChar: '招',
      senderIconColor: '#D94040',
      senderName: '招商银行信用卡',
      senderSubtitle: '',
      subject: '1544元露营车桌椅组合+50元还款金，推1人办…',
      preview: '',
      timestamp: '4月22日',
      unread: true,
      hasAttachment: false,
      isAd: false
    },
    {
      id: 'u6',
      senderIconType: 'circle',
      senderIconChar: 'Op',
      senderIconColor: '#4A90D9',
      senderName: 'OpenRouter, Inc',
      senderSubtitle: 'Your OpenRouter, Inc refund [#3480-9365]',
      subject: 'Refund from OpenRouter, Inc [#3480-9365]',
      preview: 'Refunded $30.00 Date issued Apr 22, 2026, 5...',
      timestamp: '4月22日',
      unread: true,
      hasAttachment: false,
      isAd: false
    },
    {
      id: 'u7',
      senderIconType: 'circle',
      senderIconChar: 'Op',
      senderIconColor: '#4A90D9',
      senderName: 'OpenRouter, Inc',
      senderSubtitle: '',
      subject: '',
      preview: '',
      timestamp: '4月22日',
      unread: true,
      hasAttachment: false,
      isAd: false
    }
  ]

  private getActiveMailList(): MailItemData[] {
    if (this.activeTabIndex === 1) {
      return this.unreadMails
    }
    return this.allMails
  }

  // --- Folder Data ---
  private folders: FolderItemData[] = [
    { id: 'inbox', label: '收件箱', badge: '357', iconName: 'inbox' },
    { id: 'starred', label: '星标邮件', badge: '', iconName: 'star' },
    { id: 'sent', label: '已发送', badge: '', iconName: 'sent' },
    { id: 'drafts', label: '草稿箱', badge: '', iconName: 'draft' },
    { id: 'deleted', label: '已删除', badge: '', iconName: 'trash' },
    { id: 'spam', label: '垃圾箱', badge: '1', iconName: 'bin' },
    { id: 'unread_folder', label: '未读邮件', badge: '821', iconName: 'folder' },
    { id: 'group_mail', label: '群邮件', badge: '', iconName: 'folder' },
    { id: 'important', label: '重要联系人', badge: '', iconName: 'bookmark' },
    { id: 'qq_sub', label: 'QQ邮件订阅', badge: '', iconName: 'folder' },
    { id: 'dear', label: 'dear', badge: '', iconName: 'folder' },
    { id: 'archive', label: '邮件归档', badge: '69', iconName: 'folder' },
    { id: 'manage', label: '管理', badge: '', iconName: 'gear' }
  ]

  // --- Builders ---
  @Builder
  buildMailItem(mail: MailItemData) {
    Row() {
      // Left: icon / avatar
      if (mail.senderIconType === 'ad') {
        Text(mail.senderIconChar)
          .width(40)
          .height(40)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .borderRadius(4)
          .backgroundColor('#E8A838')
      } else if (mail.senderIconType === 'circle') {
        Text(mail.senderIconChar)
          .width(40)
          .height(40)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .borderRadius(20)
          .backgroundColor(mail.senderIconColor || '#4A90D9')
      } else {
        Text(mail.senderIconChar)
          .width(40)
          .height(40)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .borderRadius(20)
          .backgroundColor(mail.senderIconColor || '#D94040')
      }

      // Center: sender + subject + preview
      Column() {
        // Sender row
        Row({ space: 6 }) {
          Text(mail.senderName)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (mail.senderBadge) {
            Text(mail.senderBadge)
              .fontSize(11)
              .fontColor(mail.senderBadgeColor || '#999999')
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .border({ width: 0.5, color: '#CCCCCC', radius: 2 })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (mail.senderSubtitle) {
          Text(mail.senderSubtitle)
            .fontSize(12)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        // Subject with unread dot
        Row({ space: 4 }) {
          if (mail.unread) {
            Circle({ width: 8, height: 8 })
              .fill('#4A90D9')
              .flexShrink(0)
          }
          Text(mail.subject || '(无主题)')
            .fontSize(14)
            .fontWeight(mail.unread ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(mail.unread ? '#1A1A1A' : '#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ top: 4 })

        if (mail.preview) {
          Text(mail.preview)
            .fontSize(12)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)

      // Right: timestamp + chevron
      Column() {
        Text(mail.timestamp)
          .fontSize(11)
          .fontColor('#AAAAAA')
          .textAlign(TextAlign.End)

        Text('>')
          .fontSize(16)
          .fontColor('#CCCCCC')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.End)
      .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 14, bottom: 14, left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(0)
    .onClick(() => {
      this.openEmailDetail()
    })
  }

  @Builder
  buildFolderItem(folder: FolderItemData) {
    Row() {
      Text(folder.label)
        .fontSize(15)
        .fontColor(folder.id === this.selectedFolderId ? '#007AFF' : '#333333')
        .fontWeight(folder.id === this.selectedFolderId ? FontWeight.Medium : FontWeight.Normal)
        .layoutWeight(1)

      if (folder.badge) {
        Text(folder.badge)
          .fontSize(13)
          .fontColor('#999999')
          .margin({ right: 8 })
      }

      if (folder.id === this.selectedFolderId) {
        Text('✓')
          .fontSize(14)
          .fontColor('#007AFF')
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .padding({ top: 14, bottom: 14, left: 20, right: 20 })
    .backgroundColor(folder.id === this.selectedFolderId ? '#E8F4FD' : '#FFFFFF')
    .onClick(() => {
      this.selectFolder(folder.id)
    })
  }

  @Builder
  buildDrawer() {
    Column() {
      // Drawer header
      Row() {
        Text('文件夹')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
      }
      .width('100%')
      .padding({ top: 16, bottom: 12, left: 20, right: 20 })
      .backgroundColor('#F5F5F5')

      // Folder list
      Scroll() {
        Column() {
          ForEach(this.folders, (folder: FolderItemData) => {
            this.buildFolderItem(folder)
          }, (folder: FolderItemData) => folder.id)
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('85%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topRight: 8, bottomRight: 8 })
    .shadow({
      radius: 16,
      color: 'rgba(0,0,0,0.15)',
      offsetX: 4,
      offsetY: 0
    })
  }

  build() {
    Stack() {
      // Main content
      Column() {
        // --- Navigation Bar ---
        Row() {
          Text('<')
            .fontSize(20)
            .fontColor('#333333')
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.goBack()
            })

          Text('xxx@qq.com')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Text('✎')
            .fontSize(18)
            .fontColor('#333333')
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height(48)
        .padding({ left: 8, right: 8 })
        .backgroundColor('#FFFFFF')

        // --- Search Bar ---
        Row() {
          Text('🔍')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ left: 12, right: 6 })

          Text('搜索')
            .fontSize(14)
            .fontColor('#BBBBBB')
            .layoutWeight(1)
        }
        .width('100%')
        .height(38)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
        .margin({ left: 14, right: 14, top: 10, bottom: 8 })

        // --- Tab Bar ---
        Row() {
          Row({ space: 4 }) {
            Text('收件箱')
              .fontSize(15)
              .fontWeight(this.activeTabIndex === 0 ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.activeTabIndex === 0 ? '#007AFF' : '#666666')

            Text('↑')
              .fontSize(12)
              .fontColor(this.activeTabIndex === 0 ? '#007AFF' : '#999999')
          }
          .padding({ top: 10, bottom: 10, left: 16, right: 16 })
          .onClick(() => {
            if (this.activeTabIndex === 0) {
              this.toggleDrawer()
            } else {
              this.activeTabIndex = 0
            }
          })

          Text('未读邮件')
            .fontSize(15)
            .fontWeight(this.activeTabIndex === 1 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.activeTabIndex === 1 ? '#007AFF' : '#666666')
            .padding({ top: 10, bottom: 10, left: 16, right: 16 })
            .onClick(() => {
              this.activeTabIndex = 1
              this.showDrawer = false
            })

          Text('管理')
            .fontSize(15)
            .fontWeight(this.activeTabIndex === 2 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.activeTabIndex === 2 ? '#007AFF' : '#666666')
            .padding({ top: 10, bottom: 10, left: 16, right: 16 })
            .onClick(() => {
              this.activeTabIndex = 2
              this.showDrawer = false
            })
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .justifyContent(FlexAlign.Start)
        .padding({ left: 4, top: 4 })

        Divider()
          .width('100%')
          .height(0.5)
          .color('#E0E0E0')

        // --- Status Banner ---
        if (this.showStatusBanner) {
          Row() {
            Text('1个文件夹有新邮件')
              .fontSize(12)
              .fontColor('#888888')
              .padding({ left: 16, top: 8, bottom: 8 })
          }
          .width('100%')
          .backgroundColor('#F8F8F8')
        }

        // --- Mail List ---
        Scroll() {
          Column() {
            ForEach(this.getActiveMailList(), (mail: MailItemData) => {
              this.buildMailItem(mail)
            }, (mail: MailItemData) => mail.id)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor('#F2F2F2')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')

      // --- Folder Drawer Overlay ---
      if (this.showDrawer) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.3)')
          .onClick(() => {
            this.closeDrawer()
          })

        this.buildDrawer()
      }
    }
    .width('100%')
    .height('100%')
  }
}
