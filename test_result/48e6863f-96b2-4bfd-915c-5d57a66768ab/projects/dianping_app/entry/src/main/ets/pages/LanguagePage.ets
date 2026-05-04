import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct LanguagePage {
  @State followSystem: boolean = false;
  @State selectedLanguage: string = '简体中文';

  private languages: string[] = ['简体中文', 'English', '日本語', '한국어'];

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })
        Text('多语言')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('保存')
          .fontSize(14)
          .fontColor('#FF6600')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#FFF0E6')
          .borderRadius(14)
          .onClick(() => {
            promptAction.showToast({ message: '语言设置已保存' });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // Follow system toggle
          Column() {
            Row() {
              Column() {
                Text('跟随系统设置')
                  .fontSize(16)
                  .fontColor('#333333')
                Text('开启后，将跟随系统设置 App 语言')
                  .fontSize(12)
                  .fontColor('#999999')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.followSystem })
                .selectedColor('#FF6600')
                .onChange((value: boolean) => {
                  this.followSystem = value;
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 12, right: 12, top: 12 })

          // Language selection section
          Row() {
            Text('当前选择')
              .fontSize(13)
              .fontColor('#999999')
              .padding({ left: 16, top: 20, bottom: 8 })
          }
          .width('100%')

          Column() {
            ForEach(this.languages, (lang: string, index: number) => {
              Column() {
                Row() {
                  Text(lang)
                    .fontSize(16)
                    .fontColor('#333333')
                    .layoutWeight(1)

                  if (this.selectedLanguage === lang) {
                    Text('✓')
                      .fontSize(18)
                      .fontColor('#FF6600')
                      .fontWeight(FontWeight.Bold)
                  }
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => {
                  this.selectedLanguage = lang;
                })

                if (index < this.languages.length - 1) {
                  Divider()
                    .strokeWidth(0.5)
                    .color('#F0F0F0')
                    .margin({ left: 16 })
                }
              }
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 12, right: 12 })

          // Footer text
          Text('更多语言接入中，敬请期待')
            .fontSize(12)
            .fontColor('#CCCCCC')
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: 24, bottom: 24 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
