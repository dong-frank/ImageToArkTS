import router from '@ohos.router';

interface MemoDetailMenuItem {
  icon: Resource;
  text: string;
  color?: string;
}

interface ShareTargetItem {
  icon: Resource;
  label: string;
}

@Entry
@Component
struct MemoDetail {
  @State isMenuVisible: boolean = false;
  @State isSharePanelVisible: boolean = false;
  @State isAdvancedShareVisible: boolean = false;
  @State isEditMode: boolean = false;
  @State memoContent: string = `交通：一个半小时到虹桥站，出来坐地铁2号线到川沙，倒数第五站
7点20班车，7点40左右到，然后排队第一次安检，第二次安检，8点32左右进来
疯狂动物城
小熊维尼
加勒比海盗-沉落宝藏之战
米奇妙游童话书
胡迪牛仔嘉年华
晶彩奇航
冰雪奇缘：欢唱盛会13:15
爱丽丝梦游
雷鸣山漂流
小勇者营地
古迹探索营绳索挑战道
巴斯光年营救4次
太空对话史迪奇

旋转蜂蜜罐

8.55开车 9.24到
上电梯右转
9.32坐下来`;

  private menuItems: Array<MemoDetailMenuItem> = [
    { icon: $r('sys.media.AI_circle_viewfinder'), text: '扫描' },
    { icon: $r('sys.media.arrowshape_3_triangle_path'), text: '置顶备忘录' },
    { icon: $r('sys.media.person_shield'), text: '锁定' },
    { icon: $r('sys.media.AI_search'), text: '在备忘录中查找' },
    { icon: $r('sys.media.waveform_folder_fill'), text: '移动备忘录' },
    { icon: $r('sys.media.calendar_badge_play'), text: '最近备忘录' },
    { icon: $r('sys.media.AI_form'), text: '数学结果' },
    { icon: $r('sys.media.AI_panels'), text: '横线与网格' },
    { icon: $r('sys.media.rectangle_filled_and_line_horizontal_and_rectangle'), text: '附件视图' },
    { icon: $r('sys.media.balloon_fill'), text: '删除', color: '#FF3B30' }
  ];

  private shareTargetsRow1: Array<ShareTargetItem> = [
    { icon: $r('app.media.startIcon'), label: '微信读书' },
    { icon: $r('sys.media.phone_arrow_down_left_circle_fill'), label: '隔空投送' },
    { icon: $r('sys.media.media_sound'), label: '信息' },
    { icon: $r('sys.media.rectangle_and_line_horizontal_and_rectangle_filled'), label: '邮件' },
    { icon: $r('app.media.startIcon'), label: '手记' }
  ];

  private shareTargetsRow2: Array<ShareTargetItem> = [
    { icon: $r('sys.media.anahs_notification_icon'), label: '拷贝' },
    { icon: $r('sys.media.arrowshape_3_triangle_path'), label: '导出为 Markdown' },
    { icon: $r('sys.media.textformat_size_square_fill'), label: '标记' },
    { icon: $r('sys.media.AI_panels'), label: '更多' }
  ];

  private advancedShareOptions: Array<MemoDetailMenuItem> = [
    { icon: $r('sys.media.waveform_folder_fill'), text: '保存到“文件”' },
    { icon: $r('app.media.startIcon'), text: '导入到微信读书' },
    { icon: $r('sys.media.lamp_ceiling'), text: '使用百度网盘在线查看' },
    { icon: $r('sys.media.rectangle_filled_and_line_horizontal_and_rectangle'), text: '文档处理' },
    { icon: $r('sys.media.AI_read_aloud'), text: '文档转 AI 播客' },
    { icon: $r('sys.media.Celia'), text: '用 AI 帮我读' }
  ];

  @Builder
  TopNavBar() {
    Row({ space: 12 }) {
      Button('<')
        .fontSize(20)
        .fontColor('#000000')
        .backgroundColor('#F5F5F5')
        .width(40)
        .height(40)
        .borderRadius(20)
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/MemoList' })
            .then(() => {})
            .catch((err: Error) => {});
        })

      Text('迪士尼')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Button('📤')
        .fontSize(18)
        .fontColor('#000000')
        .backgroundColor('#F5F5F5')
        .width(40)
        .height(40)
        .borderRadius(20)
        .onClick(() => {
          this.isSharePanelVisible = true;
        })

