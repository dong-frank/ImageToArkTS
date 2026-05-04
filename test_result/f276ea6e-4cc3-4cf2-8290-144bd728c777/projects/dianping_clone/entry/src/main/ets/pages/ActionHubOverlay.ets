/**
 * ActionHubOverlay - 功能选择面板 (Bottom Sheet)
 *
 * 底部弹出式功能选择面板，提供快捷操作入口：
 * 打卡、写评价、发笔记、标记好去处、添加商户
 *
 * 由底部Tab栏'+'按钮触发，存在于所有4个主Tab页面之上。
 * 非独立页面路由，为临时浮层/Bottom Sheet。
 */

interface ActionItem {
  id: string;
  icon: string;
  label: string;
  description: string;
  colorGradient: [string, string];
  hasBadge?: boolean;
  badgeText?: string;
}

@Component
export struct ActionHubOverlay {
  @Prop visible: boolean = false;
  onDismiss?: () => void;
  onActionTap?: (actionId: string) => void;

  @State private actionItems: ActionItem[] = [
    {
      id: 'checkin',
      icon: '📍',
      label: '打卡',
      description: '记录足迹，分享生活',
      colorGradient: ['#E8F5E9', '#C8E6C9']
    },
    {
      id: 'write_review',
      icon: '✏️',
      label: '写评价',
      description: '分享消费体验',
      colorGradient: ['#FFF8E1', '#FFECB3']
    },
    {
      id: 'post_note',
      icon: '📝',
      label: '发笔记',
      description: '图文分享好去处',
      colorGradient: ['#FFF3E0', '#FFE0B2'],
      hasBadge: true,
      badgeText: '创作灵感'
    },
    {
      id: 'bookmark_place',
      icon: '🔖',
      label: '标记好去处',
      description: '收藏想去的地方',
      colorGradient: ['#F3E5F5', '#E1BEE7']
    },
    {
      id: 'add_business',
      icon: '🏪',
      label: '添加商户',
      description: '补充商户信息',
      colorGradient: ['#E3F2FD', '#BBDEFB']
    }
  ];

  handleActionTap(actionId: string): void {
    if (this.onActionTap) {
      this.onActionTap(actionId);
    }
  }

  handleDismiss(): void {
    if (this.onDismiss) {
      this.onDismiss();
    }
  }

  handleBackdropTap(): void {
    this.handleDismiss();
  }

  build() {
    if (!this.visible) {
      return;
    }

    Stack() {
      // Semi-transparent backdrop
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.handleBackdropTap();
        })

      // Bottom Sheet panel
      Column() {
        // Drag handle indicator
        Row() {
          Row()
            .width(36)
            .height(4)
            .borderRadius(2)
            .backgroundColor('#E0E0E0')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 12, bottom: 8 })

        // Action cards
        Column({ space: 10 }) {
          ForEach(this.actionItems, (item: ActionItem, index: number) => {
            this.buildActionCard(item)
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 8 })

        // Close button
        Row() {
          Text('×')
            .fontSize(28)
            .fontColor('#333333')
            .fontWeight(FontWeight.Regular)
        }
        .width(44)
        .height(44)
        .borderRadius(22)
        .backgroundColor('#F5F5F5')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.handleDismiss();
        })

        // Bottom safe area padding
        Row()
          .width('100%')
          .height(20)
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .padding({ bottom: 8 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(1000)
  }

  @Builder
  buildActionCard(item: ActionItem): void {
    Row() {
      // Icon area
      Row() {
        Text(item.icon)
          .fontSize(28)
      }
      .width(48)
      .height(48)
      .borderRadius(12)
      .backgroundColor(item.colorGradient[0])
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // Text content
      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(item.label)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222222')

          if (item.hasBadge && item.badgeText) {
            Text(item.badgeText)
              .fontSize(10)
              .fontColor('#FFFFFF')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(8)
              .backgroundColor('#9C27B0')
          }
        }

        Text(item.description)
          .fontSize(13)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      // Chevron
      Text('›')
        .fontSize(22)
        .fontColor('#CCCCCC')
        .fontWeight(FontWeight.Light)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .borderRadius(12)
    .backgroundColor(item.colorGradient[1])
    .onClick(() => {
      this.handleActionTap(item.id);
    })
  }
}
