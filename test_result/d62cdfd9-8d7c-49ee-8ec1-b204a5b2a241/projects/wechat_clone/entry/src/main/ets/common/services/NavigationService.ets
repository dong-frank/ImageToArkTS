export class NavigationService {
  static primaryPageNames(): string[] {
    return [
      '聊天列表',
      '通讯录',
      '发现',
      '我',
      '服务（金融版）',
      '服务（消费版）',
      '钱包',
      '手机充值',
      '生活缴费',
      '设置',
      '账号安全',
      '微信安全中心',
      '界面与显示',
      '深色模式',
      '朋友权限',
      '更多设置',
      '系统权限管理',
      '其他功能',
      '辅助功能',
      '帮助与反馈',
      '关于微信',
      '功能介绍'
    ];
  }

  static routeFor(pageName: string): string {
    switch (pageName) {
      case '聊天列表':
        return 'pages/ChatListPage';
      case '通讯录':
        return 'pages/ContactsPage';
      case '发现':
        return 'pages/DiscoverPage';
      case '我':
        return 'pages/MeProfilePage';
      case '服务（金融版）':
        return 'pages/ServicesHomeAPage';
      case '服务（消费版）':
        return 'pages/ServicesHomeBPage';
      case '钱包':
        return 'pages/WalletPage';
      case '手机充值':
        return 'pages/PhoneRechargePage';
      case '生活缴费':
        return 'pages/LifePaymentPage';
      case '设置':
        return 'pages/SettingsPage';
      case '账号安全':
        return 'pages/AccountSecurityPage';
      case '微信安全中心':
        return 'pages/SecurityCenterPage';
      case '界面与显示':
        return 'pages/DisplaySettingsPage';
      case '深色模式':
        return 'pages/DarkModePage';
      case '朋友权限':
        return 'pages/FriendPermissionPage';
      case '更多设置':
        return 'pages/MoreSettingsPage';
      case '系统权限管理':
        return 'pages/SystemPermissionsPage';
      case '其他功能':
        return 'pages/OtherFunctionsPage';
      case '辅助功能':
        return 'pages/AuxiliaryFeaturesPage';
      case '帮助与反馈':
        return 'pages/HelpCenterPage';
      case '关于微信':
        return 'pages/AboutWechatPage';
      case '功能介绍':
        return 'pages/FeatureIntroPage';
      default:
        return 'pages/Index';
    }
  }
}
