import { router } from '@kit.ArkUI';

// ─── Data Types ───

interface CategoryItem {
  icon: string;
  label: string;
}

interface ConsultantData {
  avatarChar: string;
  name: string;
  consultationCount: string;
  rating: number;
  price: string;
  bio: string;
}

// ─── Page Component ───

@Entry
@Component
struct PaidConsultationPage {
  @State activeMainTab: string = '答主';
  @State activeBottomTab: string = '咨询广场';
  @State selectedCategoryIndex: number = -1;
  @State searchText: string = '';

  private mainTabs: string[] = ['答主', '问题'];

  private categories: CategoryItem[] = [
    { icon: '\uE8F1', label: '情感' },
    { icon: '\uE8EE', label: '心理' },
    { icon: '\uE8F4', label: '法律' },
    { icon: '\uE8EB', label: '职场' },
    { icon: '\uE8F3', label: '教育' },
    { icon: '\uE8ED', label: '健康' },
    { icon: '\uE8EF', label: '星座' },
    { icon: '\uE8EC', label: '亲子' },
  ];

  private consultants: ConsultantData[] = [
    {
      avatarChar: '律',
      name: '黑猫律师',
      consultationCount: '19721 次咨询',
      rating: 5.0,
      price: '¥30 咨询',
      bio: '【专业背景】经济学学士、法律硕士、法律职业资格、律师。多年治安、刑事案件办理经验、...'
    },
    {
      avatarChar: 'C',
      name: 'cxy1985',
      consultationCount: '307 次咨询',
      rating: 5.0,
      price: '¥10 咨询',
      bio: '大学老师，生物男博士，发表论文十五篇，指导本科生毕业接近50人，指导硕士毕业2人（联合...'
    },
    {
      avatarChar: '法',
      name: '法律答疑',
      consultationCount: '9511 次咨询',
      rating: 4.9,
      price: '¥18 咨询',
      bio: '【专业背景】法律专业过硬，通过法律职业资格证 拥有长期丰富的一线执法办案经验 派出...'
    }
  ];

