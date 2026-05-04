import router from '@ohos.router';

// ─── Data Models ────────────────────────────────────────────────

class FeatureItem {
  bulletText: string = ''
  subCheckboxText?: string
  subCheckboxChecked?: boolean
}

class TabData {
  icon: string = ''
  label: string = ''
  key: string = ''
  selected: boolean = false
}

// ─── Component ──────────────────────────────────────────────────

@Entry
@Component
struct InvoiceSetup {
  @State agreementChecked: boolean = false
  @State activeTab: string = 'invoice' // 'file' | 'transfer' | 'invoice'

  // ── Feature list data ──────────────────────────────────────
  getFeatureItems(): FeatureItem[] {
    return [
      {
        bulletText: '邮件中的发票自动同步，一目了然',
        subCheckboxText: '自动识别下载发票邮件附件的发票',
        subCheckboxChecked: true
      } as FeatureItem,
      {
        bulletText: '关联微信发票后，两端同步更便捷'
      } as FeatureItem,
      {
        bulletText: '一键生成报销单，发票批量省心管'
      } as FeatureItem
    ]
  }

  // ── Tab data ────────────────────────────────────────────────
  getTabItems(): TabData[] {
    return [
      { icon: '📄', label: '文件', key: 'file', selected: this.activeTab === 'file' } as TabData,
      { icon: '🔄', label: '中转站', key: 'transfer', selected: this.activeTab === 'transfer' } as TabData,
      { icon: '🧾', label: '发票', key: 'invoice', selected: this.activeTab === 'invoice' } as TabData
    ]
  }

  // ── Navigation ──────────────────────────────────────────────
  goBack() {
    router.back()
  }

  onTabSelect(tabKey: string) {
    if (tabKey === 'file' || tabKey === 'transfer') {
      // 文件、中转站Tab对应页面未在当前集合中覆盖，仅做视觉切换占位
      this.activeTab = tabKey
      return
    }
    this.activeTab = tabKey
  }

  onConfirm() {
    if (!this.agreementChecked) {
      return
    }
    // 提交授权后目标页(发票主列表页)未在当前集合中覆盖
    // 保留占位：返回上一页
    router.back()
  }

  onOpenAgreement() {
    // 授权须知详情页未在当前集合中覆盖，保留占位
    console.info('[InvoiceSetup] 打开《腾讯邮箱发票授权须知》- 目标页未覆盖')
  }

  // ── Build ───────────────────────────────────────────────────

  build() {
    Column() {
      // ── Navigation Bar ──────────────────────────────────────
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ left: 4, right: 12, top: 4, bottom: 4 })
          .onClick(() => { this.goBack() })

        Text('文件云盘')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1a1a1a')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 右侧占位保持标题居中
        Row()
          .width(28)
          .height(28)
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 16 })
      .alignItems(VerticalAlign.Center)

      // ── Divider ─────────────────────────────────────────────
      Divider()
        .color('#e5e5e5')
        .strokeWidth(0.5)

      // ── Scrollable Content ──────────────────────────────────
      Scroll() {
        Column() {
          // ── Hero Illustration Section ───────────────────────
          Column({ space: 16 }) {
            // Green invoice icon placeholder (no image asset available)
            Column() {
              Text('🧾')
                .fontSize(56)
            }
            .width(96)
            .height(96)
            .borderRadius(20)
            .backgroundColor('#e8f5e9')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Text('开启并使用发票')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1a1a1a')
          }
          .width('100%')
          .padding({ top: 32, bottom: 24 })
          .alignItems(HorizontalAlign.Center)

          // ── Feature List ────────────────────────────────────
          Column({ space: 0 }) {
            ForEach(this.getFeatureItems(), (item: FeatureItem, index: number) => {
              Column() {
                // Feature row with blue dot + text
                Row() {
                  // Blue dot
                  Circle({ width: 8, height: 8 })
                    .fill('#1677ff')
                    .margin({ right: 10, top: 2 })

                  Text(item.bulletText)
                    .fontSize(15)
                    .fontColor('#333333')
                    .layoutWeight(1)
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)

                // Sub checkbox item (for first feature)
                if (item.subCheckboxText) {
                  Row() {
                    Checkbox({ name: 'auto_detect', group: 'feature_sub' })
                      .select(item.subCheckboxChecked ?? false)
                      .selectedColor('#1677ff')
                      .width(18)
                      .height(18)
                      .enabled(false) // 默认勾选，用户不可取消
                      .margin({ left: 18, right: 8 })

                    Text(item.subCheckboxText)
                      .fontSize(13)
                      .fontColor('#888888')
                  }
                  .width('100%')
                  .margin({ top: 8 })
                  .padding({
                    left: 14,
                    right: 14,
                    top: 10,
                    bottom: 10
                  })
                  .backgroundColor('#f5f7fa')
                  .borderRadius(8)
                }

                // Separator between items
                if (index < this.getFeatureItems().length - 1) {
                  Divider()
                    .color('#f0f0f0')
                    .strokeWidth(0.5)
                    .margin({ top: 14, bottom: 14 })
                }
              }
              .width('100%')
              .padding({ top: index === 0 ? 0 : 0, bottom: 0 })
            })
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
          .backgroundColor(Color.White)
          .borderRadius(12)

          // ── Agreement Section ───────────────────────────────
          Row() {
            Checkbox({ name: 'agreement', group: 'agreement_group' })
              .select(this.agreementChecked)
              .selectedColor('#1677ff')
              .width(20)
              .height(20)
              .onChange((value: boolean) => {
                this.agreementChecked = value
              })

            Text('我已阅读并同意')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ left: 8 })

            Text('《腾讯邮箱发票授权须知》')
              .fontSize(14)
              .fontColor('#1677ff')
              .onClick(() => { this.onOpenAgreement() })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20 })
          .alignItems(VerticalAlign.Center)

          // ── CTA Button ──────────────────────────────────────
          Button('确定')
            .width('100%')
            .height(46)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .backgroundColor(this.agreementChecked ? '#1677ff' : '#a0c4ff')
            .borderRadius(8)
            .enabled(this.agreementChecked)
            .onClick(() => { this.onConfirm() })
            .margin({ left: 20, right: 20, top: 24, bottom: 24 })

          // Bottom spacer for tab bar clearance
          Blank()
            .height(60)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // ── Bottom Tab Bar Divider ──────────────────────────────
      Divider()
        .color('#e5e5e5')
        .strokeWidth(0.5)

      // ── Bottom Tab Bar ──────────────────────────────────────
      Row() {
        ForEach(this.getTabItems(), (tab: TabData) => {
          Column({ space: 2 }) {
            Text(tab.icon)
              .fontSize(22)
              .opacity(tab.selected ? 1.0 : 0.4)

            Text(tab.label)
              .fontSize(11)
              .fontColor(tab.selected ? '#1677ff' : '#999999')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 8, bottom: 8 })
          .onClick(() => {
            this.onTabSelect(tab.key)
          })
        })
      }
      .width('100%')
      .height(52)
      .backgroundColor('#fafafa')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
