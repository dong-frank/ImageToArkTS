import router from '@ohos.router';

// --- Data types ---

interface BenefitCardData {
  icon: string
  title: string
  subtitle: string
  progress?: ProgressData
  statusLine?: string
  actionLabel?: string
}

interface ProgressData {
  current: string
  total: string
}

interface BenefitItemData {
  icon: string
  title: string
  detail: string
}

@Entry
@Component
struct VipBenefits {
  // --- Navigation stubs ---
  // back → returns to pages/ServiceHub

  goBack() {
    router.back()
  }

  // --- Data ---

  private benefitCards: BenefitCardData[] = [
    {
      icon: '📧',
      title: '2T 邮箱容量',
      subtitle: '2GB 升级至 2TB',
      progress: { current: '1.2GB', total: '4GB' },
      statusLine: '当前容量 1.2GB / 4GB'
    },
    {
      icon: '☁️',
      title: '2T 云盘容量',
      subtitle: '3GB 升级至 2TB',
      progress: { current: '423KB', total: '3GB' },
      statusLine: '当前容量 423KB / 3GB'
    },
    {
      icon: '🔗',
      title: '10G 超大附件',
      subtitle: '邮件附件支持 10GB',
      actionLabel: '去了解'
    },
    {
      icon: '🛡️',
      title: '尊享会员身份',
      subtitle: '专属 VIP 地址和徽标',
      actionLabel: '去了解'
    }
  ]

  private benefitItems: BenefitItemData[] = [
    { icon: '📅', title: '超大附件', detail: '有效期90天' },
    { icon: '📦', title: '在线解压', detail: '最大10GB' },
    { icon: '📊', title: '图片导出表格', detail: '以Excel文件导出' },
    { icon: '@', title: '个性化邮箱地址', detail: '设置域名为地址' },
    { icon: '🚫', title: '会员免广告', detail: '邮箱免广告' },
    { icon: '⬆️', title: '高速上传下载', detail: '大文件传输无阻' },
    { icon: '🔍', title: '附件深度查杀', detail: '防范病毒邮件附件' },
    { icon: '🛡️', title: '恶意邮件识别', detail: '防范邮件钓鱼风险' },
    { icon: '🤖', title: 'AI防欺诈', detail: '90天自助查询' }
  ]

