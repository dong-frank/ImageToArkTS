import router from '@ohos.router';
import { BottomNavBar } from '../components/BottomNavBar';

@Entry
@Component
struct ConsultationPage {
  @State consultationTabIndex: number = 0;

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('\u2190')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => { router.back(); })
        Text('付费咨询')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
          .layoutWeight(1)
        Text('\u{1F50D}')
          .fontSize(20)
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Search box
      Row() {
        Text('\u{1F50D}')
          .fontSize(16)
          .fontColor('#999999')
        Text('搜索答主或问题')
          .fontSize(14)
          .fontColor('#CCCCCC')
          .margin({ left: 8 })
      }
      .width('100%')
      .height(36)
      .backgroundColor('#F5F5F5')
      .borderRadius(18)
      .padding({ left: 12 })
      .margin({ left: 12, right: 12, top: 8, bottom: 8 })

      // 答主/问题 tabs
      Row() {
        Text('答主')
          .fontSize(16)
          .fontColor(this.consultationTabIndex === 0 ? '#0066FF' : '#333333')
          .fontWeight(this.consultationTabIndex === 0 ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 20, right: 20, top: 8, bottom: 8 })
          .onClick(() => { this.consultationTabIndex = 0; })
        Text('问题')
          .fontSize(16)
          .fontColor(this.consultationTabIndex === 1 ? '#0066FF' : '#333333')
          .fontWeight(this.consultationTabIndex === 1 ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 20, right: 20, top: 8, bottom: 8 })
          .onClick(() => { this.consultationTabIndex = 1; })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .padding({ bottom: 4 })

      if (this.consultationTabIndex === 0) {
        this.ExpertListContent()
      } else {
        this.QuestionListContent()
      }

      BottomNavBar({ currentTab: 1 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  ExpertListContent() {
    Scroll() {
      Column() {
        // Category grid
        Grid() {
          GridItem() { this.CategoryIcon('职场') }
          GridItem() { this.CategoryIcon('心理') }
          GridItem() { this.CategoryIcon('法律') }
          GridItem() { this.CategoryIcon('教育') }
          GridItem() { this.CategoryIcon('健康') }
          GridItem() { this.CategoryIcon('情感') }
          GridItem() { this.CategoryIcon('财经') }
          GridItem() { this.CategoryIcon('科技') }
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .padding(12)
        .backgroundColor('#FFFFFF')
        .margin({ top: 8 })

        Text('推荐答主')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 16, top: 16, bottom: 8 })
          .width('100%')

        this.ExpertCard('张医生', '三甲医院主任医师', '\u00A550/次')
        this.ExpertCard('李律师', '知名律所合伙人', '\u00A5100/次')
        this.ExpertCard('王教授', '985高校心理学教授', '\u00A580/次')
        this.ExpertCard('陈顾问', '资深职业规划师', '\u00A530/次')
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  QuestionListContent() {
    Scroll() {
      Column() {
        Text('推荐问题')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 16, top: 16, bottom: 8 })
          .width('100%')

        this.QuestionItem('如何在职场中快速获得晋升？', '35人咨询过')
        this.QuestionItem('和伴侣经常吵架怎么办？', '28人咨询过')
        this.QuestionItem('育儿过程中如何平衡工作与家庭？', '42人咨询过')
        this.QuestionItem('如何选择适合自己的投资方式？', '19人咨询过')
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  CategoryIcon(name: string) {
    Column() {
      Text('\u{1F4CB}')
        .fontSize(28)
      Text(name)
        .fontSize(12)
        .fontColor('#666666')
        .margin({ top: 4 })
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ExpertCard(name: string, title: string, price: string) {
    Row() {
      Text('\u{1F464}')
        .fontSize(36)
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor('#E0E0E0')
        .textAlign(TextAlign.Center)
      Column() {
        Text(name)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
        Text(title)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
      Column() {
        Text(price)
          .fontSize(14)
          .fontColor('#FF6600')
          .fontWeight(FontWeight.Bold)
        Text('去咨询')
          .fontSize(11)
          .fontColor('#FFFFFF')
          .backgroundColor('#0066FF')
          .borderRadius(12)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .margin({ left: 12, right: 12, top: 4, bottom: 4 })
    .borderRadius(8)
  }

  @Builder
  QuestionItem(question: string, stats: string) {
    Row() {
      Column() {
        Text(question)
          .fontSize(14)
          .fontColor('#333333')
        Text(stats)
          .fontSize(11)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .margin({ left: 12, right: 12, top: 4, bottom: 4 })
    .borderRadius(8)
  }
}
