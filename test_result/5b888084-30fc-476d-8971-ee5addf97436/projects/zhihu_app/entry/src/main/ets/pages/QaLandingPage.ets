import { router } from '@kit.ArkUI';
import { BottomNavBar } from '../common/components/BottomNavBar';
import { NavigationService } from '../common/services/NavigationService';

@Entry
@Component
struct QaLandingPage {
  @State activeCategory: string = '科技';
  private categories: string[] = ['科技', '生活', '职场', '情感', '人文', '娱乐'];
  private questions: QuestionItemData[] = [
    { title: '无大算力时，作为学生，LLM 还有哪些值得做的研究？' },
    { title: '为什么有钱人皮肤都这么好？' },
    { title: 'DeepSeek-V4 技术报告一手解读来了' }
  ];
  private bottomTabs: string[] = ['首页', '直答', '+', '消息', '我的'];

  aboutToAppear(): void {
  }

  onBottomTabTap(tab: string): void {
    switch (tab) {
      case '首页':
        router.replaceUrl({ url: NavigationService.routeFor('首页信息流') });
        break;
      case '直答':
        // Already on this page
        break;
      case '+':
        router.pushUrl({ url: NavigationService.routeFor('内容编辑器') });
        break;
      case '消息':
        router.replaceUrl({ url: NavigationService.routeFor('消息列表') });
        break;
      case '我的':
        router.replaceUrl({ url: NavigationService.routeFor('个人中心') });
        break;
    }
  }

  onInputBarTap(): void {
    router.pushUrl({ url: NavigationService.routeFor('内容编辑器') });
  }

  build() {
    Column() {
      // Top Navigation Bar
      Row() {
        Text('≡')
          .fontSize(22)
          .fontColor('#333333')
          .width(40)
          .textAlign(TextAlign.Center)
        Blank()
        Text('知乎')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')
        Blank()
        Text('📖')
          .fontSize(20)
          .width(40)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(48)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#FFFFFF')

      // Scrollable Content Area
      Scroll() {
        Column() {
          // Hero Section
          Column() {
            Text('用提问发现世界')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A2E')
              .textAlign(TextAlign.Center)
            Text('有问题就会有答案')
              .fontSize(15)
              .fontColor('#888888')
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          }
          .width('100%')
          .padding({ top: 32, bottom: 28 })
          .backgroundColor('#F0F4FF')

          // Question List Section
          Column() {
            Text('热门问题')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111111')
              .padding({ left: 16, top: 16, bottom: 12 })
              .width('100%')

            ForEach(this.questions, (item: QuestionItemData, index: number) => {
              Column() {
                Row() {
                  Text(item.title)
                    .fontSize(15)
                    .fontColor('#333333')
                    .lineHeight(22)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                  Text('>')
                    .fontSize(16)
                    .fontColor('#BBBBBB')
                    .margin({ left: 8 })
                }
                .width('100%')
                .padding({ top: 14, bottom: 14, left: 16, right: 16 })
                .alignItems(VerticalAlign.Center)

                if (index < this.questions.length - 1) {
                  Divider()
                    .color('#F0F0F0')
                    .margin({ left: 16, right: 16 })
                }
              }
              .width('100%')
              .backgroundColor('#FFFFFF')
            })
          }
          .width('100%')
          .margin({ top: 12, left: 12, right: 12 })
          .borderRadius(12)
          .backgroundColor('#FFFFFF')

          // Knowledge Card Section
          Column() {
            Row() {
              Text('推荐知识库')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111111')
              Blank()
              Text('知识广场 >')
                .fontSize(13)
                .fontColor('#4A6CF7')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 10 })

            Row() {
              // Thumbnail placeholder
              Column() {
                Text('🧠')
                  .fontSize(36)
              }
              .width(64)
              .height(64)
              .borderRadius(8)
              .backgroundColor('#E8EEFF')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)

              Column() {
                Text('LLM推理框架与性能优化')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#111111')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text('LLM推理基础知识, vLLM、SGLang框...')
                  .fontSize(12)
                  .fontColor('#888888')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 4 })
                Row() {
                  Text('kaiyuan')
                    .fontSize(11)
                    .fontColor('#4A6CF7')
                  Text(' · 250人订阅 · 48个内容')
                    .fontSize(11)
                    .fontColor('#AAAAAA')
                }
                .margin({ top: 4 })
              }
              .margin({ left: 12 })
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 14 })

            // Pagination dots
            Row() {
              ForEach([0, 1, 2, 3, 4, 5], (dotIndex: number) => {
                Circle()
                  .width(dotIndex === 0 ? 7 : 5)
                  .height(dotIndex === 0 ? 7 : 5)
                  .fill(dotIndex === 0 ? '#4A6CF7' : '#D0D0D0')
                  .margin({ left: 3, right: 3 })
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ bottom: 16 })
          }
          .width('100%')
          .margin({ top: 12, left: 12, right: 12 })
          .borderRadius(12)
          .backgroundColor('#FFFFFF')

          // Category Buttons Row
          Scroll() {
            Row({ space: 10 }) {
              ForEach(this.categories, (cat: string) => {
                Text(cat)
                  .fontSize(14)
                  .fontWeight(this.activeCategory === cat ? FontWeight.Bold : FontWeight.Regular)
                  .fontColor(this.activeCategory === cat ? '#FFFFFF' : '#333333')
                  .padding({ left: 18, right: 18, top: 8, bottom: 8 })
                  .borderRadius(20)
                  .backgroundColor(this.activeCategory === cat ? '#4A6CF7' : '#F5F5F5')
                  .onClick(() => {
                    this.activeCategory = cat;
                  })
              })
            }
            .padding({ left: 12, right: 12 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
          .margin({ top: 12 })

          // Bottom spacer for the fixed input bar
          Blank()
            .height(64)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // Bottom Input Bar
      Row() {
        Row() {
          Text('🎤')
            .fontSize(16)
            .margin({ left: 12 })
          Text('请输入你的问题')
            .fontSize(14)
            .fontColor('#AAAAAA')
            .layoutWeight(1)
            .margin({ left: 8 })
          Text('📎')
            .fontSize(16)
            .margin({ right: 12 })
        }
        .width('100%')
        .height(40)
        .borderRadius(20)
        .backgroundColor('#F5F5F5')
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.onInputBarTap();
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')

      // Bottom Navigation Bar
      Row() {
        ForEach(this.bottomTabs, (tab: string) => {
          Column() {
            if (tab === '+') {
              // Center FAB style for '+'
              Text(tab)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .width(40)
                .height(40)
                .borderRadius(20)
                .backgroundColor('#4A6CF7')
                .textAlign(TextAlign.Center)
            } else {
              Text(this.tabIcon(tab))
                .fontSize(18)
                .fontColor(tab === '直答' ? '#4A6CF7' : '#888888')
              Text(tab)
                .fontSize(10)
                .fontColor(tab === '直答' ? '#4A6CF7' : '#888888')
                .margin({ top: 2 })
                .fontWeight(tab === '直答' ? FontWeight.Bold : FontWeight.Regular)
            }
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.onBottomTabTap(tab);
          })
        })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .padding({ bottom: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F6F6')
  }

  tabIcon(tab: string): string {
    switch (tab) {
      case '首页':
        return '🏠';
      case '直答':
        return '💡';
      case '消息':
        return '🔔';
      case '我的':
        return '👤';
      default:
        return '';
    }
  }
}

interface QuestionItemData {
  title: string;
}