  build() {
    Column() {
      // ── Top Navigation Bar ──
      this.buildTopNavBar();

      Divider()
        .color('#F0F0F0')
        .width('100%');

      // ── Search Bar ──
      this.buildSearchBar();

      Divider()
        .color('#F0F0F0')
        .width('100%');

      // ── Main Tab Switcher (答主/问题) ──
      this.buildMainTabs();

      Divider()
        .color('#F0F0F0')
        .width('100%');

      // ── Scrollable Content Area ──
      Scroll() {
        Column() {
          // ── 5×2 Category Grid ──
          this.buildCategoryGrid();

          Divider()
            .color('#F8F8F8')
            .width('100%')
            .height(8);

          // ── Recommended Section Header ──
          if (this.activeMainTab === '答主') {
            this.buildSectionHeader('推荐答主');

            // ── Consultant Cards ──
            Column() {
              ForEach(this.consultants, (consultant: ConsultantData) => {
                this.buildConsultantCard(consultant);
                Divider()
                  .color('#F5F5F5')
                  .width('100%')
                  .margin({ left: 16, right: 16 });
              })
            }
            .width('100%')
            .backgroundColor('#FFFFFF');
          } else {
            // 问题 Tab - placeholder
            this.buildEmptyState('暂无推荐问题');
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')
      .edgeEffect(EdgeEffect.Spring)

      Divider()
        .color('#F0F0F0')
        .width('100%');

      // ── Local Bottom 2-Tab Navigation ──
      this.buildBottomTabs();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  // ─── Top Navigation Bar ───
  @Builder
  buildTopNavBar() {
    Row() {
      // Back button
      Text('\uE8D8')
        .fontSize(20)
        .fontColor('#333333')
        .padding({ left: 12, right: 8, top: 12, bottom: 12 })
        .onClick(() => {
          router.back();
        })

      // Title
      Text('知乎付费咨询')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#111111')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // Search icon
      Text('\uE8C8')
        .fontSize(20)
        .fontColor('#333333')
        .padding({ left: 8, right: 12, top: 12, bottom: 12 })
        .onClick(() => {
          console.info('[PaidConsultationPage] 点击搜索图标 - 进入搜索页');
        })
    }
    .width('100%')
    .height(48)
    .backgroundColor('#FFFFFF')
    .alignItems(VerticalAlign.Center)
  }

  // ─── Search Bar ───
  @Builder
  buildSearchBar() {
    Row() {
      Text('\uE8C8')
        .fontSize(16)
        .fontColor('#999999')
        .margin({ left: 12, right: 6 })

      Text('搜索咨询师或问题')
        .fontSize(14)
        .fontColor('#B3B3B3')
        .layoutWeight(1)

      Text('\uE90A')
        .fontSize(16)
        .fontColor('#999999')
        .margin({ left: 6, right: 12 })
    }
    .width('100%')
    .height(40)
    .backgroundColor('#F5F5F5')
    .borderRadius(20)
    .margin({ left: 12, right: 12, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      console.info('[PaidConsultationPage] 搜索框点击 - 进入搜索页');
    })
  }

  // ─── Main Tabs (答主/问题) ───
  @Builder
  buildMainTabs() {
    Row({ space: 0 }) {
      ForEach(this.mainTabs, (tab: string) => {
        Column() {
          Text(tab)
            .fontSize(15)
            .fontWeight(this.activeMainTab === tab ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(this.activeMainTab === tab ? '#111111' : '#666666')
            .padding({ left: 20, right: 20, top: 12, bottom: 8 })

          // Active underline indicator
          if (this.activeMainTab === tab) {
            Divider()
              .width(24)
              .height(3)
              .color('#0088FF')
              .borderRadius(1.5)
          } else {
            Divider()
              .width(24)
              .height(3)
              .color(Color.Transparent)
              .borderRadius(1.5)
          }
        }
        .onClick(() => {
          this.activeMainTab = tab;
        })
      })

      Blank()
    }
    .width('100%')
    .padding({ left: 8, right: 8 })
    .backgroundColor('#FFFFFF')
  }

  // ─── Category Grid ───
  @Builder
  buildCategoryGrid() {
    Column() {
      Grid() {
        ForEach(this.categories, (item: CategoryItem, index: number) => {
          GridItem() {
            Column({ space: 8 }) {
              // Icon circle
              Stack() {
                Circle()
                  .width(44)
                  .height(44)
                  .fill(this.selectedCategoryIndex === index ? '#E8F4FF' : '#F5F7FA')
                Text(item.icon)
                  .fontSize(22)
                  .fontColor(this.selectedCategoryIndex === index ? '#0088FF' : '#666666')
              }

              Text(item.label)
                .fontSize(11)
                .fontColor(this.selectedCategoryIndex === index ? '#0088FF' : '#666666')
                .maxLines(1)
            }
            .width('100%')
            .padding({ top: 14, bottom: 14 })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.selectedCategoryIndex = index;
              console.info(`[PaidConsultationPage] 分类点击: ${item.label}`);
            })
          }
          .backgroundColor('#FFFFFF')
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .rowsGap(0)
      .columnsGap(0)
      .width('100%')
      .height(180)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }

  // ─── Section Header ───
  @Builder
  buildSectionHeader(title: string) {
    Row() {
      // Left accent bar
      Divider()
        .width(4)
        .height(16)
        .color('#0088FF')
        .borderRadius(2)

      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111111')
        .margin({ left: 8 })
        .layoutWeight(1)

      Text('更多 >')
        .fontSize(13)
        .fontColor('#999999')
        .padding({ right: 16 })
        .onClick(() => {
          console.info('[PaidConsultationPage] 更多推荐答主');
        })
    }
    .width('100%')
    .padding({ left: 16, right: 0, top: 14, bottom: 10 })
    .backgroundColor('#FFFFFF')
    .alignItems(VerticalAlign.Center)
  }

  // ─── Consultant Card ───
  @Builder
  buildConsultantCard(consultant: ConsultantData) {
    Row() {
      // Left: Avatar
      Stack() {
        Circle()
          .width(48)
          .height(48)
          .fill('#E8F0FE')
        Text(consultant.avatarChar)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0088FF')
      }

      // Middle: Info
      Column({ space: 6 }) {
        // Name row
        Row({ space: 8 }) {
          Text(consultant.name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111111')

          // Verified badge + consultation count
          Row({ space: 3 }) {
            Text('\u2713')
              .fontSize(11)
              .fontColor('#0088FF')
            Text(consultant.consultationCount)
              .fontSize(11)
              .fontColor('#888888')
          }
        }

        // Rating row (stars)
        Row({ space: 2 }) {
          ForEach([1, 2, 3, 4, 5], (star: number) => {
            Text('\u2605')
              .fontSize(13)
              .fontColor(star <= Math.floor(consultant.rating) ? '#FF9500' : '#E0E0E0')
          })
          Text(consultant.rating.toFixed(1))
            .fontSize(12)
            .fontColor('#FF9500')
            .margin({ left: 4 })
        }

        // Bio snippet
        Text(consultant.bio)
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 10 })

      // Right: Price CTA button
      Text(consultant.price)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#0088FF')
        .backgroundColor('#E8F4FF')
        .borderRadius(14)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .onClick(() => {
          console.info(`[PaidConsultationPage] 点击咨询: ${consultant.name} ${consultant.price}`);
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .alignItems(VerticalAlign.Top)
    .onClick(() => {
      console.info(`[PaidConsultationPage] 点击咨询师卡片: ${consultant.name}`);
    })
  }

  // ─── Empty State ───
  @Builder
  buildEmptyState(message: string) {
    Column() {
      Text('📋')
        .fontSize(48)
        .opacity(0.25)
        .margin({ top: 48 })
      Text(message)
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 12 })
    }
    .width('100%')
    .padding({ bottom: 48 })
    .backgroundColor('#FFFFFF')
  }

  // ─── Local Bottom 2-Tab Bar ───
  @Builder
  buildBottomTabs() {
    Row() {
      Column() {
        Text('\uE8B4')
          .fontSize(22)
          .fontColor(this.activeBottomTab === '咨询广场' ? '#0088FF' : '#999999')
        Text('咨询广场')
          .fontSize(11)
          .fontWeight(this.activeBottomTab === '咨询广场' ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.activeBottomTab === '咨询广场' ? '#0088FF' : '#999999')
          .margin({ top: 2 })
      }
      .width('50%')
      .padding({ top: 8, bottom: 8 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.activeBottomTab = '咨询广场';
      })

      Column() {
        Text('\uE8B8')
          .fontSize(22)
          .fontColor(this.activeBottomTab === '我的咨询' ? '#0088FF' : '#999999')
        Text('我的咨询')
          .fontSize(11)
          .fontWeight(this.activeBottomTab === '我的咨询' ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.activeBottomTab === '我的咨询' ? '#0088FF' : '#999999')
          .margin({ top: 2 })
      }
      .width('50%')
      .padding({ top: 8, bottom: 8 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.activeBottomTab = '我的咨询';
      })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .border({
      width: { top: 0.5 },
      color: '#E0E0E0'
    })
  }
}
