import router from '@ohos.router';

@Entry
@Component
struct PrivacyPage {
  @State showMyCollections: boolean = true;
  @State showMyLikes: boolean = true;
  @State allowRecommend: boolean = true;
  @State allowSearch: boolean = true;

  build() {
    Column() {
      // Top bar
      Row() {
        Text('\u{2190}')
          .fontSize(20)
          .fontColor('#333333')
          .padding(12)
          .onClick(() => {
            router.back();
          })
        Text('隐私设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Row()
          .width(44)
          .height(44)
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })

      Scroll() {
        Column() {
          // Visibility settings
          this.SectionHeader('公开信息')
          this.SettingItem('个人主页', '公开', () => {
            // Profile visibility
          })
          this.SettingItem('个人资料', '公开', () => {
            // Personal info visibility
          })

          // Content visibility
          this.SectionHeader('内容可见性')
          this.ToggleItem('公开我的收藏', this.showMyCollections, (isOn: boolean) => {
            this.showMyCollections = isOn;
          })
          this.ToggleItem('公开我的赞同', this.showMyLikes, (isOn: boolean) => {
            this.showMyLikes = isOn;
          })
          this.SettingItem('动态可见范围', '所有人', () => {
            // Feed visibility: Everyone / Followers / Only Me
          })
          this.SettingItem('回答可见范围', '所有人', () => {
            // Answer visibility
          })

          // Interaction privacy
          this.SectionHeader('互动隐私')
          this.SettingItem('谁可以评论我', '所有人', () => {
            // Comment permission
          })
          this.SettingItem('谁可以私信我', '所有人', () => {
            // Message permission
          })
          this.SettingItem('谁可以邀请我回答', '所有人关注的人', () => {
            // Invite permission
          })
          this.ToggleItem('隐藏访问记录', true, () => {})

          // Recommendation privacy
          this.SectionHeader('推荐与搜索')
          this.ToggleItem('允许个性化推荐', this.allowRecommend, (isOn: boolean) => {
            this.allowRecommend = isOn;
          })
          if (this.allowRecommend) {
            Row() {
              Text('根据你的浏览和互动记录推荐相关内容')
                .fontSize(12)
                .fontColor('#999999')
                .lineHeight(18)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor('#FFFFFF')
            .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
          }
          this.ToggleItem('允许搜索引擎收录', this.allowSearch, (isOn: boolean) => {
            this.allowSearch = isOn;
          })

          // Data privacy
          this.SectionHeader('数据与权限')
          this.SettingItem('个人信息浏览与导出', '', () => {})
          this.SettingItem('个性化广告管理', '', () => {})
          this.SettingItem('授权管理', '', () => {})
          this.SettingItem('信任设备管理', '', () => {
            router.pushUrl({ url: 'pages/TrustDevicePage' });
          })

          // Account
          this.SectionHeader('账号管理')
          this.SettingItem('注销账号', '', () => {})

          // Bottom spacing
          Column()
            .width('100%')
            .height(24)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(12)
      .fontColor('#999999')
      .padding({ left: 16, top: 20, bottom: 8 })
      .width('100%')
  }

  @Builder
  SettingItem(title: string, value: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
      if (value !== '') {
        Text(value)
          .fontSize(13)
          .fontColor('#999999')
      }
      Text('>')
        .fontSize(14)
        .fontColor('#CCCCCC')
        .margin({ left: 6 })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 12 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
    .onClick(onClick)
  }

  @Builder
  ToggleItem(title: string, isOn: boolean, onChange: (isOn: boolean) => void) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .onChange(onChange)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
  }
}