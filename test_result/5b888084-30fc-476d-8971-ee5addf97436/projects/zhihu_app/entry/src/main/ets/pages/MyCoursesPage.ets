import { router } from '@kit.ArkUI';

interface CourseCardData {
  title: string;
  author: string;
  price: string;
  status: string;
}

@Entry
@Component
struct MyCoursesPage {
  @State private activeTabIndex: number = 1; // 0: 课程专区, 1: 我的课程

  private courseList: CourseCardData[] = [
    {
      title: '短篇故事变现速成班',
      author: '知乎知学堂',
      price: '¥1.00',
      status: '已订阅'
    },
    {
      title: '一节课搞懂大模型应用开发',
      author: '知乎知学堂',
      price: '¥1.00',
      status: '已订阅'
    },
    {
      title: '零基础 AI 视频应用变现实战',
      author: '知乎知学堂',
      price: '¥1.00',
      status: '已订阅'
    },
    {
      title: '推广达人变现方案',
      author: '知乎知学堂',
      price: '¥1.00',
      status: '已订阅'
    }
  ];

  build() {
    Column() {
      // ── Top Navigation Bar ──
      this.buildNavBar();

      // ── Scrollable Content ──
      Scroll() {
        Column() {
          // ── Empty State ──
          this.buildEmptyState();

          // ── Recommendation Section Header ──
          this.buildSectionHeader();

          // ── Course Card List ──
          this.buildCourseCardList();

          // Bottom spacer for tab bar clearance
          Blank().height(16);
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      // ── Bottom Tab Bar (local, course module specific) ──
      this.buildBottomTabBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // ─── Navigation Bar ───
  @Builder
  buildNavBar() {
    Row() {
      // Back button
      Text('\uE0D9')
        .fontSize(28)
        .fontColor('#1A1A1A')
        .padding({ left: 16, right: 12, top: 12, bottom: 12 })
        .onClick(() => {
          router.back();
        })

      // Title
      Text('我的课程')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A1A')

      Blank()
    }
    .width('100%')
    .height(56)
    .backgroundColor('#FFFFFF')
    .border({
      width: { bottom: 0.5 },
      color: '#E5E5E5'
    })
  }

  // ─── Empty State ───
  @Builder
  buildEmptyState() {
    Column() {
      // Astronaut illustration placeholder
      Column() {
        Text('\uE0B1')
          .fontSize(80)
          .fontColor('#B0BEC5')
      }
      .width(120)
      .height(120)
      .borderRadius(60)
      .backgroundColor('#ECEFF1')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 60, bottom: 20 })

      // Empty hint text
      Text('还没有内容')
        .fontSize(16)
        .fontColor('#999999')
        .margin({ bottom: 24 })

      // CTA button "去看看"
      Button('去看看')
        .fontSize(15)
        .fontColor('#1565C0')
        .backgroundColor('#E3F2FD')
        .border({ width: 1, color: '#1565C0', style: BorderStyle.Solid })
        .borderRadius(20)
        .width(120)
        .height(40)
        .padding(0)
        .onClick(() => {
          // Target: 课程发现/推荐页 — no confirmed route available
          console.info('去看看 → 课程发现/推荐页 (route not confirmed)');
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 12 })
  }

  // ─── Section Header "大家还在学" ───
  @Builder
  buildSectionHeader() {
    Row() {
      Text('大家还在学')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 24, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }

  // ─── Course Card List ───
  @Builder
  buildCourseCardList() {
    // Horizontal scrollable row of course cards
    Scroll() {
      Row({ space: 12 }) {
        ForEach(this.courseList, (course: CourseCardData, index: number) => {
          this.buildCourseCard(course, index);
        }, (course: CourseCardData, index: number) => `course_${index}`)
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  // ─── Individual Course Card ───
  @Builder
  buildCourseCard(course: CourseCardData, index: number) {
    Column() {
      // Cover image placeholder
      Column() {
        Text('\uE0B2')
          .fontSize(36)
          .fontColor('#90A4AE')
      }
      .width('100%')
      .height(100)
      .backgroundColor('#ECEFF1')
      .borderRadius({ topLeft: 8, topRight: 8 })
      .justifyContent(FlexAlign.Center)

      // Card info area
      Column() {
        // Title
        Text(course.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 6 })

        // Author
        Row() {
          Text(course.author)
            .fontSize(11)
            .fontColor('#999999')
            .maxLines(1)

          Blank()

          // Price
          Text(course.price)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#E53935')
        }
        .width('100%')
        .margin({ bottom: 6 })

        // Status badge
        Row() {
          Text(course.status)
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor('#4CAF50')
            .borderRadius(3)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 8 })
      .alignItems(HorizontalAlign.Start)
      .backgroundColor('#FFFFFF')
      .borderRadius({ bottomLeft: 8, bottomRight: 8 })
    }
    .width(160)
    .shadow({
      radius: 4,
      color: '#00000015',
      offsetY: 2
    })
    .borderRadius(8)
    .onClick(() => {
      // Target: 课程详情页 — no confirmed route available
      console.info(`课程卡片 "${course.title}" 被点击 → 课程详情页 (route not confirmed)`);
    })
  }

  // ─── Bottom Tab Bar (local, course module specific) ───
  @Builder
  buildBottomTabBar() {
    Row() {
      // Tab: 课程专区
      Column() {
        Text('课程专区')
          .fontSize(14)
          .fontColor(this.activeTabIndex === 0 ? '#1565C0' : '#999999')
      }
      .layoutWeight(1)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .border({
        width: { bottom: this.activeTabIndex === 0 ? 2 : 0 },
        color: this.activeTabIndex === 0 ? '#1565C0' : 'transparent'
      })
      .onClick(() => {
        this.activeTabIndex = 0;
        // Same-page state change: switch to 课程专区 content
        console.info('切换到课程专区 Tab');
      })

      // Tab: 我的课程
      Column() {
        Text('我的课程')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.activeTabIndex === 1 ? '#1565C0' : '#999999')
      }
      .layoutWeight(1)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .border({
        width: { bottom: this.activeTabIndex === 1 ? 2 : 0 },
        color: this.activeTabIndex === 1 ? '#1565C0' : 'transparent'
      })
      .onClick(() => {
        this.activeTabIndex = 1;
        // Already on current tab, no change
      })
    }
    .width('100%')
    .height(50)
    .backgroundColor('#FFFFFF')
    .border({
      width: { top: 0.5 },
      color: '#E5E5E5'
    })
  }
}
