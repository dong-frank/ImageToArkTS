import router from '@ohos.router';

@Entry
@Component
struct HelpCenterPage {
  @State searchText: string = '';

  faqList: FaqItem[] = [
    { question: '如何修改个人资料？', category: '账号相关', icon: '👤' },
    { question: '如何注销知乎账号？', category: '账号相关', icon: '🗑️' },
    { question: '忘记密码怎么办？', category: '账号相关', icon: '🔑' },
    { question: '如何举报违规内容？', category: '内容问题', icon: '🚩' },
    { question: '我的内容被删除了？', category: '内容问题', icon: '📝' },
    { question: '文章审核需要多久？', category: '内容问题', icon: '⏱️' },
    { question: '盐选会员如何开通？', category: '会员服务', icon: '⭐' },
    { question: '会员自动续费如何取消？', category: '会员服务', icon: '🔄' },
    { question: '付费咨询如何退款？', category: '支付问题', icon: '💳' },
    { question: '盐粒如何获取和使用？', category: '支付问题', icon: '🧂' },
  ];

  categories: string[] = ['全部', '账号相关', '内容问题', '会员服务', '支付问题', '功能使用'];
  @State selectedCategoryIndex: number = 0;

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
        Text('帮助与客服')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Search bar
      Row() {
        Text('🔍')
          .fontSize(16)
          .margin({ right: 8 })
        TextInput({ placeholder: '搜索问题，快速找到答案', text: this.searchText })
          .fontSize(14)
          .layoutWeight(1)
          .backgroundColor('#F5F5F5')
          .borderRadius(0)
          .height(36)
          .onChange((value: string) => {
            this.searchText = value;
          })
      }
      .width('100%')
      .height(40)
      .backgroundColor('#F5F5F5')
      .borderRadius(20)
      .padding({ left: 16, right: 16 })
      .margin({ left: 12, right: 12, top: 10, bottom: 6 })

      // Category tabs
      Scroll() {
        Row() {
          ForEach(this.categories, (cat: string, index: number) => {
            Text(cat)
              .fontSize(13)
              .fontColor(this.selectedCategoryIndex === index ? '#0066FF' : '#666666')
              .backgroundColor(this.selectedCategoryIndex === index ? '#E8F0FE' : '#F5F5F5')
              .borderRadius(14)
              .padding({ left: 14, right: 14, top: 6, bottom: 6 })
              .margin({ left: index === 0 ? 12 : 6, right: index === this.categories.length - 1 ? 12 : 0 })
              .onClick(() => {
                this.selectedCategoryIndex = index;
              })
          })
        }
        .padding({ top: 8, bottom: 8 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .backgroundColor('#FFFFFF')

      // FAQ list
      Scroll() {
        Column() {
          Text('常见问题')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')
            .padding({ left: 16, top: 16, bottom: 8 })

          ForEach(this.getFilteredFaqs(), (item: FaqItem, index: number) => {
            this.FaqRow(item);
          })

          // Contact section
          Column() {
            Text('联系我们')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .padding({ left: 16, top: 20, bottom: 12 })

            Row() {
              Text('📧')
                .fontSize(24)
                .width(44)
                .height(44)
                .backgroundColor('#E8F0FE')
                .borderRadius(22)
                .textAlign(TextAlign.Center)
              Column() {
                Text('在线客服')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                Text('工作时间 09:00 - 22:00')
                  .fontSize(11)
                  .fontColor('#999999')
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .margin({ left: 12 })
              .alignItems(HorizontalAlign.Start)
              Text('>')
                .fontSize(14)
                .fontColor('#CCCCCC')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 12, right: 12 })

            Row() {
              Text('📞')
                .fontSize(24)
                .width(44)
                .height(44)
                .backgroundColor('#FFF3E0')
                .borderRadius(22)
                .textAlign(TextAlign.Center)
              Column() {
                Text('投诉与建议')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                Text('我们会在 3 个工作日内回复')
                  .fontSize(11)
                  .fontColor('#999999')
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .margin({ left: 12 })
              .alignItems(HorizontalAlign.Start)
              Text('>')
                .fontSize(14)
                .fontColor('#CCCCCC')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 12, right: 12, top: 8, bottom: 24 })
          }
          .width('100%')
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }

  getFilteredFaqs(): FaqItem[] {
    if (this.selectedCategoryIndex === 0) {
      return this.faqList;
    }
    const cat = this.categories[this.selectedCategoryIndex];
    return this.faqList.filter((item: FaqItem) => item.category === cat);
  }

  @Builder
  FaqRow(item: FaqItem) {
    Row() {
      Text(item.icon)
        .fontSize(22)
        .width(40)
        .height(40)
        .backgroundColor('#F5F5F5')
        .borderRadius(10)
        .textAlign(TextAlign.Center)
      Column() {
        Text(item.question)
          .fontSize(14)
          .fontColor('#333333')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.category)
          .fontSize(11)
          .fontColor('#0066FF')
          .backgroundColor('#E8F0FE')
          .borderRadius(8)
          .padding({ left: 8, right: 8, top: 1, bottom: 1 })
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
      Text('>')
        .fontSize(14)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#F5F5F5' })
  }
}

interface FaqItem {
  question: string;
  category: string;
  icon: string;
}
