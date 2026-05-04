import router from '@ohos.router';
import { BottomNavBar } from '../components/BottomNavBar';

@Entry
@Component
struct HomePage {
  @State currentTab: number = 0;
  @State feedTabIndex: number = 1;
  feedTabs: string[] = ['关注', '推荐', '热榜', '故事', '知识', '圈子', '专栏', '听'];

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

      // Search bar
      Row() {
        Text('南瑞继保硕士3年后待遇')
          .fontSize(14)
          .fontColor('#999999')
          .layoutWeight(1)
        Text('搜索')
          .fontSize(14)
          .fontColor('#0066FF')
      }
      .width('100%')
      .height(36)
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
      .padding({ left: 16, right: 12 })
      .margin({ left: 12, right: 12, top: 6, bottom: 6 })
      .onClick(() => {
        // Search action
      })

      // Feed tab bar
      Scroll() {
        Row() {
          ForEach(this.feedTabs, (tab: string, index: number) => {
            Text(tab)
              .fontSize(16)
              .fontColor(this.feedTabIndex === index ? '#333333' : '#999999')
              .fontWeight(this.feedTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => {
                this.feedTabIndex = index;
              })
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(44)
      .backgroundColor('#FFFFFF')

      // Content area based on selected feed tab
      if (this.feedTabIndex === 0) {
        this.FollowTabContent()
      } else if (this.feedTabIndex === 1) {
        this.RecommendTabContent()
      } else if (this.feedTabIndex === 2) {
        this.HotListContent()
      } else if (this.feedTabIndex === 3) {
        this.StoryTabContent()
      } else if (this.feedTabIndex === 4) {
        this.KnowledgeTabContent()
      } else {
        this.PlaceholderContent(this.feedTabs[this.feedTabIndex])
      }

      // Bottom navigation
      BottomNavBar({ currentTab: 0 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  FollowTabContent() {
    Scroll() {
      Column() {
        // Author quick entry carousel
        Row() {
          Text('作者快捷入口')
            .fontSize(13)
            .fontColor('#666666')
            .margin({ left: 12, top: 12 })
        }
        .width('100%')

        Scroll() {
          Row() {
            this.AvatarCard('夏可 sherck', '什么值得买', true)
            this.AvatarCard('值', '什么值得买', false)
            this.AvatarCard('木匠小强', '木匠小强', false)
            this.AvatarCard('老爸评测', '老爸评测', false)
          }
          .padding({ left: 12, right: 12 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .height(80)

        // Filter buttons
        Row() {
          Text('精选')
            .fontSize(13)
            .fontColor('#FFFFFF')
            .backgroundColor('#0066FF')
            .borderRadius(14)
            .padding({ left: 14, right: 14, top: 5, bottom: 5 })
          Text('最新')
            .fontSize(13)
            .fontColor('#333333')
            .backgroundColor('#F0F0F0')
            .borderRadius(14)
            .padding({ left: 14, right: 14, top: 5, bottom: 5 })
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })

        // Feed cards
        this.QuestionCard('无大算力时，作为学生，LLM 还有哪些值得做的研究？', 'Cv大法代码酱', '2.4 万人关注', '3424', '5917', '95')
        this.QuestionCard('为什么有钱人皮肤都这么好？', '达布溜溜梅', '', '1280', '2340', '42')
        this.QuestionCard('在人的世界里是钱最重要还是快乐最重要？', '哲学家小张', '97 回答 · 96 关注', '567', '890', '23')
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  @Builder
  RecommendTabContent() {
    Scroll() {
      Column() {
        // Top bar with avatar and icons
        Row() {
          Text('\u{1F464}')
            .fontSize(24)
          Blank()
          Text('\u{1F4F7}')
            .fontSize(20)
            .margin({ right: 12 })
          Text('\u{1F50D}')
            .fontSize(20)
            .margin({ right: 12 })
          Text('\u{2699}')
            .fontSize(20)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })

        // Question card with answer prompt
        Column() {
          Text('试试帮他/她解答吧')
            .fontSize(12)
            .fontColor('#0066FF')
          Text('在人的世界里是钱最重要还是快乐最重要？')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 8 })
          Text('97 回答 · 96 关注')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .margin({ left: 12, right: 12, top: 8 })

        // Activity banner
        Row() {
          Text('\u{1F389}')
            .fontSize(20)
          Column() {
            Text('创作打卡瓜分 2300 万盐粒')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
            Text('连续打卡赢奖励')
              .fontSize(12)
              .fontColor('#FF6600')
          }
          .margin({ left: 8 })
          .layoutWeight(1)
          Text('>')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF8E1')
        .borderRadius(8)
        .margin({ left: 12, right: 12, top: 8 })

        // Function list
        this.FunctionItem('知识王者', 'PK')
        this.FunctionItem('超赞包', 'star')
        this.FunctionItem('畅听', 'headset')
        this.FunctionItem('品牌榜', 'chart')
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  @Builder
  HotListContent() {
    Scroll() {
      Column() {
        Text('热榜')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 16, top: 16, bottom: 8 })
          .width('100%')

        this.HotItem('1', 'AI 大模型将如何改变未来教育？', '994万热度')
        this.HotItem('2', '如何看待最新的芯片制造工艺突破？', '876万热度')
        this.HotItem('3', '有哪些简单易行的健康生活方式？', '752万热度')
        this.HotItem('4', '2025 年最值得期待的新技术有哪些？', '689万热度')
        this.HotItem('5', '如何高效学习一门新编程语言？', '521万热度')
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  @Builder
  StoryTabContent() {
    Scroll() {
      Column() {
        // Promo banner
        Row() {
          Text('\u{1F4DA}')
            .fontSize(24)
          Column() {
            Text('开通盐选会员')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF6600')
            Text('海量优质内容等你来读')
              .fontSize(12)
              .fontColor('#999999')
          }
          .margin({ left: 8 })
          .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF3E0')
        .margin({ top: 8, left: 12, right: 12 })
        .borderRadius(8)

        // Sub tabs
        Row() {
          Text('推荐榜')
            .fontSize(14)
            .fontColor('#0066FF')
            .fontWeight(FontWeight.Bold)
            .padding({ right: 16 })
          Text('新书榜')
            .fontSize(14)
            .fontColor('#666666')
            .padding({ right: 16 })
          Text('热度榜')
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')
        .padding({ left: 16, top: 12, bottom: 8 })

        // Story cards
        this.StoryCard('深夜的秘密', '悬疑短篇', '4.8分')
        this.StoryCard('穿越时光的爱恋', '言情长文', '4.6分')
        this.StoryCard('最后的侦探', '推理连载', '4.7分')
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  @Builder
  KnowledgeTabContent() {
    Scroll() {
      Column() {
        Row() {
          Text('口碑榜')
            .fontSize(14)
            .fontColor('#0066FF')
            .fontWeight(FontWeight.Bold)
            .padding({ right: 16 })
          Text('畅销榜')
            .fontSize(14)
            .fontColor('#666666')
            .padding({ right: 16 })
          Text('新鲜榜')
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')
        .padding({ left: 16, top: 12, bottom: 8 })

        this.KnowledgeBookCard('LLM推理框架与性能优化', 'kaiyuan', '250人订阅', '48个内容')
        this.KnowledgeBookCard('深度学习入门与实践', 'tech_lab', '1820人订阅', '120个内容')
        this.KnowledgeBookCard('产品经理成长手册', 'pm_master', '960人订阅', '64个内容')

        Text('精选书单')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 16, top: 16, bottom: 8 })
          .width('100%')

        this.KnowledgeBookCard('2025年必读科技好书', 'editor_pick', '3200人关注', '15本书')
        this.KnowledgeBookCard('人文社科经典导读', 'culture_hub', '1560人关注', '28本书')
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  @Builder
  PlaceholderContent(tabName: string) {
    Column() {
      Text(tabName + ' 内容')
        .fontSize(16)
        .fontColor('#999999')
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  AvatarCard(name: string, subtitle: string, hasBadge: boolean) {
    Column() {
      Text('\u{1F464}')
        .fontSize(30)
        .width(44)
        .height(44)
        .borderRadius(22)
        .backgroundColor('#E0E0E0')
        .textAlign(TextAlign.Center)
      Text(name)
        .fontSize(11)
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width(60)
        .textAlign(TextAlign.Center)
      if (hasBadge) {
        Text('●')
          .fontSize(8)
          .fontColor('#FF0000')
      }
    }
    .margin({ right: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  QuestionCard(title: string, author: string, badge: string, upvotes: string, stars: string, comments: string) {
    Column() {
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Row() {
        Text(author)
          .fontSize(12)
          .fontColor('#666666')
        if (badge !== '') {
          Text(badge)
            .fontSize(10)
            .fontColor('#0066FF')
            .margin({ left: 6 })
        }
        Blank()
        Text('\u{2764} ' + upvotes)
          .fontSize(12)
          .fontColor('#999999')
        Text('\u{2B50} ' + stars)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ left: 10 })
        Text('\u{1F4AC} ' + comments)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ left: 10 })
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
  FunctionItem(name: string, icon: string) {
    Row() {
      Text(icon === 'PK' ? '\u{1F3AE}' : icon === 'star' ? '\u{2B50}' : icon === 'headset' ? '\u{1F3A7}' : '\u{1F4CA}')
        .fontSize(20)
      Text(name)
        .fontSize(14)
        .fontColor('#333333')
        .margin({ left: 10 })
        .layoutWeight(1)
      Text('>')
        .fontSize(14)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
  }

  @Builder
  HotItem(rank: string, title: string, heat: string) {
    Row() {
      Text(rank)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(rank === '1' ? '#FF4500' : rank === '2' ? '#FF6600' : rank === '3' ? '#FF9900' : '#999999')
        .width(30)
        .textAlign(TextAlign.Center)
      Column() {
        Text(title)
          .fontSize(14)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(heat)
          .fontSize(11)
          .fontColor('#999999')
      }
      .layoutWeight(1)
      .margin({ left: 8 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .margin({ left: 12, right: 12, top: 2, bottom: 2 })
    .borderRadius(4)
  }

  @Builder
  StoryCard(title: string, tag: string, rating: string) {
    Row() {
      Text('\u{1F4D5}')
        .fontSize(36)
        .width(60)
        .height(80)
        .backgroundColor('#E8F0FE')
        .borderRadius(4)
        .textAlign(TextAlign.Center)
      Column() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
        Row() {
          Text(tag)
            .fontSize(11)
            .fontColor('#0066FF')
            .backgroundColor('#E8F0FE')
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          Text(rating)
            .fontSize(11)
            .fontColor('#FF6600')
            .margin({ left: 8 })
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .margin({ left: 12, right: 12, top: 4, bottom: 4 })
    .borderRadius(8)
  }

  @Builder
  KnowledgeBookCard(title: string, author: string, subscribers: string, count: string) {
    Row() {
      Text('\u{1F4D8}')
        .fontSize(32)
        .width(56)
        .height(72)
        .backgroundColor('#F0F4FF')
        .borderRadius(4)
        .textAlign(TextAlign.Center)
      Column() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(author + ' · ' + subscribers + ' · ' + count)
          .fontSize(11)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .margin({ left: 12, right: 12, top: 4, bottom: 4 })
    .borderRadius(8)
  }
}
