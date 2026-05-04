import router from '@ohos.router';

@Entry
@Component
struct PrivacyManagementPage {
  @State allowViewFollowing: boolean = true;
  @State allowViewFollowers: boolean = true;
  @State shareNicknameAvatar: boolean = true;

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('<')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })

        Text('隐私管理')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row()
          .width(44)
          .height(44)
      }
      .width('100%')
      .height(48)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#FFFFFF')

      // Scrollable content
      Scroll() {
        Column() {
          // Section: 个人信息
          this.SectionHeader('个人信息')

          Column() {
            this.NavigationItem('个人信息查看与管理', () => {
              router.pushUrl({ url: 'pages/PersonalInfoPage' });
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.NavigationItem('个人信息下载', () => {
              // Navigate to personal info download
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 12, right: 12 })

          // Section: 系统权限管理
          this.SectionHeader('系统权限管理')

          Column() {
            this.NavigationItemWithDescription(
              '系统权限管理',
              '为了提供更好的服务，大众点评在某些特定场景下需要向你申请使用系统数据的权限',
              () => {
                router.pushUrl({ url: 'pages/PermissionManagementPage' });
              }
            )
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 12, right: 12 })

          // Section: 个人主页设置
          this.SectionHeader('个人主页设置')

          Column() {
            this.ToggleItem(
              '允许他人查看我关注的人',
              '',
              this.allowViewFollowing,
              (value: boolean) => {
                this.allowViewFollowing = value;
              }
            )

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.ToggleItem(
              '允许他人查看我的粉丝',
              '',
              this.allowViewFollowers,
              (value: boolean) => {
                this.allowViewFollowers = value;
              }
            )

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.ToggleItemWithDescription(
              '分享给微信好友展示昵称头像',
              '微信好友查看你分享的商户和评价时，将看到你的大众点评昵称和头像，并可以关注你；关闭后则不显示。',
              this.shareNicknameAvatar,
              (value: boolean) => {
                this.shareNicknameAvatar = value;
              }
            )
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 12, right: 12 })

          // Section: 关系及互动设置
          this.SectionHeader('关系及互动设置')

          Column() {
            this.NavigationItem('推荐可能认识的人', () => {
              // Navigate to recommend settings
            })

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.NavigationItemWithDescription(
              '解除第三方好友关系',
              '解除后通过微信、QQ和通讯录关注的人和粉丝都会被删除',
              () => {
                // Navigate to unbind third-party friends
              }
            )
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 12, right: 12 })
        }
        .width('100%')
        .padding({ top: 10, bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor('#999999')
      .padding({ left: 28, top: 16, bottom: 8 })
      .width('100%')
  }

  @Builder
  NavigationItem(label: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)

      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      onClick();
    })
  }

  @Builder
  NavigationItemWithDescription(label: string, description: string, onClick: () => void) {
    Row() {
      Column() {
        Text(label)
          .fontSize(15)
          .fontColor('#333333')
        Text(description)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      onClick();
    })
  }

  @Builder
  ToggleItem(label: string, description: string, isOn: boolean, onChange: (value: boolean) => void) {
    Row() {
      Column() {
        Text(label)
          .fontSize(15)
          .fontColor('#333333')
        if (description !== '') {
          Text(description)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor('#FF6600')
        .onChange((value: boolean) => {
          onChange(value);
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  @Builder
  ToggleItemWithDescription(label: string, description: string, isOn: boolean, onChange: (value: boolean) => void) {
    Column() {
      Row() {
        Text(label)
          .fontSize(15)
          .fontColor('#333333')
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: isOn })
          .selectedColor('#FF6600')
          .onChange((value: boolean) => {
            onChange(value);
          })
      }
      .width('100%')

      Text(description)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 6, right: 56 })
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text('示例')
        .fontSize(12)
        .fontColor('#FF6600')
        .margin({ top: 6 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }
}
