import router from '@ohos.router';

@Entry
@Component
struct PrivacyManagement {
  // Toggle states
  @State showReviews: boolean = true;
  @State showNotes: boolean = true;
  @State showCheckins: boolean = true;
  @State showWechatProfile: boolean = true;
  @State personalizedContent: boolean = true;
  @State personalizedAds: boolean = true;

  // Unresolved labels that should not create real routes
  private unresolvedLabels: Set<string> = new Set([
    '个人信息下载',
    '推荐可能认识的人',
    '解除第三方好友关系',
    '黑名单',
    '允许谁私信我',
    '隐私政策概要',
    '应用权限说明',
    '未成年人保护',
    '清除历史个性记录',
    '我有疑问'
  ]);

  // Confirmed route map
  private routeMap: Record<string, string> = {
    '个人信息查看与管理': 'pages/PersonalInfoManagement',
    '系统权限管理': 'pages/SystemPermissionManagement',
    '隐私政策': 'pages/PrivacyPolicyDetail'
  };

  handleItemTap(label: string): void {
    // Confirmed routes
    if (this.routeMap[label]) {
      router.pushUrl({ url: this.routeMap[label] });
      return;
    }

    // Unresolved items - log only, no real navigation
    if (this.unresolvedLabels.has(label)) {
      console.info(`[PrivacyManagement] ${label} tapped - target page not yet available`);
      return;
    }
  }

  build() {
    Column() {
      // Navigation bar: back button + title
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ left: 16, right: 8, top: 12, bottom: 12 })
          .onClick(() => {
            router.back();
          })

        Text('隐私管理')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')

