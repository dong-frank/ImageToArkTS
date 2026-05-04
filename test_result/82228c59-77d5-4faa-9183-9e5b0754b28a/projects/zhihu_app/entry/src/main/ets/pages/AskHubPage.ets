import router from '@ohos.router';
import { BottomNavBar } from '../components/BottomNavBar';

@Entry
@Component
struct AskHubPage {
  @State currentTabIndex: number = 0;
  askTabs: string[] = ['推荐', '最新', '热门', '视频', '圆桌'];

  build() {
    Column() {
      // Status bar placeholder
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

      // Top action bar
      Row() {
        Text('知乎')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Blank()
        Text('\u{1F50D}')
          .fontSize(20)
          .margin({ right: 12 })
        Text('\u{1F514}')
          .fontSize(20)
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Topic tabs
      Scroll() {
        Row() {
          ForEach(this.askTabs, (tab: string, index: number) => {
            Text(tab)
              .fontSize(15)
              .fontColor(this.currentTabIndex === index ? '#0066FF' : '#666666')
              .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
              .padding({ left: 14, right: 14, top: 10, bottom: 10 })
              .onClick(() => {
                this.currentTabIndex = index;
              })
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(44)
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })

      // Content area
      if (this.currentTabIndex === 0) {
        this.RecommendContent()
      } else if (this.currentTabIndex === 1) {
        this.LatestContent()
      } else if (this.currentTabIndex === 2) {
        this.HotContent()
      } else if (this.currentTabIndex === 3) {
        this.VideoContent()
      } else {
        this.RoundTableContent()
      }

      BottomNavBar({ currentTab: 1 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  RecommendContent() {
    Scroll() {
      Column() {
        // Highlighted question banner
        Column() {
          Text('今日热议')
            .fontSize(12)
            .fontColor('#FF6600')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })
          Text('AI 时代，普通人应该如何提升自己的核心竞争力？')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Row() {
            Text('3,542 回答 · 1,280 万浏览')
              .fontSize(12)
              .fontColor('#999999')
            Blank()
            Text('查看详情 >')
              .fontSize(12)
              .fontColor('#0066FF')
          }
          .width('100%')
          .margin({ top: 10 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .margin({ left: 12, right: 12, top: 12 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/QuestionDetailPage', params: { title: 'AI 时代，普通人应该如何提升自己的核心竞争力？', author: '科技观察者' } });
        })

        // Feed cards
        this.AskFeedCard('为什么现在的年轻人越来越不愿意结婚生娃了？', '社会学博士李', '1.2 万赞同 · 3,890 评论', true)
        this.AskFeedCard('如何评价苹果最新发布的 Vision Pro 2？', '数码爱好者小王', '8,920 赞同 · 2,456 评论', false)
        this.AskFeedCard('有哪些不为人知但非常实用的生活小技巧？', '生活达人阿花', '5,670 赞同 · 1,234 评论', true)
        this.AskFeedCard('工作多年后才发现，学历真的比能力重要吗？', '职场老司机', '2.3 万赞同 · 6,789 评论', false)
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  @Builder
  LatestContent() {
    Scroll() {
      Column() {
        this.AskFeedCard('如何看待最近的地缘政治变化？', '国际观察员', '456 赞同 · 128 评论', false)
        this.AskFeedCard('有什么好的副业推荐吗？', '自由职业者小林', '2,340 赞同 · 890 评论', true)
        this.AskFeedCard('高考志愿填报应该注意什么？', '教育专栏作者', '1,890 赞同 · 567 评论', false)
        this.AskFeedCard('Python 和 Rust 哪个更值得学？', '程序员老张', '3,456 赞同 · 987 评论', true)
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  @Builder
  HotContent() {
    Scroll() {
      Column() {
        Text('热门话题')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 16, top: 16, bottom: 8 })
          .width('100%')

        this.HotTopicItem('1', 'AI 大模型的未来发展趋势', '2,340 万热度')
        this.HotTopicItem('2', '中国航天最新进展', '1,980 万热度')
        this.HotTopicItem('3', '新能源车市场竞争格局', '1,756 万热度')
        this.HotTopicItem('4', '人工智能与就业变革', '1,520 万热度')
        this.HotTopicItem('5', '元宇宙概念还能火多久', '1,280 万热度')
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  @Builder
  VideoContent() {
    Column() {
      Text('\u{1F3AC}')
        .fontSize(48)
        .margin({ bottom: 12 })
      Text('视频内容')
        .fontSize(16)
        .fontColor('#999999')
      Text('精彩视频即将上线')
        .fontSize(13)
        .fontColor('#CCCCCC')
        .margin({ top: 4 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  RoundTableContent() {
    Column() {
      Text('\u{1F91D}')
        .fontSize(48)
        .margin({ bottom: 12 })
      Text('圆桌讨论')
        .fontSize(16)
        .fontColor('#999999')
      Text('更多圆桌内容敬请期待')
        .fontSize(13)
        .fontColor('#CCCCCC')
        .margin({ top: 4 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  AskFeedCard(title: string, author: string, stats: string, hasImage: boolean) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Row() {
        Text(author)
          .fontSize(12)
          .fontColor('#666666')
        Blank()
        Text(stats)
          .fontSize(11)
          .fontColor('#999999')
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .margin({ left: 12, right: 12, top: 6, bottom: 2 })
    .borderRadius(8)
    .onClick(() => {
      router.pushUrl({ url: 'pages/QuestionDetailPage', params: { title: title, author: author } });
    })
  }

  @Builder
  HotTopicItem(rank: string, title: string, heat: string) {
    Row() {
      Text(rank)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(rank === '1' ? '#FF4500' : rank === '2' ? '#FF6600' : rank === '3' ? '#FF9900' : '#999999')
        .width(28)
        .textAlign(TextAlign.Center)
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(heat)
          .fontSize(11)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .margin({ left: 10 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .margin({ left: 12, right: 12, top: 2, bottom: 2 })
    .borderRadius(4)
    .onClick(() => {
      router.pushUrl({ url: 'pages/QuestionDetailPage', params: { title: title, author: '知乎热榜' } });
    })
  }
}
