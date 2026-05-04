import router from '@ohos.router';

@Entry
@Component
struct SettingsGeneral {
  // --- State ---
  @State soundOn: boolean = true;
  @State avatarOn: boolean = true;

  // --- Confirmed navigation obligations ---
  // back → returns to pages/SettingsRoot (high confidence)
  goBack() {
    router.back()
  }

  // app_settings → opens pages/AppSettingsList (high confidence)
  openAppSettings() {
    router.pushUrl({ url: 'pages/AppSettingsList' })
  }

  // --- Unresolved navigation targets (target pages not in page set) ---
  openHomeManagement() {
    console.info('[SettingsGeneral] openHomeManagement: target page not covered')
  }

  openFontSize() {
    console.info('[SettingsGeneral] openFontSize: target page not covered')
  }

  openImageLoading() {
    console.info('[SettingsGeneral] openImageLoading: target page not covered')
  }

  openLanguage() {
    console.info('[SettingsGeneral] openLanguage: target page not covered')
  }

  // --- Section building helpers ---
  @Builder
  buildSectionHeaderDivider() {
    Row()
      .width('100%')
      .height(8)
  }

  @Builder
  buildChevronItem(label: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#000000')
        .layoutWeight(1)
      Text('>')
        .fontSize(18)
        .fontColor('#C7C7CC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .onClick(onClick)
  }

  @Builder
  buildChevronItemWithDetail(label: string, detail: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#000000')
      Blank()
      Text(detail)
        .fontSize(16)
        .fontColor('#8E8E93')
        .padding({ right: 6 })
      Text('>')
        .fontSize(18)
        .fontColor('#C7C7CC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .onClick(onClick)
  }

  @Builder
  buildToggleItem(label: string, isOn: boolean, onToggle: (value: boolean) => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#000000')
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor('#007AFF')
        .onChange((value: boolean) => {
          onToggle(value)
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
  }

  @Builder
  buildSeparator() {
    Divider()
      .strokeWidth(0.5)
      .color('#E5E5EA')
      .margin({ left: 16, right: 0 })
  }

  build() {
    Column() {
      // --- Navigation Bar ---
      Row() {
        Button() {
          Text('<')
            .fontSize(20)
            .fontColor('#007AFF')
            .fontWeight(FontWeight.Normal)
        }
        .type(ButtonType.Normal)
        .backgroundColor(Color.Transparent)
        .width(44)
        .height(44)
        .onClick(() => {
          this.goBack()
        })

        Text('通用')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

        // Spacer to balance the back button
        Row()
          .width(44)
          .height(44)
      }
      .width('100%')
      .height(44)
      .padding({ left: 4, right: 16 })
      .backgroundColor('#F5F5F5')

      // --- Scrollable Content ---
      Scroll() {
        Column() {
          // Section 1: Navigation & Core Settings
          this.buildSectionHeaderDivider()

          Column() {
            this.buildChevronItem('首页管理', () => { this.openHomeManagement() })
            this.buildSeparator()
            this.buildChevronItem('应用设置', () => { this.openAppSettings() })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .margin({ left: 16, right: 16 })

          // Section 2: Toggle Controls & System-Linked Options
          this.buildSectionHeaderDivider()

          Column() {
            this.buildToggleItem('发信音效', this.soundOn, (value: boolean) => {
              this.soundOn = value
            })
            this.buildSeparator()
            this.buildToggleItem('邮件列表头像', this.avatarOn, (value: boolean) => {
              this.avatarOn = value
            })
            this.buildSeparator()
            this.buildChevronItemWithDetail('文字大小', '跟随系统', () => { this.openFontSize() })
            this.buildSeparator()
            this.buildChevronItemWithDetail('加载邮件图片', '所有网络', () => { this.openImageLoading() })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .margin({ left: 16, right: 16 })

          // Section 3: Language
          this.buildSectionHeaderDivider()

          Column() {
            this.buildChevronItem('语言', () => { this.openLanguage() })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .margin({ left: 16, right: 16 })

          // Bottom spacing
          this.buildSectionHeaderDivider()
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
