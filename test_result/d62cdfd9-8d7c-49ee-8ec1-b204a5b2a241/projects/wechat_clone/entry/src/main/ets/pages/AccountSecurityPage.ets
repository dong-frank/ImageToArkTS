import router from '@ohos.router';

@Entry
@Component
struct AccountSecurityPage {
  @Builder
  BackButton() {
    Row() {
      Text('<')
        .fontSize(22)
        .fontColor('#333333')
        .fontWeight(FontWeight.Normal)
    }
    .width(44)
    .height(44)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      router.back();
    })
  }

  @Builder
  NavBar() {
    Row() {
      this.BackButton()
      Text('账号安全')
        .fontSize(18)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Row()
        .width(44)
        .height(44)
    }
    .width('100%')
    .height(48)
    .padding({ left: 4, right: 4 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#E5E5E5' })
  }

  @Builder
  ListItemWithStatus(label: string, status: string, onTap: () => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#333333')
      Blank()
      Text(status)
        .fontSize(14)
        .fontColor('#999999')
        .margin({ right: 8 })
      Text('>')
        .fontSize(16)
        .fontColor('#C0C0C0')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      onTap();
    })
  }

  @Builder
  ListItem(label: string, onTap: () => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#333333')
      Blank()
      Text('>')
        .fontSize(16)
        .fontColor('#C0C0C0')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      onTap();
    })
  }

  @Builder
  SectionDivider() {
    Row()
      .width('100%')
      .height(8)
      .backgroundColor('#F5F5F5')
  }

  @Builder
  ItemDivider() {
    Row()
      .width('100%')
      .height(0.5)
      .backgroundColor('#E5E5E5')
      .margin({ left: 16 })
  }

  build() {
    Column() {
      this.NavBar()

      Scroll() {
        Column() {
          // Section 1: 微信密码 & 声音锁
          this.ListItemWithStatus('微信密码', '已设置', () => {
            console.info('navigate to password detail');
          })
          this.ItemDivider()
          this.ListItemWithStatus('声音锁', '暂未开启', () => {
            console.info('navigate to voice lock setting');
          })

          this.SectionDivider()

          // Section 2: 应急联系人, 登录设备管理, 更多安全设置
          this.ListItem('应急联系人', () => {
            console.info('navigate to emergency contacts');
          })
          this.ItemDivider()
          this.ListItem('登录设备管理', () => {
            console.info('navigate to device management');
          })
          this.ItemDivider()
          this.ListItem('更多安全设置', () => {
            console.info('navigate to more security settings');
          })

          this.SectionDivider()

          // Section 3: 帮朋友冻结账号, 微信安全中心
          this.ListItem('帮朋友冻结账号', () => {
            console.info('navigate to freeze for friend');
          })
          this.ItemDivider()
          this.ListItem('微信安全中心', () => {
            router.pushUrl({ url: 'pages/SecurityCenterPage' });
          })

          // Footer text block
          Text('如果遇到账号信息泄露、忘记密码、诈骗等账号安全问题，可前往微信安全中心。')
            .fontSize(13)
            .fontColor('#999999')
            .lineHeight(20)
            .padding({ left: 16, right: 16, top: 16, bottom: 32 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

export default AccountSecurityPage;
