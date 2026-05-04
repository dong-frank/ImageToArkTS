export interface MainTabInfo {
  pageId: string;
  label: string;
  route: string;
  isOverlayTrigger: boolean;
}

export class NavigationService {
  static readonly MAIN_TABS: MainTabInfo[] = [
    { pageId: 'home_discovery', label: '首页', route: 'pages/HomeDiscovery', isOverlayTrigger: false },
    { pageId: 'map_poi', label: '地图', route: 'pages/MapPoi', isOverlayTrigger: false },
    { pageId: 'action_hub_overlay', label: '+', route: '', isOverlayTrigger: true },
    { pageId: 'messages', label: '消息', route: 'pages/Messages', isOverlayTrigger: false },
    { pageId: 'my_profile', label: '我的', route: 'pages/MyProfile', isOverlayTrigger: false }
  ];

  static getMainTabLabels(): string[] {
    return NavigationService.MAIN_TABS.map(t => t.label);
  }

  static getMainTabRoutes(): string[] {
    return NavigationService.MAIN_TABS.filter(t => !t.isOverlayTrigger).map(t => t.route);
  }

  static routeForPageId(pageId: string): string {
    const tab = NavigationService.MAIN_TABS.find(t => t.pageId === pageId);
    return tab ? tab.route : '';
  }

  static isMainTab(pageId: string): boolean {
    return NavigationService.MAIN_TABS.some(t => t.pageId === pageId);
  }

  static routeFor(pageName: string): string {
    switch (pageName) {
      case '首页':
        return 'pages/HomeDiscovery';
      case '美食列表':
        return 'pages/FoodList';
      case '内容详情':
        return 'pages/ContentDetail';
      case '地图':
        return 'pages/MapPoi';
      case '消息':
        return 'pages/Messages';
      case '我的':
        return 'pages/MyProfile';
      case '订单列表':
        return 'pages/OrderList';
      case '设置':
        return 'pages/SettingsRoot';
      case '账号与安全':
        return 'pages/AccountSecurity';
      case '消息通知设置':
        return 'pages/NotificationSettings';
      case '消息页设置':
        return 'pages/MessagePageSettings';
      case '隐私管理':
        return 'pages/PrivacyManagement';
      case '个人信息查看与管理':
        return 'pages/PersonalInfoManagement';
      case '当前设备信息':
        return 'pages/DeviceInfo';
      case '通用':
        return 'pages/GeneralSettings';
      case '多语言':
        return 'pages/LanguageSettings';
      case '隐私政策详情':
        return 'pages/PrivacyPolicyDetail';
      case '关于我们':
        return 'pages/AboutUs';
      case '应用相关信息':
        return 'pages/AppInfo';
      case '系统权限管理':
        return 'pages/SystemPermissionManagement';
      case '存储空间':
        return 'pages/StorageSpace';
      case '第三方SDK信息清单':
        return 'pages/ThirdPartySdkList';
      case '意见反馈':
        return 'pages/FeedbackForm';
      case '活动消息':
        return 'pages/ActivityMessages';
      case '我的打卡':
        return 'pages/MyCheckin';
      default:
        return 'pages/HomeDiscovery';
    }
  }
}