        Blank()
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center)

      // Divider below nav bar
      Divider()
        .height(0.5)
        .color('#E5E5E5')

      // Scrollable settings list
      Scroll() {
        Column() {
          // ===== Section: 个人信息 =====
          this.buildSectionHeader('个人信息')

          Column() {
            this.buildChevronItem('个人信息查看与管理')
            this.buildItemDivider()
            this.buildChevronItem('个人信息下载')
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          this.buildSectionGap()

          // ===== Section: 系统权限管理 =====
          this.buildSectionHeader('系统权限管理')

          Column() {
            this.buildChevronItem('系统权限管理',
              '为了提供更好的服务，大众点评在某些特定场景下需要向你申请使用系统数据的权限')
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          this.buildSectionGap()

          // ===== Section: 个人主页设置 =====
          this.buildSectionHeader('个人主页设置')

          Column() {
            this.buildToggleItem('在个人主页展示我的评价', this.showReviews,
              (value: boolean) => { this.showReviews = value; })
            this.buildItemDivider()
            this.buildToggleItem('在个人主页展示我的笔记', this.showNotes,
              (value: boolean) => { this.showNotes = value; })
            this.buildItemDivider()
            this.buildToggleItem('在个人主页展示我的打卡', this.showCheckins,
              (value: boolean) => { this.showCheckins = value; })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          this.buildSectionGap()

          // ===== Section: 分享设置 =====
          this.buildSectionHeader('分享设置')

          Column() {
            Row() {
              Column() {
                Text('分享给微信好友展示昵称头像')
                  .fontSize(16)
                  .fontColor('#1A1A1A')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text('微信好友查看你分享的商户和评价时，将看到你的大众点评昵称和头像，并可以关注你；关闭后则不显示。')
                  .fontSize(12)
                  .fontColor('#999999')
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 4 })

                Text('示例 >')
                  .fontSize(13)
                  .fontColor('#007AFF')
                  .margin({ top: 6 })
                  .onClick(() => {
                    console.info('[PrivacyManagement] 示例链接 tapped');
                  })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Toggle({ type: ToggleType.Switch, isOn: this.showWechatProfile })
                .onChange((value: boolean) => {
                  this.showWechatProfile = value;
                })
                .margin({ left: 12 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .alignItems(VerticalAlign.Top)
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          this.buildSectionGap()

          // ===== Section: 关系及互动设置 =====
          this.buildSectionHeader('关系及互动设置')

          Column() {
            this.buildChevronItem('推荐可能认识的人')
            this.buildItemDivider()
            this.buildChevronItem('解除第三方好友关系',
              '解除后通过微信、QQ和通讯录关注的人和粉丝都会被删除')
            this.buildItemDivider()
            this.buildChevronItem('黑名单')
            this.buildItemDivider()
            this.buildChevronItem('允许谁私信我', undefined, '所有人')
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          this.buildSectionGap()

          // ===== Section: 隐私说明 =====
          this.buildSectionHeader('隐私说明')

          Column() {
            this.buildChevronItem('隐私政策')
            this.buildItemDivider()
            this.buildChevronItem('隐私政策概要')
            this.buildItemDivider()
            this.buildChevronItem('应用权限说明')
            this.buildItemDivider()
            this.buildChevronItem('未成年人保护')
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          this.buildSectionGap()

          // ===== Section: 个性化设置 =====
          this.buildSectionHeader('个性化设置')

          Column() {
            // 接收个性化内容推荐
            Row() {
              Column() {
                Text('接收个性化内容推荐')
                  .fontSize(16)
                  .fontColor('#1A1A1A')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text('关闭后将无法收到个性化推荐，建议开启以看到更多感兴趣内容。')
                  .fontSize(12)
                  .fontColor('#999999')
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 4 })

                Text('内容推荐算法说明')
                  .fontSize(13)
                  .fontColor('#007AFF')
                  .margin({ top: 6 })
                  .onClick(() => {
                    console.info('[PrivacyManagement] 内容推荐算法说明 tapped');
                  })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Toggle({ type: ToggleType.Switch, isOn: this.personalizedContent })
                .onChange((value: boolean) => {
                  this.personalizedContent = value;
                })
                .margin({ left: 12 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .alignItems(VerticalAlign.Top)

            this.buildItemDivider()

            // 接收个性化广告推荐
            Row() {
              Column() {
                Text('接收个性化广告推荐')
                  .fontSize(16)
                  .fontColor('#1A1A1A')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text('关闭后仍会看到广告，但相关性会下降，建议开启以过滤更多不感兴趣的广告。')
                  .fontSize(12)
                  .fontColor('#999999')
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 4 })

                Text('广告推荐算法说明')
                  .fontSize(13)
                  .fontColor('#007AFF')
                  .margin({ top: 6 })
                  .onClick(() => {
                    console.info('[PrivacyManagement] 广告推荐算法说明 tapped');
                  })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Toggle({ type: ToggleType.Switch, isOn: this.personalizedAds })
                .onChange((value: boolean) => {
                  this.personalizedAds = value;
                })
                .margin({ left: 12 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .alignItems(VerticalAlign.Top)

            this.buildItemDivider()

            this.buildChevronItem('清除历史个性记录')
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          this.buildSectionGap()

          // ===== Section: 我有疑问 =====
          Column() {
            this.buildChevronItem('我有疑问')
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          // Bottom safe area
          Column()
            .height(32)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // ===== Reusable Builders =====

  @Builder
  buildSectionHeader(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor('#999999')
      .padding({ left: 16, top: 16, bottom: 8 })
      .width('100%')
  }

  @Builder
  buildSectionGap() {
    Column()
      .width('100%')
      .height(10)
      .backgroundColor('#F5F5F5')
  }

  @Builder
  buildItemDivider() {
    Divider()
      .height(0.5)
      .color('#F0F0F0')
      .margin({ left: 16 })
  }

  @Builder
  buildChevronItem(label: string, description?: string, trailingText?: string) {
    Row() {
      Column() {
        Text(label)
          .fontSize(16)
          .fontColor('#1A1A1A')

        if (description) {
          Text(description)
            .fontSize(12)
            .fontColor('#999999')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (trailingText) {
        Text(trailingText)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ right: 4 })
      }

      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.handleItemTap(label);
    })
  }

  @Builder
  buildToggleItem(label: string, isOn: boolean, onChange: (value: boolean) => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#1A1A1A')
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .onChange(onChange)
        .margin({ left: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .alignItems(VerticalAlign.Center)
  }
}