      Button('...')
        .fontSize(18)
        .fontColor('#000000')
        .backgroundColor('#F5F5F5')
        .width(40)
        .height(40)
        .borderRadius(20)
        .onClick(() => {
          this.isMenuVisible = !this.isMenuVisible;
        })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ContentArea() {
    Scroll() {
      Text(this.memoContent)
        .fontSize(16)
        .fontColor('#333333')
        .textAlign(TextAlign.Start)
        .width('100%')
        .padding(16)
    }
    .height('70%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  BottomToolbar() {
    Row({ space: 20 }) {
      Button('≡·')
        .fontSize(20)
        .fontColor('#000000')
        .backgroundColor('#F5F5F5')
        .width(44)
        .height(44)
        .borderRadius(22)
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/MemoDetail_draw' })
            .then(() => {})
            .catch((err: Error) => {});
        })

      Button('📎')
        .fontSize(20)
        .fontColor('#000000')
        .backgroundColor('#F5F5F5')
        .width(44)
        .height(44)
        .borderRadius(22)
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/MemoDetail_attach' })
            .then(() => {})
            .catch((err: Error) => {});
        })

      Button('A')
        .fontSize(20)
        .fontColor('#000000')
        .backgroundColor('#F5F5F5')
        .width(44)
        .height(44)
        .borderRadius(22)
        .onClick(() => {})

      Blank()
        .layoutWeight(1)

      Button('✏️')
        .fontSize(20)
        .fontColor('#FFFFFF')
        .backgroundColor('#007AFF')
        .width(44)
        .height(44)
        .borderRadius(22)
        .onClick(() => {
          this.isEditMode = true;
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor('#F9F9F9')
    .borderRadius(12)
  }

  @Builder
  MoreMenu() {
    Column() {
      ForEach(this.menuItems, (item: MemoDetailMenuItem) => {
        Row({ space: 12 }) {
          Image(item.icon)
            .width(20)
            .height(20)
            .fillColor('#333333')
          Text(item.text)
            .fontSize(16)
            .fontColor(item.color ? item.color : '#333333')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .onClick(() => {
          if (item.text === '删除') {
          } else if (item.text === '附件视图') {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/MemoDetail_attach' })
              .then(() => {})
              .catch((err: Error) => {});
          }
          this.isMenuVisible = false;
        })
      })
    }
    .width(200)
    .padding(8)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 12, color: '#1A000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  SharePanel() {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        Image($r('app.media.startIcon'))
          .width(40)
          .height(40)
          .borderRadius(8)
        Column({ space: 4 }) {
          Text('迪士尼')
            .fontSize(16)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
          Text('备忘录')
            .fontSize(14)
            .fontColor('#666666')
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      Row({ space: 20 }) {
        ForEach(this.shareTargetsRow1, (item: ShareTargetItem) => {
          Column({ space: 4 }) {
            Button('')
              .width(56)
              .height(56)
              .borderRadius(28)
              .backgroundColor('#F0F0F0')
              .onClick(() => {})
            Text(item.label)
              .fontSize(12)
              .fontColor('#666666')
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)

      Row({ space: 20 }) {
        ForEach(this.shareTargetsRow2, (item: ShareTargetItem) => {
          Column({ space: 4 }) {
            Button('')
              .width(56)
              .height(56)
              .borderRadius(28)
              .backgroundColor('#F0F0F0')
              .onClick(() => {
                if (item.label === '更多') {
                  this.isAdvancedShareVisible = !this.isAdvancedShareVisible;
                }
              })
            Text(item.label)
              .fontSize(12)
              .fontColor('#666666')
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)

      if (this.isAdvancedShareVisible) {
        Column({ space: 0 }) {
          ForEach(this.advancedShareOptions, (item: MemoDetailMenuItem) => {
            Row({ space: 12 }) {
              Image(item.icon)
                .width(20)
                .height(20)
                .fillColor('#333333')
              Text(item.text)
                .fontSize(16)
                .fontColor('#333333')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .onClick(() => {
              this.isAdvancedShareVisible = false;
              this.isSharePanelVisible = false;
            })
          })
        }
        .width('100%')
        .margin({ top: 16 })
        .backgroundColor('#F9F9F9')
        .borderRadius(12)
      }
    }
    .width('90%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 24, color: '#1A000000', offsetX: 0, offsetY: 8 })
  }

  @Builder
  EditModeView() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Button('✓')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .width(36)
          .height(36)
          .borderRadius(18)
          .onClick(() => {
            this.isEditMode = false;
          })
        TextInput({ placeholder: '查找' })
          .placeholderFont({ size: 16, weight: FontWeight.Normal })
          .placeholderColor('#999999')
          .fontSize(16)
          .fontColor('#333333')
          .backgroundColor('#F0F0F0')
          .height(40)
          .layoutWeight(1)
          .borderRadius(8)
          .padding({ left: 12 })
        Button('↑')
          .fontSize(18)
          .fontColor('#007AFF')
          .backgroundColor('#F0F0F0')
          .width(36)
          .height(36)
          .borderRadius(18)
          .onClick(() => {})
        Button('↓')
          .fontSize(18)
          .fontColor('#007AFF')
          .backgroundColor('#F0F0F0')
          .width(36)
          .height(36)
          .borderRadius(18)
          .onClick(() => {})
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      TextInput({ text: this.memoContent })
        .fontSize(16)
        .fontColor('#333333')
        .backgroundColor('#FFFFFF')
        .width('100%')
        .height('60%')
        .onChange((value: string) => {
          this.memoContent = value;
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  build() {
    Stack() {
      Column() {
        this.TopNavBar()
        if (this.isEditMode) {
          this.EditModeView()
        } else {
          this.ContentArea()
        }
        this.BottomToolbar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')

      if (this.isMenuVisible) {
        Column() {
          this.MoreMenu()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.End)
        .padding({ top: 60, right: 12 })
        .onClick(() => {
          this.isMenuVisible = false;
        })
      }

      if (this.isSharePanelVisible) {
        Column() {
          this.SharePanel()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#80000000')
        .onClick(() => {
          this.isSharePanelVisible = false;
          this.isAdvancedShareVisible = false;
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}