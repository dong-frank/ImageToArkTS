import router from '@ohos.router';

@Entry
@Component
struct InterestPreferencesPage {
  @State preferenceLevels: number[] = [1, 1, 1, 1, 1, 1, 1, 1];
  categories: string[] = ['社会/时政', '科技互联网', '职场', '娱乐', '人文', '情感', '体育竞技', '家居生活'];
  levelLabels: string[] = ['减少', '默认', '增加'];

  build() {
    Column() {
      // Status bar
      Row() {
        Text('15:17')
          .fontSize(12)
          .fontColor('#333333')
        Blank()
        Text('56%')
          .fontSize(12)
          .fontColor('#333333')
      }
      .width('100%')
      .height(28)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F5F5F5')

      // Navigation bar
      Row() {
        Text('<')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ right: 12 })
          .onClick(() => {
            router.back();
          })
        Text('内容兴趣偏好')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
        Text('恢复默认')
          .fontSize(14)
          .fontColor('#0066FF')
          .onClick(() => {
            for (let i = 0; i < this.preferenceLevels.length; i++) {
              this.preferenceLevels[i] = 1;
            }
          })
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Subtitle
      Text('为你推荐可能感兴趣的内容')
        .fontSize(13)
        .fontColor('#999999')
        .width('100%')
        .padding({ left: 16, top: 12, bottom: 12 })
        .backgroundColor('#FFFFFF')

      // Scrollable content list
      Scroll() {
        Column() {
          ForEach(this.categories, (category: string, index: number) => {
            this.PreferenceRow(category, index);
          })
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
      .backgroundColor('#F5F5F5')

      // Footer
      Row() {
        Text('编辑兴趣标签 >')
          .fontSize(15)
          .fontColor('#0066FF')
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#FFFFFF')
      .border({ width: { top: 0.5 }, color: '#F0F0F0' })
      .onClick(() => {
        // Navigate to interest tags editor
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  PreferenceRow(category: string, index: number) {
    Row() {
      Text(category)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
      Row() {
        ForEach(this.levelLabels, (label: string, levelIndex: number) => {
          Text(label)
            .fontSize(12)
            .fontColor(this.preferenceLevels[index] === levelIndex ? '#FFFFFF' : '#666666')
            .backgroundColor(this.preferenceLevels[index] === levelIndex ? '#0066FF' : '#F5F5F5')
            .borderRadius(12)
            .padding({ left: 14, right: 14, top: 4, bottom: 4 })
            .margin({ left: levelIndex === 0 ? 0 : 6 })
            .onClick(() => {
              this.preferenceLevels[index] = levelIndex;
            })
        })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
  }
}
