import { WebNodeController, callPageLifeCycle, getCurrentMP, appAbilityEmitter } from './sdk';
import {
  TabBar,
  TabBarState,
  OnTabItemClickOptions,
  createTabBarState,
  createTabBarItem
} from './components/TabBar';
import { NavBar, ITitleNView } from './components/NavBar';
import { FullScreenState, fullScreenState } from './components/FullScreen'
import { NodeController, FrameCallback } from '@kit.ArkUI';
import { SafeAreaOffset } from './components/SafeAreaOffset';
import { Capsule } from './components/Capsule'
import { SplashScreen } from './components/SplashScreen'
import { UniMP, IWebNodeController, PageComponent } from './types/index'
import { WEB_PAGE_END } from './WebBuilder';
import { ThemeState, themeState } from './theme';

@Observed
class PullToRefresh {
  support?: boolean

  constructor(pullToRefresh?: PullToRefresh) {
    this.support = pullToRefresh?.support
  }
}

@Observed
class ObservedPageStyle {
  titleNView?: ITitleNView
  pullToRefresh?: PullToRefresh
  background?: string
  backgroundTextStyle?: 'light' | 'dark'
  bounce: string
  scrollIndicator: string
  marginTop?: number
  paddingBottom?: number

  constructor(style: ObservedPageStyle) {
    this.titleNView = style.titleNView
    this.pullToRefresh = new PullToRefresh(style.pullToRefresh)
    this.background = style.background
    this.backgroundTextStyle = style.backgroundTextStyle
    this.marginTop = style.marginTop
    this.paddingBottom = style.paddingBottom
    this.bounce = style.bounce
    this.scrollIndicator = style.scrollIndicator
  }
}

@Observed
class ObservedChildren extends Array<NodeController> {
}

@Observed
class RefreshState {
  refreshing?: boolean
  onRefreshing?: () => void
  onRefreshStateChange?: (state?: RefreshStatus) => void

  constructor(state?: RefreshState) {
    this.refreshing = state?.refreshing
    this.onRefreshing = state?.onRefreshing
    this.onRefreshStateChange = state?.onRefreshStateChange
  }
}

@Observed
class SubPageState {
  id: string
  style: ObservedPageStyle
  embedChildren: ObservedChildren
  stackChildren: ObservedChildren
  refreshState: RefreshState

  constructor(id: string, style: ObservedPageStyle, embedChildren: NodeController[], stackChildren: NodeController[],
    refreshState?: RefreshState) {
    this.id = id
    this.style = new ObservedPageStyle(style)
    this.embedChildren = new ObservedChildren(...embedChildren)
    this.stackChildren = new ObservedChildren(...stackChildren)
    this.refreshState = new RefreshState(refreshState)
  }
}

export function createSubPageState(options: SubPageState) {
  return new SubPageState(options.id, options.style, options.embedChildren, options.stackChildren, options.refreshState)
}

export {
  createTabBarState, createTabBarItem
}

interface NavBarState extends ITitleNView {
  onBackClick?: (options: OnTabItemClickOptions) => void
}

@Component
struct PageChildren {
  @ObjectLink children: ObservedChildren

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.children, (child: NodeController) => {
        NodeContainer(child)
      }, (_: object, index: number) => {
        return '' + index
      })
    }
  }
}

interface IWebNodeStyle {
  backgroundColor: string
}

@Component
struct PageContainer {
  @ObjectLink subPage: SubPageState
  @Require @Prop @Watch('pageStyleChange') style: ObservedPageStyle
  webNode: IWebNodeController | null = null

  pageStyleChange(propName: string) {
    this.updatePageStyle()
  }

  updatePageStyle() {
    if (this.webNode) {
      this.webNode.update({
        backgroundColor: this.style.background,
        bounce: this.style.bounce,
        scrollIndicator: this.style.scrollIndicator
      })
    }
  }

