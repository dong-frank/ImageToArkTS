import router from '@ohos.router';

// --- Data Models ---

interface CheckinRecord {
  date: string;
  weekday: string;
  time: string;
  location: string;
  imageCount: number;
}

interface CalendarDay {
  day: number;
  hasRecord: boolean;
  isToday: boolean;
  imagePreview: boolean;
}

interface UserStats {
  name: string;
  level: string;
  totalCheckins: string;
  cities: string;
  locations: string;
}

// --- Mock Data ---

const USER_STATS: UserStats = {
  name: '猫馋',
  level: 'Lv4',
  totalCheckins: '29次',
  cities: '3个城市',
  locations: '24个'
};

const CALENDAR_HEADER: string[] = ['一', '二', '三', '四', '五', '六', '日'];

const CALENDAR_ROWS: CalendarDay[][] = [
  [
    { day: 1, hasRecord: false, isToday: false, imagePreview: false }
  ],
  [
    { day: 6, hasRecord: false, isToday: false, imagePreview: false },
    { day: 7, hasRecord: false, isToday: false, imagePreview: false },
    { day: 8, hasRecord: false, isToday: false, imagePreview: false },
    { day: 9, hasRecord: false, isToday: false, imagePreview: false },
    { day: 10, hasRecord: true, isToday: false, imagePreview: true },
    { day: 11, hasRecord: false, isToday: false, imagePreview: false },
    { day: 12, hasRecord: false, isToday: false, imagePreview: false }
  ],
  [
    { day: 13, hasRecord: false, isToday: false, imagePreview: false },
    { day: 14, hasRecord: false, isToday: false, imagePreview: false },
    { day: 15, hasRecord: false, isToday: false, imagePreview: false },
    { day: 16, hasRecord: false, isToday: false, imagePreview: false },
    { day: 17, hasRecord: false, isToday: false, imagePreview: false },
    { day: 18, hasRecord: false, isToday: false, imagePreview: false },
    { day: 19, hasRecord: false, isToday: false, imagePreview: false }
  ],
  [
    { day: 20, hasRecord: false, isToday: false, imagePreview: false },
    { day: 21, hasRecord: false, isToday: false, imagePreview: false },
    { day: 22, hasRecord: false, isToday: false, imagePreview: false },
    { day: 23, hasRecord: false, isToday: false, imagePreview: false },
    { day: 24, hasRecord: false, isToday: false, imagePreview: false },
    { day: 25, hasRecord: false, isToday: false, imagePreview: false },
    { day: 26, hasRecord: false, isToday: false, imagePreview: false }
  ],
  [
    { day: 27, hasRecord: false, isToday: false, imagePreview: false },
    { day: 28, hasRecord: false, isToday: false, imagePreview: false },
    { day: 29, hasRecord: false, isToday: false, imagePreview: false },
    { day: 30, hasRecord: false, isToday: true, imagePreview: false }
  ]
];

const FILTER_TABS: string[] = ['全部', '时间', '地点'];

const MOCK_RECORDS: CheckinRecord[] = [
  {
    date: '4月10日',
    weekday: '周五',
    time: '17:02',
    location: '鮨鸟歡·烧鸟 yakitori',
    imageCount: 3
  }
];

const MONTH_TABS: string[] = ['4月', '3月', '2月'];

// --- Main Component ---

@Entry
@Component
struct MyCheckin {
  @State selectedMonthIndex: number = 0;
  @State selectedFilterIndex: number = 0;

