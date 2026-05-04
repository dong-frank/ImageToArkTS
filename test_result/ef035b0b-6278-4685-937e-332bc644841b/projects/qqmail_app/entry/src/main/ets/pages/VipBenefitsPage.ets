/**
 * VipBenefitsPage - QQ Mail VIP membership benefits page
 * Based on: Draft 3 (success)
 */
import router from '@ohos.router';

interface BenefitCardData {
  icon: string;
  title: string;
  detail: string;
  progressCurrent?: string;
  progressTotal?: string;
  progressLabel?: string;
  linkText?: string;
}

interface FeatureItemData {
  icon: string;
  title: string;
  caption: string;
}

@Entry
@Component
struct VipBenefitsPage {
  readonly userName: string = '蒋';
  readonly membershipStatus: string = '未开通';

  readonly coreBenefits: BenefitCardData[] = [
    {
      icon: '✉️',
      title: '2T 邮箱容量',
      detail: '2GB 升级至 2TB',
      progressCurrent: '1.2GB',
      progressTotal: '4GB',
      progressLabel: '当前容量 1.2GB / 4GB'
    },
    {
      icon: '☁️',
      title: '2T 云盘容量',
      detail: '3GB 升级至 2TB',
      progressCurrent: '423KB',
      progressTotal: '3GB',
      progressLabel: '当前容量 423KB / 3GB'
    },
    {
      icon: '📎',
      title: '10G 超大附件',
      detail: '邮件附件支持 10GB',
      linkText: '去了解'
    },
    {
      icon: '✓',
      title: '尊享会员身份',
      detail: '专属 VIP 地址和徽标',
      linkText: '去了解'
    }
  ];

  readonly extraFeatures: FeatureItemData[] = [
    { icon: '📅', title: '超大附件', caption: '有效期90天' },
    { icon: '📄', title: '在线解压', caption: '最大10GB' },
    { icon: '📊', title: '图片导出表格', caption: '' },
    { icon: '🔒', title: '加密邮件', caption: '' },
    { icon: '📭', title: '垃圾邮件拦截', caption: '智能过滤' },
    { icon: '↩️', title: '邮件撤回', caption: '发信15秒内' },
    { icon: '⏰', title: '定时发送', caption: '' },
    { icon: '🎨', title: '个性邮箱皮肤', caption: '' }
  ];

  handleBackTap(): void {
    router.back();
  }

  handleOpenVip(): void {
    // Placeholder: would navigate to payment page
  }

  build() {
    Column() {
      // Navigation header
      Row() {
        Text('<')
          .fontSize(20)
          .fontColor('#4A90D9')
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.handleBackTap(); })

        Text('QQ邮箱会员')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('⋯')
          .fontSize(18)
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(48)
      .padding({ left: 4, right: 8 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // User status section
          Row() {
            Text(this.userName)
              .fontSize(28)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A1A')
              .width(56)
              .height(56)
              .borderRadius(28)
              .backgroundColor('#4A90D9')
              .fontColor('#FFFFFF')
              .textAlign(TextAlign.Center)
              .fontSize(22)
              .margin({ right: 12 })

            Column() {
              Text('蒋')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A1A1A')
              Text(this.membershipStatus)
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)

            Blank()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })

          // Promo banner
          Column() {
            Row() {
              Text('✓')
                .fontSize(10)
                .fontColor('#FFFFFF')
                .backgroundColor('#7B3FF2')
                .borderRadius(8)
                .width(16)
                .height(16)
                .textAlign(TextAlign.Center)
                .margin({ right: 6 })

              Text('邮箱VIP')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
            }

            Text('开通会员，让邮箱更好用')
              .fontSize(13)
              .fontColor('#E0D0FF')
              .margin({ top: 4 })

            Button('开通')
              .width('80%')
              .height(40)
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor('#7B3FF2')
              .borderRadius(20)
              .margin({ top: 12 })
              .onClick(() => { this.handleOpenVip(); })

            Text('每月只需 17.5 元')
              .fontSize(11)
              .fontColor('#C0B0E0')
              .margin({ top: 4 })
          }
          .width('100%')
          .padding({ top: 20, bottom: 20 })
          .backgroundColor('linear-gradient(135deg, #9B59B6, #6C3FAA)')
          .borderRadius(12)
          .margin({ left: 12, right: 12, top: 8 })
          .alignItems(HorizontalAlign.Center)

          // Section title
          Text('会员享以下权益')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .width('100%')
            .padding({ left: 16, right: 16, top: 20, bottom: 10 })

          // Core benefits - 2x2 grid
          Grid() {
            ForEach(this.coreBenefits, (benefit: BenefitCardData, index: number) => {
              GridItem() {
                this.buildBenefitCard(benefit)
              }
            })
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(10)
          .rowsGap(10)
          .padding({ left: 12, right: 12 })
          .height(360)

          // Extra features section
          Text('更多权益')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 8 })

          List() {
            ForEach(this.extraFeatures, (feature: FeatureItemData) => {
              ListItem() {
                Row() {
                  Text(feature.icon)
                    .fontSize(18)
                    .width(32)

                  Column() {
                    Text(feature.title)
                      .fontSize(14)
                      .fontColor('#333333')
                    if (feature.caption) {
                      Text(feature.caption)
                        .fontSize(11)
                        .fontColor('#999999')
                        .margin({ top: 2 })
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 10, bottom: 10 })
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 12, right: 12 })
          .divider({ strokeWidth: 0.5, color: '#F0F0F0' })

          Column().height(20)
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
  buildBenefitCard(benefit: BenefitCardData) {
    Column() {
      Text(benefit.icon)
        .fontSize(28)
        .margin({ bottom: 6 })

      Text(benefit.title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A1A')

      Text(benefit.detail)
        .fontSize(11)
        .fontColor('#666666')
        .margin({ top: 4 })

      if (benefit.progressLabel) {
        Column() {
          Row() {
            Row() {
            }
            .width('30%')
            .height(4)
            .borderRadius(2)
            .backgroundColor('#7B3FF2')
          }
          .width('100%')
          .height(4)
          .borderRadius(2)
          .backgroundColor('#E8E8E8')
          .margin({ top: 8 })

          Text(benefit.progressLabel)
            .fontSize(9)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
        .width('100%')
        .margin({ top: 4 })
      }

      if (benefit.linkText) {
        Text(benefit.linkText)
          .fontSize(12)
          .fontColor('#4A90D9')
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding({ top: 14, bottom: 14, left: 10, right: 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Center)
  }
}
