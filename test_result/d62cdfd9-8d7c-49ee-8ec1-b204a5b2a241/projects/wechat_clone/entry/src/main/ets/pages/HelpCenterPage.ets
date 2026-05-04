import router from '@ohos.router';

interface CategoryItemData {
  icon: string;
  mainText: string;
  subText: string;
  iconColor: string;
}

@Entry
@Component
struct HelpCenterPage {
  private categories: CategoryItemData[] = [
    {
      icon: '👤',
      mainText: '账号与登录',
      subText: '账号被封、忘记密码、收到安全提醒',
      iconColor: '#07C160'
    },
    {
      icon: '👥',
      mainText: '通讯录',
      subText: '添加好友、删除/拉黑',
      iconColor: '#576B95'
    },
    {
      icon: '📷',
      mainText: '朋友圈',
      subText: '发布方法、权限设置、评论规则',
      iconColor: '#1485EE'
    },
    {
      icon: '☂️',
      mainText: '未成年人模式',
      subText: '如何使用、修改独立密码',
      iconColor: '#FA9D3B'
    },
    {
      icon: '🤝',
      mainText: '关怀模式',
      subText: '听文字消息、调整字体',
      iconColor: '#FA5151'
    },
    {
      icon: '💬',
      mainText: '聊天',
      subText: '备份聊天记录、消息撤回、发起投票',
      iconColor: '#07C160'
    },
    {
      icon: '📹',
      mainText: '视频号',
      subText: '视频审核、互动浏览',
      iconColor: '#FF6B35'
    },
    {
      icon: '💳',
      mainText: '支付',
      subText: '支付限制、自动扣费、绑定银行卡',
      iconColor: '#07C160'
    }
  ];

  onCloseTap(): void {
    router.back();
  }

  onCategoryTap(item: CategoryItemData): void {
    // Category sub-pages not in current 22-page scope — placeholder
    console.info(`Help category tapped: ${item.mainText}`);
  }

  onToolTap(): void {
    console.info('Tool icon tapped');
  }

  onOverflowTap(): void {
    console.info('Overflow menu tapped');
  }

  onSearchTap(): void {
    console.info('AI search triggered');
  }

  onFeedbackTap(): void {
    console.info('Feedback FAB tapped');
  }

  @Builder
  TopBar() {
    Row() {
      Text('×')
        .fontSize(22)
        .fontColor('#333333')
        .fontWeight(FontWeight.Normal)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.onCloseTap();
        })

      Column() {
        Text('帮助与反馈')
          .fontSize(17)
          .fontColor('#191919')
          .fontWeight(FontWeight.Medium)
        Text('kf.qq.com')
          .fontSize(11)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1)

      Text('🔧')
        .fontSize(18)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.onToolTap();
        })

      Text('⋯')
        .fontSize(20)
        .fontColor('#333333')
        .fontWeight(FontWeight.Bold)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.onOverflowTap();
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: 4, right: 4 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#E5E5E5' })
  }

  @Builder
  CategoryItem(item: CategoryItemData, isLast: boolean) {
    Row() {
      Column() {
        Text(item.icon)
          .fontSize(22)
      }
      .width(40)
      .height(40)
      .borderRadius(8)
      .backgroundColor(item.iconColor + '14')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ right: 12 })

      Column() {
        Text(item.mainText)
          .fontSize(16)
          .fontColor('#191919')
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.subText)
          .fontSize(13)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(20)
        .fontColor('#BBBBBB')
        .margin({ left: 8 })
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: isLast ? 0 : 0.5 }, color: '#F0F0F0' })
    .onClick(() => {
      this.onCategoryTap(item);
    })
  }

  @Builder
  BottomSearchArea() {
    Column() {
      Row() {
        Row() {
          Text('🔍')
            .fontSize(14)
            .margin({ right: 6 })
          Text('微信朋友圈怎么发送实况照片？')
            .fontSize(14)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .layoutWeight(1)
        .height(36)
        .padding({ left: 12, right: 8 })
        .backgroundColor('#EDEDED')
        .borderRadius(18)
        .onClick(() => {
          this.onSearchTap();
        })

        Text('问AI')
          .fontSize(13)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
          .padding({ left: 14, right: 14 })
          .height(36)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor('#07C160')
          .margin({ left: 10 })
          .onClick(() => {
            this.onSearchTap();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .backgroundColor('#F5F5F5')
    .border({ width: { top: 0.5 }, color: '#E5E5E5' })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        this.TopBar()

        Scroll() {
          Column() {
            ForEach(this.categories, (item: CategoryItemData, index: number) => {
              this.CategoryItem(item, index === this.categories.length - 1)
            })
          }
          .width('100%')
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
        .scrollBar(BarState.Off)

        this.BottomSearchArea()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      Text('💬 意见反馈')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .padding({ left: 16, right: 16 })
        .height(40)
        .borderRadius(20)
        .backgroundColor('#07C160')
        .shadow({
          radius: 8,
          color: '#33000000',
          offsetX: 0,
          offsetY: 2
        })
        .onClick(() => {
          this.onFeedbackTap();
        })
        .margin({ right: 16, bottom: 80 })
    }
    .width('100%')
    .height('100%')
  }
}