  build() {
    Stack() {
      Column() {
        // --- Navigation Bar ---
        Row() {
          Text('←')
            .fontSize(22)
            .fontColor('#333333')
            .padding({ left: 4, right: 12 })
            .onClick(() => {
              router.back();
            })

          Text('我的打卡')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')

          Blank()
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')

        // --- Scrollable Content ---
        Scroll() {
          Column() {
            // --- User Summary Card ---
            Column() {
              Row() {
                // Avatar area
                Column() {
                  Stack() {
                    // Avatar placeholder
                    Row() {
                      Text('猫')
                        .fontSize(20)
                        .fontColor('#FFFFFF')
                        .fontWeight(FontWeight.Bold)
                    }
                    .width(52)
                    .height(52)
                    .borderRadius(26)
                    .backgroundColor('#FF8C42')
                    .justifyContent(FlexAlign.Center)
                  }
                  .alignContent(Alignment.Center)

                  // Level badge
                  Text(USER_STATS.level)
                    .fontSize(10)
                    .fontColor('#FFFFFF')
                    .backgroundColor('#FF6B35')
                    .borderRadius(8)
                    .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                    .margin({ top: -8 })
                }
                .alignItems(HorizontalAlign.Center)

                // User name
                Text(USER_STATS.name)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1A1A1A')
                  .margin({ left: 12 })

                Blank()

                // Stats row
                Row({ space: 24 }) {
                  Column() {
                    Text(USER_STATS.totalCheckins)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#1A1A1A')
                    Text('累计打卡')
                      .fontSize(11)
                      .fontColor('#999999')
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Center)

                  Column() {
                    Text(USER_STATS.cities)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#1A1A1A')
                    Text('遍布')
                      .fontSize(11)
                      .fontColor('#999999')
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Center)

                  Column() {
                    Text(USER_STATS.locations)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#1A1A1A')
                    Text('地点')
                      .fontSize(11)
                      .fontColor('#999999')
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Center)
                }
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              // 打卡地图 link
              Row() {
                Text('打卡地图')
                  .fontSize(13)
                  .fontColor('#666666')
                Text(' >')
                  .fontSize(13)
                  .fontColor('#999999')
              }
              .margin({ top: 12 })
              .onClick(() => {
                console.info('[MyCheckin] 打卡地图入口 - 目标页未覆盖');
              })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ left: 12, right: 12, top: 8 })

            // --- Calendar Section ---
            Column() {
              // Month tabs
              Row({ space: 0 }) {
                ForEach(MONTH_TABS, (month: string, index: number) => {
                  Text(month)
                    .fontSize(15)
                    .fontWeight(this.selectedMonthIndex === index ? FontWeight.Bold : FontWeight.Normal)
                    .fontColor(this.selectedMonthIndex === index ? '#1A1A1A' : '#999999')
                    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                    .onClick(() => {
                      this.selectedMonthIndex = index;
                    })
                })
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)

              // Calendar grid
              Column() {
                // Header row
                Row() {
                  ForEach(CALENDAR_HEADER, (day: string) => {
                    Text(day)
                      .fontSize(12)
                      .fontColor('#999999')
                      .width('14.28%')
                      .textAlign(TextAlign.Center)
                      .padding({ top: 8, bottom: 8 })
                  })
                }
                .width('100%')

                // Day rows
                ForEach(CALENDAR_ROWS, (row: CalendarDay[]) => {
                  Row() {
                    ForEach(row, (cell: CalendarDay) => {
                      Column() {
                        if (cell.hasRecord && cell.imagePreview) {
                          Stack() {
                            Row()
                              .width(28)
                              .height(28)
                              .borderRadius(14)
                              .backgroundColor('#E8F5E9')

                            Text(cell.day.toString())
                              .fontSize(13)
                              .fontColor('#4CAF50')
                              .fontWeight(FontWeight.Medium)
                          }
                        } else if (cell.isToday) {
                          Column() {
                            Text('今')
                              .fontSize(10)
                              .fontColor('#4CAF50')
                            Text(cell.day.toString())
                              .fontSize(13)
                              .fontColor('#4CAF50')
                              .fontWeight(FontWeight.Medium)
                          }
                          .width(32)
                          .height(44)
                          .borderRadius(8)
                          .backgroundColor('#E8F5E9')
                          .justifyContent(FlexAlign.Center)
                          .alignItems(HorizontalAlign.Center)
                        } else {
                          Text(cell.day.toString())
                            .fontSize(13)
                            .fontColor('#333333')
                            .width(28)
                            .height(28)
                            .textAlign(TextAlign.Center)
                        }
                      }
                      .width('14.28%')
                      .height(48)
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                      .onClick(() => {
                        console.info('[MyCheckin] 日历日期点击 - 同页内容筛选');
                      })
                    })
                  }
                  .width('100%')
                })
              }
              .width('100%')
              .margin({ top: 8 })

              // Monthly stats
              Row({ space: 32 }) {
                Column() {
                  Text('1')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1A1A1A')
                  Text('打卡次数')
                    .fontSize(11)
                    .fontColor('#999999')
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Center)

                Column() {
                  Text('1')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1A1A1A')
                  Text('打卡天数')
                    .fontSize(11)
                    .fontColor('#999999')
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Center)
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .margin({ top: 12 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ left: 12, right: 12, top: 8 })

            // --- Highlight Section ---
            Column() {
              Text('高光时刻')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A1A')
                .width('100%')

              // Highlight card
              Row() {
                Column() {
                  Text('刷新最常打卡的地点')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#1A1A1A')
                  Text('高达 3 次！')
                    .fontSize(13)
                    .fontColor('#FF6B35')
                    .fontWeight(FontWeight.Medium)
                    .margin({ top: 4 })
                  Text('鮨鸟歡·烧鸟 yakitori 4月10日')
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // Image placeholder
                Row()
                  .width(72)
                  .height(72)
                  .borderRadius(8)
                  .backgroundColor('#FFF3E0')
                  .justifyContent(FlexAlign.Center)
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FAFAFA')
              .borderRadius(10)
              .margin({ top: 10 })
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ left: 12, right: 12, top: 8 })

            // --- First Experience Section ---
            Column() {
              Row() {
                Text('打卡初体验')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A1A1A')
                Text(' 16')
                  .fontSize(14)
                  .fontColor('#999999')
                Text(' >')
                  .fontSize(14)
                  .fontColor('#999999')
                Blank()
              }
              .width('100%')
              .onClick(() => {
                console.info('[MyCheckin] 打卡初体验入口 - 目标页未覆盖');
              })

              // Horizontal scroll cards
              Scroll() {
                Row({ space: 10 }) {
                  // Card 1: 顺德菜
                  Column() {
                    Text('第一次打卡')
                      .fontSize(11)
                      .fontColor('#999999')
                    Text('顺德菜')
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#1A1A1A')
                      .margin({ top: 4 })
                    Text('新品上新')
                      .fontSize(10)
                      .fontColor('#FFFFFF')
                      .backgroundColor('#4A90D9')
                      .borderRadius(4)
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .margin({ top: 6 })
                  }
                  .width(120)
                  .padding(12)
                  .backgroundColor('#FAFAFA')
                  .borderRadius(10)
                  .alignItems(HorizontalAlign.Start)

                  // Card 2: 菌菇火锅
                  Column() {
                    Text('第一次打卡')
                      .fontSize(11)
                      .fontColor('#999999')
                    Text('菌菇火锅')
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#1A1A1A')
                      .margin({ top: 4 })
                  }
                  .width(120)
                  .padding(12)
                  .backgroundColor('#FAFAFA')
                  .borderRadius(10)
                  .alignItems(HorizontalAlign.Start)
                }
                .padding({ left: 2, right: 2 })
              }
              .scrollable(ScrollDirection.Horizontal)
              .scrollBar(BarState.Off)
              .margin({ top: 10 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ left: 12, right: 12, top: 8 })

            // --- All Checkin Records Section ---
            Column() {
              Text('全部打卡记录')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A1A')
                .width('100%')

              // Filter bar
              Row({ space: 8 }) {
                ForEach(FILTER_TABS, (filter: string, index: number) => {
                  Text(filter)
                    .fontSize(13)
                    .fontColor(this.selectedFilterIndex === index ? '#FF6B35' : '#666666')
                    .fontWeight(this.selectedFilterIndex === index ? FontWeight.Medium : FontWeight.Normal)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(14)
                    .backgroundColor(this.selectedFilterIndex === index ? '#FFF3E0' : '#F5F5F5')
                    .onClick(() => {
                      this.selectedFilterIndex = index;
                      console.info('[MyCheckin] 筛选标签点击 - 同页状态变化');
                    })
                })

                Blank()

                // Search icon
                Text('🔍')
                  .fontSize(16)
              }
              .width('100%')
              .margin({ top: 12 })

              // Record list
              ForEach(MOCK_RECORDS, (record: CheckinRecord) => {
                Column() {
                  Row() {
                    Column() {
                      Text(`${record.date} ${record.weekday} ${record.time}`)
                        .fontSize(14)
                        .fontColor('#1A1A1A')
                      Text(record.location)
                        .fontSize(12)
                        .fontColor('#999999')
                        .margin({ top: 4 })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    Text('...')
                      .fontSize(18)
                      .fontColor('#999999')
                      .padding({ left: 8, right: 4 })
                      .onClick(() => {
                        console.info('[MyCheckin] 记录更多操作');
                      })
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)

                  // Image thumbnails row
                  if (record.imageCount > 0) {
                    Row({ space: 6 }) {
                      ForEach(new Array(record.imageCount), (_: undefined, imgIndex: number) => {
                        Row()
                          .width(64)
                          .height(64)
                          .borderRadius(6)
                          .backgroundColor('#F0F0F0')
                      })
                    }
                    .margin({ top: 8 })
                  }
                }
                .width('100%')
                .padding({ top: 14, bottom: 14 })
                .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
                .onClick(() => {
                  console.info('[MyCheckin] 打卡记录点击 - 打卡详情页未覆盖');
                })
              })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ left: 12, right: 12, top: 8 })

            // Bottom spacer for FAB
            Column()
              .height(80)
          }
          .width('100%')
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // --- FAB: 打卡 ---
      Row() {
        Text('📍')
          .fontSize(18)
          .fontColor('#FFFFFF')
        Text('打卡')
          .fontSize(15)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
          .margin({ left: 4 })
      }
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .backgroundColor('#FF6B35')
      .borderRadius(24)
      .shadow({ radius: 8, color: '#40000000', offsetY: 2 })
      .position({ right: 20, bottom: 24 })
      .onClick(() => {
        console.info('[MyCheckin] FAB打卡按钮 - 打卡发布页未覆盖');
      })
    }
    .width('100%')
    .height('100%')
  }
}
