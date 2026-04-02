import router from '@ohos.router';

interface IndexMemoItem {
  id: string;
  title: string;
  subtitle: string;
  type: 'text' | 'handwriting' | 'table' | 'image';
  time: string;
}

interface IndexGroupItem {
  groupName: string;
  memos: Array<IndexMemoItem>;
}

@Entry
@Component
struct Index {
  @State currentView: 'list' | 'gallery' = 'list';
  @State groups: Array<IndexGroupItem> = [
    {
      groupName: '今天',
      memos: [
        { id: '1', title: '迪士尼', subtitle: '11:40 交通：一个半小时到虹桥站，出来坐地...', type: 'text', time: '今天 11:40' }
      ]
    },
    {
      groupName: '过去30天',
      memos: [
        { id: '2', title: '新备忘录', subtitle: '2025/12/26 1个表格', type: 'table', time: '2025/12/26' },
        { id: '3', title: '新备忘录', subtitle: '2025/12/24 1个表格', type: 'table', time: '2025/12/24' }
      ]
    },
    {
      groupName: '2025年',
      memos: [
        { id: '4', title: '这几天听报告…', subtitle: '2025/11/30', type: 'text', time: '2025/11/30' },
        { id: '5', title: '11月28上午', subtitle: '2025/11/28', type: 'text', time: '2025/11/28' },
        { id: '6', title: '枫东菲角', subtitle: '2025/11/4 手写备忘录', type: 'handwriting', time: '2025/11/4' },
        { id: '7', title: '新备忘录', subtitle: '2025/10/15 1个表格', type: 'table', time: '2025/10/15' },
        { id: '8', title: '煲仔饭', subtitle: '2025/9/20', type: 'image', time: '2025/9/20' }
      ]
    }
  ];
  @State isMenuVisible: boolean = false;
  @State sortBy: string = 'latestFirst';
  @State groupByDate: boolean = true;

  @Builder
  TopNavBar() {
    Row({ space: 8 }) {
      Button('<')
        .width(40)
        .height(40)
        .backgroundColor('#FFFFFF')
        .fontColor('#000000')
        .borderRadius(20)
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/Index'
          })
            .then(() => {})
            .catch((err: Error) => {});
        })

      Blank()

      Button('...')
        .width(40)
        .height(40)
        .backgroundColor('#FFFFFF')
        .fontColor('#000000')
        .borderRadius(20)
        .onClick(() => {
          this.isMenuVisible = !this.isMenuVisible;
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  @Builder
  OverflowMenu() {
    if (this.isMenuVisible) {
      Column() {
        Text('画廊视图')
          .fontSize(16)
          .fontColor('#000000')
          .backgroundColor('#F5F5F5')
          .width('100%')
          .padding(12)
          .onClick(() => {
            this.currentView = 'gallery';
            this.isMenuVisible = false;
          })

        Text('选择备忘录')
          .fontSize(16)
          .fontColor('#000000')
          .backgroundColor('#F5F5F5')
          .width('100%')
          .padding(12)
          .onClick(() => {
            this.isMenuVisible = false;
          })

        Text('排序方式')
          .fontSize(16)
          .fontColor('#000000')
          .backgroundColor('#F5F5F5')
          .width('100%')
          .padding(12)
          .onClick(() => {
            this.isMenuVisible = false;
          })

        Text('按日期分组')
          .fontSize(16)
          .fontColor('#000000')
          .backgroundColor('#F5F5F5')
          .width('100%')
          .padding(12)
          .onClick(() => {
            this.groupByDate = !this.groupByDate;
            this.isMenuVisible = false;
          })

        Text('查看附件')
          .fontSize(16)
          .fontColor('#000000')
          .backgroundColor('#F5F5F5')
          .width('100%')
          .padding(12)
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/Attachments'
            })
              .then(() => {})
              .catch((err: Error) => {});
            this.isMenuVisible = false;
          })
      }
      .width(160)
      .border({ width: 1, color: '#E0E0E0' })
      .borderRadius(8)
      .position({ x: '80%', y: 60 })
    }
  }

  @Builder
  MemoListItem(memo: IndexMemoItem) {
    Column({ space: 4 }) {
      Text(memo.title)
        .fontSize(18)
        .fontColor('#000000')
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Text(memo.subtitle)
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F9F9F9')
    .borderRadius(12)
    .onClick(() => {
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/MemoDetail'
      })
        .then(() => {})
        .catch((err: Error) => {});
    })

  }

  @Builder
  MemoGalleryItem(memo: IndexMemoItem) {
    Column({ space: 8 }) {
      if (memo.type === 'handwriting') {
        Image($r('sys.media.AI_form'))
          .width(80)
          .height(80)
          .fillColor('#FF0000')
      } else if (memo.type === 'table') {
        Image($r('sys.media.AI_panels'))
          .width(80)
          .height(80)
          .fillColor('#CCCCCC')
      } else if (memo.type === 'image') {
        Image($r('app.media.startIcon'))
          .width(80)
          .height(80)
      } else {
        Image($r('sys.media.AI_lightbulb_max'))
          .width(80)
          .height(80)
          .fillColor('#CCCCCC')
      }

      Text(memo.title)
        .fontSize(14)
        .fontColor('#000000')
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width(100)
    .padding(8)
    .backgroundColor('#F9F9F9')
    .borderRadius(8)
    .onClick(() => {
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/MemoDetail'
      })
        .then(() => {})
        .catch((err: Error) => {});
    })
  }

  @Builder
  ContentArea() {
    if (this.currentView === 'list') {
      Scroll() {
        Column({ space: 24 }) {
          ForEach(this.groups, (group: IndexGroupItem) => {
            Column({ space: 12 }) {
              Text(group.groupName)
                .fontSize(20)
                .fontColor('#000000')
                .fontWeight(FontWeight.Bold)
                .width('100%')

              Column({ space: 8 }) {
                ForEach(group.memos, (memo: IndexMemoItem) => {
                  this.MemoListItem(memo)
                })
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
          })
        }
        .width('100%')
        .padding({ top: 16, bottom: 80 })
      }
    } else {
      Scroll() {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.groups, (group: IndexGroupItem) => {
            ForEach(group.memos, (memo: IndexMemoItem) => {
              this.MemoGalleryItem(memo)
            })
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 80 })
      }
    }
  }

  @Builder
  BottomBar() {
    Row({ space: 12 }) {
      TextInput({ placeholder: '搜索' })
        .placeholderFont({ size: 16, weight: FontWeight.Normal })
        .width('70%')
        .height(40)
        .backgroundColor('#F0F0F0')
        .borderRadius(20)
        .padding({ left: 16, right: 16 })

      Button('✎')
        .width(50)
        .height(50)
        .backgroundColor('#FFFFFF')
        .fontColor('#000000')
        .borderRadius(25)
        .fontSize(24)
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/NewMemo'
          })
            .then(() => {})
            .catch((err: Error) => {});
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 24 })
    .position({ y: '90%' })
    .backgroundColor('#FFFFFF')
  }

  build() {
    Stack() {
      Column() {
        this.TopNavBar()

        Column({ space: 8 }) {
          Text('备忘录')
            .fontSize(32)
            .fontColor('#000000')
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .textAlign(TextAlign.Center)

          Text('209个备忘录')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .padding({ left: 16 })
        }
        .width('100%')
        .padding({ bottom: 16 })

        this.ContentArea()
      }
      .width('100%')
      .height('100%')

      this.OverflowMenu()

      this.BottomBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}