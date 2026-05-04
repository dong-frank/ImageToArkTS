import router from '@ohos.router';

interface ContactCategory {
  icon: string;
  label: string;
}

interface EnterpriseItem {
  icon: string;
  label: string;
}

@Entry
@Component
struct ContactsPage {
  @State private searchText: string = '';

  private readonly categories: ContactCategory[] = [
    { icon: '💫', label: '新的朋友' },
    { icon: '💬', label: '仅聊天的朋友' },
    { icon: '👥', label: '群聊' },
    { icon: '🏷️', label: '标签' },
    { icon: '🍃', label: '公众号' },
    { icon: '💎', label: '服务号' },
    { icon: '🏢', label: '企业微信联系人' }
  ];

  private readonly enterpriseItems: EnterpriseItem[] = [
    { icon: '📢', label: '企业微信通知' },
    { icon: '🏫', label: '学校通知' }
  ];

  private readonly alphabet: string[] = [
    'Q', '☆', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
    'H', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'R', 'S', 'T', 'W', 'X', 'Y', 'Z', '#'
  ];

  private readonly bottomTabs: string[] = ['微信', '通讯录', '发现', '我'];

  private handleTabClick(tab: string): void {
    if (tab === '通讯录') {
      return;
    }
    let route: string;
    switch (tab) {
      case '微信':
        route = 'pages/ChatListPage';
        break;
      case '发现':
        route = 'pages/DiscoverPage';
        break;
      case '我':
        route = 'pages/MeProfilePage';
        break;
      default:
        return;
    }
    router.replaceUrl({ url: route });
  }

  private handleCategoryClick(category: ContactCategory): void {
    console.info(`[ContactsPage] 点击分类入口: ${category.label}`);
  }

  private handleEnterpriseClick(item: EnterpriseItem): void {
    console.info(`[ContactsPage] 点击企业入口: ${item.label}`);
  }

  private handleAddPerson(): void {
    console.info('[ContactsPage] 点击添加联系人');
  }

  private getTabIcon(tab: string): string {
    switch (tab) {
      case '微信':
        return '💬';
      case '通讯录':
        return '👥';
      case '发现':
        return '🔍';
      case '我':
        return '👤';
      default:
        return '';
    }
  }

  build() {
    Column() {
      // Top header bar
      Row() {
        Text('通讯录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#191919')
          .layoutWeight(1)

        Text('+')
          .fontSize(22)
          .fontColor('#191919')
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .onClick(() => {
            this.handleAddPerson();
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#EDEDED')

      // Search bar
      Row() {
        Text('🔍')
          .fontSize(14)
          .margin({ right: 6 })

        Text('搜索')
          .fontSize(15)
          .fontColor('#B2B2B2')
      }
      .width('100%')
      .height(36)
      .backgroundColor('#FFFFFF')
      .borderRadius(6)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Start)
      .padding({ left: 12 })
      .margin({ left: 12, right: 12, top: 8, bottom: 8 })

      // Scrollable content area with right-side alphabet index
      Stack({ alignContent: Alignment.End }) {
        Scroll() {
          Column() {
            // Category list section
            Column() {
              ForEach(this.categories, (category: ContactCategory, index: number) => {
                Column() {
                  Row() {
                    Text(category.icon)
                      .fontSize(20)
                      .width(32)
                      .height(32)
                      .textAlign(TextAlign.Center)

                    Text(category.label)
                      .fontSize(16)
                      .fontColor('#191919')
                      .layoutWeight(1)
                      .margin({ left: 12 })

                    Text('>')
                      .fontSize(14)
                      .fontColor('#C0C0C0')
                      .margin({ right: 4 })
                  }
                  .width('100%')
                  .height(52)
                  .alignItems(VerticalAlign.Center)
                  .padding({ left: 16, right: 16 })
                  .onClick(() => {
                    this.handleCategoryClick(category);
                  })

                  if (index < this.categories.length - 1) {
                    Divider()
                      .height(0.5)
                      .color('#EBEBEB')
                      .margin({ left: 60 })
                  }
                }
              })
            }
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 12, right: 12, top: 4, bottom: 12 })

            // "我的企业" section header
            Row() {
              Text('我的企业')
                .fontSize(14)
                .fontColor('#888888')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 8 })

            // Enterprise section
            Column() {
              ForEach(this.enterpriseItems, (item: EnterpriseItem, index: number) => {
                Column() {
                  Row() {
                    Text(item.icon)
                      .fontSize(20)
                      .width(32)
                      .height(32)
                      .textAlign(TextAlign.Center)

                    Text(item.label)
                      .fontSize(16)
                      .fontColor('#191919')
                      .layoutWeight(1)
                      .margin({ left: 12 })

                    Text('>')
                      .fontSize(14)
                      .fontColor('#C0C0C0')
                      .margin({ right: 4 })
                  }
                  .width('100%')
                  .height(52)
                  .alignItems(VerticalAlign.Center)
                  .padding({ left: 16, right: 16 })
                  .onClick(() => {
                    this.handleEnterpriseClick(item);
                  })

                  if (index < this.enterpriseItems.length - 1) {
                    Divider()
                      .height(0.5)
                      .color('#EBEBEB')
                      .margin({ left: 60 })
                  }
                }
              })
            }
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 12, right: 12, bottom: 12 })

            // "星标朋友" section header
            Row() {
              Text('☆ 星标朋友')
                .fontSize(14)
                .fontColor('#888888')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 8 })

            // Starred section - empty state
            Column() {
              Text('暂无星标朋友')
                .fontSize(15)
                .fontColor('#B2B2B2')
            }
            .width('100%')
            .height(80)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 12, right: 12, bottom: 12 })

            // Spacer for bottom nav clearance
            Column()
              .height(20)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None)

        // Right-side alphabet quick index
        Column({ space: 0 }) {
          ForEach(this.alphabet, (letter: string) => {
            Text(letter)
              .fontSize(11)
              .fontColor('#666666')
              .height(17)
              .width(20)
              .textAlign(TextAlign.Center)
          })
        }
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 8, bottom: 8, right: 4 })
        .zIndex(1)
        .margin({ right: 2 })
      }
      .layoutWeight(1)

      // Bottom navigation bar
      Row() {
        ForEach(this.bottomTabs, (tab: string) => {
          Column({ space: 2 }) {
            Text(this.getTabIcon(tab))
              .fontSize(20)
            Text(tab)
              .fontSize(10)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 6, bottom: 6 })
          .onClick(() => {
            this.handleTabClick(tab);
          })
        })
      }
      .width('100%')
      .padding({ top: 4, bottom: 6 })
      .backgroundColor('#F7F7F7')
      .border({ width: { top: 0.5 }, color: '#E0E0E0' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#EDEDED')
  }
}
