import router from '@ohos.router';
import { BottomNavBar } from '../components/BottomNavBar';
import { MenuItemData } from '../models/DataTypes';

@Entry
@Component
struct ProfilePage {
  @State currentTab: number = 3;

  build() {
    Column() {
      // Header area with user info
      this.UserHeader()

      // Stats row
      this.StatsRow()

      // Action cards grid
      this.ActionCards()

      // Menu list
      this.MenuList()

      // Bottom navigation
      BottomNavBar({ currentTab: $currentTab })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  UserHeader() {
    Row() {
      // Avatar
      Circle()
        .width(60)
        .height(60)
        .fill('#FF6600')

      Column() {
        Text('Hi, 美食爱好者')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Text('查看个人主页 >')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)

      // Settings icon
      Text('⚙️')
        .fontSize(22)
        .onClick(() => {
          router.pushUrl({ url: 'pages/SettingsPage' });
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 48, bottom: 16 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  StatsRow() {
    Row() {
      this.StatItem('12', '关注')
      this.StatItem('36', '粉丝')
      this.StatItem('128', '贡献')
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 1 })
  }

  @Builder
  StatItem(count: string, label: string) {
    Column() {
      Text(count)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      Text(label)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
  }

  @Builder
  ActionCards() {
    Column() {
      // First row: 4 action items
      Row() {
        this.ActionItem('📋', '我的订单')
        this.ActionItem('🎫', '优惠券')
        this.ActionItem('❤️', '我的收藏')
        this.ActionItem('📝', '我的评价')
      }
      .width('100%')
      .padding({ top: 16, bottom: 8 })

      // Second row: 4 action items
      Row() {
        this.ActionItem('📍', '打卡记录')
        this.ActionItem('📒', '我的笔记')
        this.ActionItem('🏪', '商户管理')
        this.ActionItem('👥', '邀请好友')
      }
      .width('100%')
      .padding({ top: 8, bottom: 16 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .margin({ top: 10 })
    .borderRadius(8)
  }

  @Builder
  ActionItem(icon: string, label: string) {
    Column() {
      Text(icon)
        .fontSize(28)
      Text(label)
        .fontSize(12)
        .fontColor('#333333')
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .onClick(() => {
      if (label === '我的订单') {
        router.pushUrl({ url: 'pages/OrderListPage' });
      }
    })
  }

  @Builder
  MenuList() {
    Column() {
      // Group 1: Account & Services
      this.MenuGroup([
        new MenuItemData('👤', '个人资料', 'pages/PersonalInfoPage'),
        new MenuItemData('🔒', '账号与安全', 'pages/AccountSecurityPage'),
        new MenuItemData('🔔', '消息通知设置', 'pages/NotificationSettingsPage'),
        new MenuItemData('🛡️', '隐私管理', 'pages/PrivacyManagementPage'),
        new MenuItemData('⚡', '通用', 'pages/GeneralSettingsPage'),
      ])

      // Group 2: Other
      this.MenuGroup([
        new MenuItemData('📱', '设备信息', 'pages/DeviceInfoPage'),
        new MenuItemData('💾', '存储空间', 'pages/StoragePage'),
        new MenuItemData('📄', '隐私政策', 'pages/PrivacyPolicyPage'),
        new MenuItemData('ℹ️', '关于', 'pages/AboutPage'),
        new MenuItemData('💬', '意见反馈', 'pages/FeedbackPage'),
      ])
    }
    .width('100%')
    .margin({ top: 10, bottom: 70 })
  }

  @Builder
  MenuGroup(items: MenuItemData[]) {
    Column() {
      ForEach(items, (item: MenuItemData, index: number) => {
        this.MenuItem(item.icon, item.label, item.route)
        if (index < items.length - 1) {
          Divider()
            .strokeWidth(0.5)
            .color('#F0F0F0')
            .margin({ left: 48 })
        }
      })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ top: 10 })
  }

  @Builder
  MenuItem(icon: string, label: string, route: string) {
    Row() {
      Text(icon)
        .fontSize(20)
      Text(label)
        .fontSize(15)
        .fontColor('#333333')
        .margin({ left: 12 })
        .layoutWeight(1)
      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      router.pushUrl({ url: route });
    })
  }
}
