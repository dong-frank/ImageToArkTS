import font from '@ohos.font';
import { UniSystemIcons } from '../utils/index'
import { SafeAreaOffset } from './SafeAreaOffset'
import { FullScreenState, fullScreenState } from './FullScreen'

export interface ITitleNView {
  titleText?: string;
  backgroundColor?: string;
  titleColor?: string;
  autoBackButton?: boolean;
  loading?: boolean
}

const FlexRowCenter = (): FlexOptions => {
  return { direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }
}

@Component
export struct NavBar {
  onBackClick?: () => void;
  @State fullScreenState: FullScreenState = fullScreenState;
  @Prop titleNView: ITitleNView;
  @Consume  isMain: boolean;
  titleMargin = this.isMain ? 50 : 100

  aboutToAppear() {
    font.registerFont({
      familyName: UniSystemIcons,
      familySrc: $rawfile('uni-app/iconfont.ttf')
    })
  }

  build() {
    if (!this.fullScreenState.isFullScreen) {
      Column() {
        SafeAreaOffset({ type: 'top' })
        Flex(FlexRowCenter()) {
          Stack({ alignContent: Alignment.Start }) {
            Flex(FlexRowCenter()) {
              // 使用 Row 在 titleText 过长时 LoadingProgress 会静止
              Flex(FlexRowCenter()) {
                if (this.titleNView.loading) {
                  LoadingProgress()
                    .width(32)
                    .margin(4)
                    .color(this.titleNView.titleColor)
                }
                if (this.titleNView.titleText) {
                  Text(this.titleNView.titleText)
                    .fontSize(20)
                    .fontColor(this.titleNView.titleColor)
                    .maxLines(1)
                    .textOverflow({
                      overflow: TextOverflow.Ellipsis
                    })
                    .textAlign(TextAlign.Center)
                }
              }.margin({ left: this.titleMargin, right: this.titleMargin })
            }.width('100%')

            // 按钮在栈顶不影响点击
            if (this.titleNView.autoBackButton) {
              Stack() {
                Text('\uE601')
                  .fontSize(27)
                  .fontColor(this.titleNView.titleColor ?? Color.Black)
                  .halfLeading(true)
                  .fontFamily(UniSystemIcons)
              }
              .width(30)
              .height(30)
              .margin({ left: 5 })
              .onClick(() => {
                this.onBackClick?.();
              });
            }
          }.height(44)
        }
      }
      .backgroundColor(this.titleNView.backgroundColor || '#F8F8F8')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    }
  }
}