  updateWebNodeBackground(style: IWebNodeStyle) {
    if (this.webNode) {
      this.webNode.update({
        backgroundColor: style.backgroundColor || (Color.Transparent as Object as string)
      })
    }
  }

  aboutToAppear(): void {
    this.webNode = new WebNodeController(this.subPage.id) as IWebNodeController
    this.updateWebNodeBackground({
      backgroundColor: this.style.background
    } as IWebNodeStyle)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.TopStart }) {
        PageChildren({ children: this.subPage.embedChildren })
        NodeContainer(this.webNode)
          .width('100%')
          .height('100%')
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        PageChildren({ children: this.subPage.stackChildren }).width(0).height(0).clip(false)
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .margin({
        top: this.style.marginTop
      })
    }
    .clip(true)
    .width('100%')
    .height('100%')
    .padding({
      bottom: this.style.paddingBottom
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}

@Component
struct SubPage {
  @ObjectLink subPage: SubPageState
  @Require @Prop style: ObservedPageStyle
  @ObjectLink refreshState: RefreshState
  @Prop safeArea: SafeArea | undefined

  @Builder
  customRefreshComponent() {
    Stack() {
      Row() {
        LoadingProgress().height(32)
          .color(this.style.backgroundTextStyle === 'light' ? Color.White : '#5f5f5f')
      }
      .alignItems(VerticalAlign.Center)
    }.width("100%").align(Alignment.Center)
  }

  build() {
    Flex({
      direction: FlexDirection.Column,
    }) {
      if (this.style.titleNView) {
        NavBar({
          titleNView: this.style.titleNView,
          onBackClick: () => {
            callPageLifeCycle('onBackPress', this as Object as PageComponent)
          }
        })
      }

      Stack() {
        if (this.style.pullToRefresh?.support) {
          Refresh({
            refreshing: $$this.refreshState.refreshing,
            builder: this.customRefreshComponent()
          }) {
            PageContainer({ subPage: this.subPage, style: this.style })
          }
          .backgroundColor(this.style.background)
          .onStateChange(status => {
            this.refreshState.onRefreshStateChange?.(status)
          })
          .onRefreshing(() => {
            this.refreshState.refreshing = true
            this.refreshState.onRefreshing?.()
          })
        } else {
          PageContainer({ subPage: this.subPage, style: this.style })
        }
      }
      .clip(true)
      .width('100%')
      .flexGrow(1)
      .flexBasis(1)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

    }.width('100%')
    .height('100%')
    .backgroundColor(this.style.background || '#FFFFFF')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}

@Observed
class ObservedPages extends Array<SubPageState> {
}

interface SafeAreaBottom {
  offset?: string
}

interface SafeArea {
  background?: string
  backgroundDark?: string
  bottom?: SafeAreaBottom
}

@Component
struct Page {
  @Prop name: string
  @State pages: SubPageState[] = new ObservedPages()
  @State safeArea: SafeArea | undefined = undefined
  @State tabBar: TabBarState | undefined = undefined
  @State navBar: NavBarState | undefined = undefined
  @State fullScreenState: FullScreenState = fullScreenState;
  @State themeState: ThemeState = themeState;

  build() {
    Flex({
      direction: FlexDirection.Column,
    }) {
      Stack() {
        ForEach(this.pages, (subPage: SubPageState, index: number) => {
          SubPage({
            subPage: subPage,
            style: subPage.style,
            refreshState: subPage.refreshState,
            safeArea: this.safeArea
          })
        }, (subPage: SubPageState, index: number) => {
          // NOTE: index is not used here, but it is required by the ForEach API return id (HarmonyOS Next Beta6)
          return subPage.id
        })
      }
      .width('100%')
      .flexGrow(1)
      .flexBasis(1)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      if (!this.fullScreenState.isFullScreen) {
        if (this.tabBar && this.tabBar.list && this.tabBar.list.length > 0) {
          TabBar({
            style: this.tabBar,
            selectedIndex: this.tabBar.selectedIndex,
            items: this.tabBar.list,
            midButton: this.tabBar.midButton,
            onTabItemClick: (options: OnTabItemClickOptions) => {
              this.tabBar?.onClick?.(options)
            },
            onMidButtonClick: () => {
              this.tabBar?.onMidButtonClick?.()
            }
          })
            .visibility(this.tabBar.visible === false ? Visibility.None : Visibility.Visible)
        } else if (this.safeArea && this.safeArea?.bottom?.offset === 'auto') {
          SafeAreaOffset({ type: 'bottom' })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.isDark ? this.safeArea?.backgroundDark ?? this.safeArea?.background :
      this.safeArea?.background)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  aboutToAppear() {
    callPageLifeCycle('aboutToAppear', this as PageComponent)
  }

  aboutToDisappear() {
    callPageLifeCycle('aboutToDisappear', this as PageComponent)
  }
}

@Entry({ routeName: 'UniPage' })
@Component
struct UniPage {
  currentMP = getCurrentMP() as UniMP
  router = this.currentMP.router
  showCapsuleButton = this.currentMP.showCapsuleButton
  capsuleButtonStyle = this.currentMP.capsuleButtonStyle
  animationType = this.currentMP.animationType
  animationDuration = this.currentMP.animationDuration
  @State showSplashScreen: boolean = this.currentMP.showSplashScreen
  @State x: number | string = 0
  @State y: number | string = 0
  @State opacityValue: number = 1
  @Provide("isMain") isMain: boolean = this.currentMP.isMain;

  build() {
    Stack({
      alignContent: Alignment.TopEnd
    }) {
      Navigation(this.router)
        .mode(NavigationMode.Stack)
        .titleMode(NavigationTitleMode.Mini)
        .navDestination(this.pageBuilder)
        .hideTitleBar(true)
      if (this.showSplashScreen) {
        SplashScreen()
      }
      if (this.showCapsuleButton) {
        Capsule({
          style: this.capsuleButtonStyle
        })
      }
    }
    .height('100%')
    .width('100%')
    .translate({
      x: this.x,
      y: this.y
    })
    .opacity(this.opacityValue)
    .animation({
      duration: this.animationDuration,
      curve: Curve.EaseOut,
      playMode: PlayMode.Normal
    })
  }

  @Builder
  pageBuilder(name: string) {
    NavDestination() {
      Page({ name: name })
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      return callPageLifeCycle('onBackPress', this as Object as PageComponent)
    })
  }

  onBackPress(): boolean {
    return callPageLifeCycle('onBackPress', this as Object as PageComponent)
  }

  setAnimationBeginState() {
    switch (this.animationType) {
      case 'slide-in-right':
        this.x = '100%'
        break
      case 'slide-in-left':
        this.x = '-100%'
        break
      case 'slide-in-top':
        this.y = '-100%'
        break
      case 'slide-in-bottom':
        this.y = '100%'
        break
      case 'fade-in':
        this.opacityValue = 0
        break
    }
  }

  setAnimationEndState() {
    switch (this.animationType) {
      case 'slide-in-right':
        this.x = 0
        break
      case 'slide-in-left':
        this.x = 0
        break
      case 'slide-in-top':
        this.y = 0
        break
      case 'slide-in-bottom':
        this.y = 0
        break
      case 'fade-in':
        this.opacityValue = 1
        break
    }
  }

  aboutToAppear(): void {
    this.setAnimationBeginState()
    appAbilityEmitter.once(WEB_PAGE_END, () => {
      this.showSplashScreen = false
    })
  }

  onDidBuild(): void {
    const self = this

    class CustomFrameCallback extends FrameCallback {
      onIdle() {
        self.setAnimationEndState()
      }
    }

    this.getUIContext()?.postFrameCallback(new CustomFrameCallback())
  }
}