  @Builder
  buildNavBar() {
    Row() {
      Text('<')
        .fontSize(24)
        .fontColor('#333333')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .onClick(() => {
          this.goBack()
        })

      Blank()

      Text('QQ邮箱会员')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A1A')

      Blank()

      Text('⋯')
        .fontSize(22)
        .fontColor('#333333')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .onClick(() => {
          // More menu overlay — not navigation, per design spec
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: 8, right: 8 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildUserInfo() {
    Row({ space: 10 }) {
      // Avatar placeholder — circle
      Text('👤')
        .fontSize(28)
        .width(44)
        .height(44)
        .borderRadius(22)
        .backgroundColor('#E8E8E8')
        .textAlign(TextAlign.Center)

      Column({ space: 2 }) {
        Text('蒋')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')

        Text('未开通')
          .fontSize(12)
          .fontColor('#999999')
          .padding({ left: 6, right: 6, top: 1, bottom: 1 })
          .backgroundColor('#F0F0F0')
          .borderRadius(3)
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildPromoBanner() {
    Column() {
      // Top section with badge and subtitle
      Row({ space: 6 }) {
        Text('邮箱VIP')
          .fontSize(12)
          .fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor('#8A7FFD')
          .borderRadius(3)

        Text('开通会员，让邮箱更好用')
          .fontSize(14)
          .fontColor('#8A7FFD')
      }
      .width('100%')
      .margin({ bottom: 14 })

      // CTA Button
      Column() {
        Text('开通')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')

        Text('每月只需17.5元')
          .fontSize(11)
          .fontColor('#CCFFFFFF')
          .margin({ top: 2 })
      }
      .width('100%')
      .padding({ top: 14, bottom: 14 })
      .borderRadius(10)
      .backgroundColor('#8A7FFD')
      .onClick(() => {
        // activate_vip → target payment page not covered in page set
        // Per navigation_context, this is unresolved; keep as clickable but route unknown
      })
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor('#F5F3FF')
  }

  @Builder
  buildSectionHeader(title: string) {
    Text(title)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor('#1A1A1A')
      .width('100%')
      .padding({ left: 4, top: 4, bottom: 4 })
  }

  @Builder
  buildBenefitCard(card: BenefitCardData) {
    Column() {
      // Icon
      Text(card.icon)
        .fontSize(24)
        .margin({ bottom: 8 })

      // Title
      Text(card.title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A1A')
        .margin({ bottom: 2 })

      // Subtitle
      Text(card.subtitle)
        .fontSize(11)
        .fontColor('#888888')
        .margin({ bottom: 8 })

      // Progress bar (if present)
      if (card.progress !== undefined) {
        Column() {
          // Progress track
          Stack({ alignContent: Alignment.Start }) {
            // Background track
            Row()
              .width('100%')
              .height(4)
              .borderRadius(2)
              .backgroundColor('#EEEEEE')

            // Filled portion
            Row()
              .width('30%')
              .height(4)
              .borderRadius(2)
              .backgroundColor('#8A7FFD')
          }
          .width('100%')

          // Status text
          if (card.statusLine !== undefined) {
            Text(card.statusLine)
              .fontSize(10)
              .fontColor('#AAAAAA')
              .margin({ top: 4 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')
      }

      // Action link (if present)
      if (card.actionLabel !== undefined) {
        Row({ space: 3 }) {
          Text(card.actionLabel)
            .fontSize(12)
            .fontColor('#8A7FFD')
          Text('›')
            .fontSize(12)
            .fontColor('#8A7FFD')
        }
        .margin({ top: 4 })
        .onClick(() => {
          // learn_more targets not covered in page set — per navigation_context, unresolved
        })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildBenefitItem(item: BenefitItemData) {
    Row({ space: 12 }) {
      // Icon
      Text(item.icon)
        .fontSize(20)
        .width(36)
        .height(36)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .textAlign(TextAlign.Center)

      // Title + Detail
      Column({ space: 2 }) {
        Text(item.title)
          .fontSize(14)
          .fontColor('#1A1A1A')
        Text(item.detail)
          .fontSize(12)
          .fontColor('#AAAAAA')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // Right chevron
      Text('›')
        .fontSize(18)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 12, bottom: 12 })
  }

  build() {
    Column() {
      // Fixed navigation bar
      this.buildNavBar()

      // Scrollable content
      Scroll() {
        Column({ space: 0 }) {
          // --- User info section ---
          this.buildUserInfo()

          // --- Promo banner ---
          Column()
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor('#FFFFFF')
          {
            this.buildPromoBanner()
          }

          // --- Section: 会员享以下权益 ---
          Column()
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 6 })
            .backgroundColor('#FFFFFF')
          {
            this.buildSectionHeader('会员享以下权益')
          }

          // --- 2×2 Benefit Cards Grid ---
          Column()
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 10 })
            .backgroundColor('#FFFFFF')
          {
            Grid() {
              ForEach(this.benefitCards, (card: BenefitCardData, index: number) => {
                GridItem() {
                  this.buildBenefitCard(card)
                }
              }, (card: BenefitCardData, index: number) => index.toString())
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(10)
            .rowsGap(10)
            .width('100%')
          }

          // --- Divider spacing ---
          Row()
            .width('100%')
            .height(8)
            .backgroundColor('#F5F5F5')

          // --- Benefit List (9 items) ---
          Column()
            .width('100%')
            .padding({ left: 16, right: 16, top: 4, bottom: 16 })
            .backgroundColor('#FFFFFF')
          {
            ForEach(this.benefitItems, (item: BenefitItemData, index: number) => {
              this.buildBenefitItem(item)
              if (index < this.benefitItems.length - 1) {
                Divider()
                  .strokeWidth(0.5)
                  .color('#F0F0F0')
                  .margin({ left: 48 })
              }
            }, (item: BenefitItemData, index: number) => index.toString())
          }

          // Bottom spacer
          Row()
            .width('100%')
            .height(24)
            .backgroundColor('#FFFFFF')
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
