import router from '@ohos.router';

@Entry
@Component
struct ImportantContacts {
  // --- Navigation ---
  // back → returns to pages/ServiceHub
  // add_contact → target page not covered in page set (unresolved)

  goBack() {
    router.back()
  }

  onAddContact() {
    // Target "联系人选择页" not covered in current page set.
    // Keep as clickable placeholder; no confirmed route available.
  }

  // --- Nav Bar ---

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

      Text('重要联系人')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A1A')

      Blank()

      // Spacer to balance the left back button
      Row()
        .width(40)
        .height(40)
    }
    .width('100%')
    .height(48)
    .padding({ left: 8, right: 8 })
    .backgroundColor('#FFFFFF')
  }

  // --- Empty State Content ---

  @Builder
  buildEmptyState() {
    Column({ space: 20 }) {
      // Envelope + bookmark illustration
      Stack({ alignContent: Alignment.Center }) {
        // Envelope outline icon
        Text('✉')
          .fontSize(56)
          .fontColor('#CCCCCC')

        // Bookmark icon layered at bottom-right
        Text('🔖')
          .fontSize(28)
          .offset({ x: 30, y: 16 })
      }
      .width(120)
      .height(100)

      // Caption text
      Text('快速查看重要联系人的来信')
        .fontSize(15)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)

      // Primary CTA button
      Button('添加重要联系人')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor('#1677FF')
        .borderRadius(8)
        .width(200)
        .height(44)
        .onClick(() => {
          this.onAddContact()
        })
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .layoutWeight(1)
  }

  build() {
    Column() {
      this.buildNavBar()

      this.buildEmptyState()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
