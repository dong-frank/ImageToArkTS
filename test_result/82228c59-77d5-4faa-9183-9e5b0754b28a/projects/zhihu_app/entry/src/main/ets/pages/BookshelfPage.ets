import router from '@ohos.router';

interface BookItem {
  title: string;
  author: string;
  cover: string;
  progress: string;
  category: string;
}

@Entry
@Component
struct BookshelfPage {
  @State selectedTab: number = 0;
  shelfTabs: string[] = ['全部', '在读', '已读', '想读'];

  bookList: BookItem[] = [
    { title: 'LLM推理框架与性能优化', author: 'kaiyuan', cover: '📘', progress: '已读 48%', category: '在读' },
    { title: '深度学习入门与实践', author: 'tech_lab', cover: '📙', progress: '已读 72%', category: '在读' },
    { title: '产品经理成长手册', author: 'pm_master', cover: '📕', progress: '已完成', category: '已读' },
    { title: '2025年必读科技好书', author: 'editor_pick', cover: '📗', progress: '未开始', category: '想读' },
    { title: '人文社科经典导读', author: 'culture_hub', cover: '📓', progress: '已读 35%', category: '在读' },
    { title: 'Python高级编程实战', author: 'dev_guru', cover: '📔', progress: '已完成', category: '已读' },
    { title: '中国历史通览', author: 'history_nerd', cover: '📒', progress: '未开始', category: '想读' }
  ];

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
        Text('书架')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Tab filters
      Scroll() {
        Row() {
          ForEach(this.shelfTabs, (tab: string, index: number) => {
            Text(tab)
              .fontSize(13)
              .fontColor(this.selectedTab === index ? '#0066FF' : '#666666')
              .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Normal)
              .backgroundColor(this.selectedTab === index ? '#E8F0FE' : '#F5F5F5')
              .borderRadius(14)
              .padding({ left: 14, right: 14, top: 6, bottom: 6 })
              .margin({ left: index === 0 ? 12 : 6, right: index === this.shelfTabs.length - 1 ? 12 : 0 })
              .onClick(() => {
                this.selectedTab = index;
              })
          })
        }
        .padding({ top: 10, bottom: 10 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .backgroundColor('#FFFFFF')

      // Book list
      Scroll() {
        Column() {
          ForEach(this.getFilteredBooks(), (book: BookItem) => {
            this.BookCard(book);
          })
        }
        .padding({ top: 8 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }

  getFilteredBooks(): BookItem[] {
    if (this.selectedTab === 0) {
      return this.bookList;
    }
    const filterCategory = this.shelfTabs[this.selectedTab];
    return this.bookList.filter((book: BookItem) => book.category === filterCategory);
  }

  @Builder
  BookCard(book: BookItem) {
    Row() {
      Text(book.cover)
        .fontSize(32)
        .width(56)
        .height(72)
        .backgroundColor('#F0F4FF')
        .borderRadius(4)
        .textAlign(TextAlign.Center)

      Column() {
        Text(book.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row() {
          Text(book.author)
            .fontSize(12)
            .fontColor('#999999')
            .layoutWeight(1)
          Text(book.progress)
            .fontSize(11)
            .fontColor('#0066FF')
            .backgroundColor('#E8F0FE')
            .borderRadius(8)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .margin({ left: 12, right: 12, top: 4, bottom: 4 })
    .borderRadius(8)
    .onClick(() => {
      // Navigate to book reader/detail
    })
  }
}
