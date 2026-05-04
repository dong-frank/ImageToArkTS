export class NavigationService {
  static primaryPageNames(): string[] {
    return [
      '首页信息流',
      '直答/提问首页',
      '消息列表',
      '个人中心',
      '内容编辑器',
      '故事频道',
      '知识频道',
      '回答详情页',
      '我的-功能列表',
      '设置',
      '通用设置',
      '消息设置',
      '隐私设置',
      '视频播放设置',
      '内容兴趣偏好',
      '关于知乎',
      '我的书架',
      '我的课程',
      '付费咨询',
      '知乎商城',
      '帮助与客服',
      '组织机构号注册',
      '个人信息保护指引',
      '知乎协议',
      '未成年人模式',
      '信任设备',
      'APP备案编号',
      '自动播放设置详情',
      '推送消息设置',
      '与第三方共享个人信息清单'
    ];
  }

  static routeFor(pageName: string): string {
    switch (pageName) {
      case '首页信息流':
        return 'pages/HomeFeedPage';
      case '直答/提问首页':
        return 'pages/QaLandingPage';
      case '消息列表':
        return 'pages/MessageListPage';
      case '个人中心':
        return 'pages/ProfileHomePage';
      case '内容编辑器':
        return 'pages/ContentEditorPage';
      case '故事频道':
        return 'pages/StoryHomePage';
      case '知识频道':
        return 'pages/KnowledgeHomePage';
      case '回答详情页':
        return 'pages/AnswerDetailPage';
      case '我的-功能列表':
        return 'pages/MyFeaturesPage';
      case '设置':
        return 'pages/SettingsRootPage';
      case '通用设置':
        return 'pages/SettingsGeneralPage';
      case '消息设置':
        return 'pages/MessageSettingsPage';
      case '隐私设置':
        return 'pages/PrivacySettingsPage';
      case '视频播放设置':
        return 'pages/VideoPlaybackSettingsPage';
      case '内容兴趣偏好':
        return 'pages/InterestPreferencePage';
      case '关于知乎':
        return 'pages/AboutZhihuPage';
      case '我的书架':
        return 'pages/MyBookshelfPage';
      case '我的课程':
        return 'pages/MyCoursesPage';
      case '付费咨询':
        return 'pages/PaidConsultationPage';
      case '知乎商城':
        return 'pages/MallHomePage';
      case '帮助与客服':
        return 'pages/HelpCenterPage';
      case '组织机构号注册':
        return 'pages/OrgRegisterPage';
      case '个人信息保护指引':
        return 'pages/PrivacyGuidePage';
      case '知乎协议':
        return 'pages/ZhihuAgreementPage';
      case '未成年人模式':
        return 'pages/MinorModeOnboardingPage';
      case '信任设备':
        return 'pages/TrustDevicePage';
      case 'APP备案编号':
        return 'pages/AppFilingDetailPage';
      case '自动播放设置详情':
        return 'pages/AutoPlayDetailPage';
      case '推送消息设置':
        return 'pages/PushNotificationSettingsPage';
      case '与第三方共享个人信息清单':
        return 'pages/ThirdPartyDataSharingPage';
      default:
        return 'pages/Index';
    }
  }
}
