import router from '@ohos.router';

@Entry
@Component
struct LanguageSettings {
  @State followSystem: boolean = false;
  @State selectedLanguage: string = '简体中文';

  private languages: string[] = ['简体中文', 'English', '日本語', '한국어'];

  build() {
    Column() {
      // Navigation bar: back button + title + save button
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ left: 16, right: 8, top: 12, bottom: 12 })
          .onClick(() => {
            router.back();
          })

        Text('多语言')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')

        Blank()

        Text('保存')
          .fontSize(16)
          .fontColor('#007AFF')
          .padding({ left: 8, right: 16, top: 12, bottom: 12 })
          .onClick(() => {
            console.info('[LanguageSettings] 保存语言设置: followSystem=' + this.followSystem + ', language=' + this.selectedLanguage);
          })
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center)

      // Divider below nav bar
      Divider()
        .height(0.5)
        .color('#E5E5E5')

      // Scrollable settings list
      Scroll() {
        Column() {
          // Follow system toggle
          Row() {
            Text('跟随系统设置')
              .fontSize(16)
              .fontColor('#1A1A1A')

            Blank()

            Toggle({ type: ToggleType.Switch, isOn: this.followSystem })
              .onChange((isOn: boolean) => {
                this.followSystem = isOn;
              })
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FFFFFF')
          .alignItems(VerticalAlign.Center)

          // Section gap
          Column()
            .width('100%')
            .height(8)
            .backgroundColor('#F5F5F5')

          // Section header: 语言
          Row() {
            Text('语言')
              .fontSize(13)
              .fontColor('#999999')
              .padding({ left: 16, top: 12, bottom: 8 })
          }
          .width('100%')
          .backgroundColor('#F5F5F5')

          // Language radio list
          Column() {
            ForEach(this.languages, (language: string, index: number) => {
              Column() {
                Row() {
                  Text(language)
                    .fontSize(16)
                    .fontColor('#1A1A1A')

                  Blank()

                  if (this.selectedLanguage === language) {
                    Text('✓')
                      .fontSize(18)
                      .fontColor('#007AFF')
                  }
                }
                .width('100%')
                .height(52)
                .padding({ left: 16, right: 16 })
                .alignItems(VerticalAlign.Center)
                .onClick(() => {
                  if (!this.followSystem) {
                    this.selectedLanguage = language;
                  }
                })

                if (index < this.languages.length - 1) {
                  Divider()
                    .height(0.5)
                    .color('#F0F0F0')
                    .margin({ left: 16 })
                }
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
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
