import { ObservedArray } from '../utils/index';
import { uni, getResourceStr,getCurrentWindow } from '../sdk';
import { BusinessError } from '@kit.BasicServicesKit';
import { ComponentContent, promptAction, UIContext } from '@kit.ArkUI';

/**
 * customDialog参考文档，修改为promptAction.openCustomDialog
 * - [自定义弹窗](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-common-components-custom-dialog-0000001813575884)
 * - [promptAction.openCustomDialog](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-promptaction-0000001821000749#ZH-CN_TOPIC_0000001857916061__promptactionopencustomdialog11)
 * 手势相关文档
 * - [多层级手势事件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-gesture-events-multi-level-gesture-0000001839307337)
 *
 * 微信小程序previewImage效果如下
 * - 图片默认contain大小，这也是最小尺寸
 * - 图片放大时滑动到图片边界与屏幕边界重合时再触发切换图片
 *
 * TODO 待解决手势冲突后实现微信小程序的效果，目前禁用PanGesture
 */

interface Image {
  url: string
  translateX: number
  translateY: number
  scale: number
}

interface IOffset {
  offsetX: number
  offsetY: number
  reachTop: boolean
  reachBottom: boolean
  reachLeft: boolean
  reachRight: boolean
}

const TAG_IMAGE_PAN = 'IMAGE_PAN'

export class PromptAction {
  static ctx: UIContext;
  static contentNode: ComponentContent<Object>;
  static options: promptAction.BaseDialogOptions;

  static setContext(context: UIContext) {
    PromptAction.ctx = context;
  }


  static setContentNode(node: ComponentContent<Object>) {
    PromptAction.contentNode = node;
  }


  static setOptions(options: promptAction.BaseDialogOptions) {
    PromptAction.options = options;
  }


  static openDialog() {
    if (PromptAction.contentNode !== null) {
      PromptAction.ctx.getPromptAction()
        .openCustomDialog(PromptAction.contentNode, PromptAction.options)
        .then(() => {})
        .catch((error: BusinessError) => {
          let message = (error as BusinessError).message;
          let code = (error as BusinessError).code;
          console.error(`OpenCustomDialog args error code is ${code}, message is ${message}`);
        })
    }
  }


  static closeDialog() {
    if (PromptAction.contentNode !== null) {
      PromptAction.ctx.getPromptAction()
        .closeCustomDialog(PromptAction.contentNode)
        .then(() => {})
        .catch((error: BusinessError) => {
          let message = (error as BusinessError).message;
          let code = (error as BusinessError).code;
          console.error(`CloseCustomDialog args error code is ${code}, message is ${message}`);
        })
    }
  }


  static updateDialog(options: promptAction.BaseDialogOptions) {
    if (PromptAction.contentNode !== null) {
      PromptAction.ctx.getPromptAction()
        .updateCustomDialog(PromptAction.contentNode, options)
        .then(() => {})
        .catch((error: BusinessError) => {
          let message = (error as BusinessError).message;
          let code = (error as BusinessError).code;
          console.error(`UpdateCustomDialog args error code is ${code}, message is ${message}`);
        })
    }
  }
}

@Component
struct ImageView {
  @Prop @Watch('urlChange') url: string = ''
  @Prop showmenu: boolean
  @State offsetX: number = 0
  @State offsetY: number = 0
  @State scaleRatio: number = 1
  @State offsetXStart: number = 0
  @State offsetYStart: number = 0
  @State scaleRatioStart: number = 1
  @State scaleCenterX: number = 0
  @State scaleCenterY: number = 0
  @State loadComplete: boolean = false
  @State componentWidth: number = 0
  @State componentHeight: number = 0
  @State contentWidth: number = 0
  @State contentHeight: number = 0

  private urlChange() {
    this.loadComplete = false
    this.resetPosition()
  }

  private resetPosition() {
    this.offsetX = 0
    this.offsetY = 0
    this.scaleRatio = 1
  }

  private getLimitedOffset(offsetX: number, offsetY: number): IOffset {
    const oversizeX = Math.max(this.contentWidth * this.scaleRatio - this.componentWidth, 0)
    const oversizeY = Math.max(this.contentHeight * this.scaleRatio - this.componentHeight, 0)
    const minOffsetX = -oversizeX / 2
    const maxOffsetX = -minOffsetX
    const minOffsetY = -oversizeY / 2
    const maxOffsetY = -minOffsetY
    const limitedOffsetX = Math.min(Math.max(minOffsetX, offsetX), maxOffsetX)
    const limitedOffsetY = Math.min(Math.max(minOffsetY, offsetY), maxOffsetY)
    return {
      offsetX: limitedOffsetX,
      offsetY: limitedOffsetY,
      reachTop: limitedOffsetY === maxOffsetY,
      reachBottom: limitedOffsetY === minOffsetY,
      reachLeft: limitedOffsetX === maxOffsetX,
      reachRight: limitedOffsetX === minOffsetX,
    }
  }

  private resetScaleCenter(newCenterX: number, newCenterY: number) {
    const offsetX = this.offsetX + (newCenterX - this.scaleCenterX) * (this.scaleRatio - 1)
    const offsetY = this.offsetY + (newCenterY - this.scaleCenterY) * (this.scaleRatio - 1)
    const limitedOffset = this.getLimitedOffset(offsetX, offsetY)
    this.offsetX = limitedOffset.offsetX
    this.offsetY = limitedOffset.offsetY
    this.scaleCenterX = newCenterX
    this.scaleCenterY = newCenterY
  }

  build() {
    Stack() {
      Image(getResourceStr(this.url) as string | Resource)
        .objectFit(ImageFit.Contain)
        .width('100%')
        .height('100%')
        .draggable(false)
        .onComplete((e) => {
          if (!e) {
            return
          }
          this.loadComplete = !!(
            e.componentWidth &&
            e.componentHeight &&
            e.contentWidth &&
            e.contentHeight
          )
          if (this.loadComplete) {
            this.componentWidth = px2vp(e?.componentWidth!)
            this.componentHeight = px2vp(e?.componentHeight!)
            this.contentWidth = px2vp(e?.contentWidth!)
            this.contentHeight = px2vp(e?.contentHeight!)
            this.scaleCenterX = (this.componentWidth!) / 2
            this.scaleCenterY = (this.componentHeight!) / 2
          }
        })
        .translate({
          x: this.offsetX,
          y: this.offsetY,
        })
        .scale({
          x: this.scaleRatio,
          y: this.scaleRatio,
          centerX: this.scaleCenterX,
          centerY: this.scaleCenterY,
        })

    }
    .width('100%')
    .height('100%')
    .clip(true)
    .gesture(
      GestureGroup(
        GestureMode.Parallel,
        PanGesture({
          fingers: 1
        })
          .onActionStart(() => {
            this.offsetXStart = this.offsetX
            this.offsetYStart = this.offsetY
          })
          .onActionUpdate((e) => {
            /**
             * 图片scale后如果宽度小于component宽度则不可左右移动
             * 图片scale后如果高度小于component高度则不可上下移动
             * 图片scale后如果宽度大于component宽度则左右移动范围为图片宽度与component宽度差值的一半
             * 图片scale后如果高度大于component高度则上下移动范围为图片高度与component高度差值的一半
             */
            const limitedOffset = this.getLimitedOffset(this.offsetXStart + e.offsetX * this.scaleRatio,
              this.offsetYStart + e.offsetY * this.scaleRatio)

            this.offsetX = limitedOffset.offsetX
            this.offsetY = limitedOffset.offsetY
          })
          .tag(TAG_IMAGE_PAN),

        PinchGesture()
          .onActionStart((e) => {
            this.scaleRatioStart = this.scaleRatio
            const newCenterX = (-this.offsetX) / this.scaleRatio + e.pinchCenterX
            const newCenterY = (-this.offsetY) / this.scaleRatio + e.pinchCenterY
            this.resetScaleCenter(newCenterX, newCenterY)
          })
          .onActionUpdate((e) => {
            this.scaleRatio = Math.min(Math.max(1, this.scaleRatioStart * e.scale), 4)
          })
          .onActionEnd((e) => {
            // 重设放大中心点为图片中心
            const newCenterX = (this.componentWidth!) / 2
            const newCenterY = (this.componentHeight!) / 2
            this.resetScaleCenter(newCenterX, newCenterY)
          })
          .onActionCancel(() => {
            // 重设放大中心点为图片中心
            const newCenterX = (this.componentWidth!) / 2
            const newCenterY = (this.componentHeight!) / 2
            this.resetScaleCenter(newCenterX, newCenterY)
          })
      )
    )
    .hitTestBehavior(this.loadComplete ? HitTestMode.Default : HitTestMode.None)
    .onGestureJudgeBegin((gestureInfo: GestureInfo, event: BaseGestureEvent) => {
      const tag = gestureInfo.tag
      if (tag !== TAG_IMAGE_PAN) {
        return GestureJudgeResult.CONTINUE
      }
      const offsetX = (event as GestureEvent).offsetX
      const limit = this.getLimitedOffset(this.offsetX, this.offsetY)
      if (offsetX > 0 && limit.reachLeft || offsetX < 0 && limit.reachRight) {
        return GestureJudgeResult.REJECT;
      }
      return GestureJudgeResult.CONTINUE;
    })
  }
}

class ImagePreviewerParams {
  urls: string[] = [];
  state: PreviewImageState =  new Object({ currentIndex: 0, showmenu: true }) as PreviewImageState;

  constructor(urls: string[], state: PreviewImageState) {
    this.urls = urls
    this.state = state
  }
}

@Builder
function ImagePreviewer(params: ImagePreviewerParams) {
  Column() {
    Swiper() {
      ForEach(params.urls, (url: string) => {
        ImageView({
          url,
          showmenu: params.state.showmenu
        })
      })
    }
    .width('100%')
    .height('100%')
    .loop(false)
    .effectMode(EdgeEffect.None)
    .index($$params.state.currentIndex)
  }
  .width('100%')
  .height('100%')
  .align(Alignment.Center)
  .backgroundColor('#FF000000')
  .justifyContent(FlexAlign.Center)
  .onClick(() => {
    PromptAction.closeDialog()
  })
  .gesture(
    LongPressGesture()
      .onAction(() => {
        if (!params.state.showmenu) {
          return
        }
        promptAction.showActionMenu({
          title: '',
          buttons: [
            {
              text: '保存图片',
              color: '#000000'
            }
          ]
        }).then(async (data) =>{
          if (!data || data.index != 0) {
            return
          }
          let uri = params.urls[params.state.currentIndex]
          if (/^https?:\/\//.test(uri)) {
            uri = await new Promise<string>((resolve, reject) => {
              uni.downloadFile({
                url: uri,
                success(res: ESObject) {
                  resolve(res.tempFilePath)
                },
                fail(err: ESObject) {
                  reject()
                }
              })
            })
          }
          uni.saveImageToPhotosAlbum({
            filePath: uri
          })
        })
      })
  )
}

interface IPreviewImageState {
  currentIndex: number
  showmenu: boolean
}

@Observed
class PreviewImageState {
  currentIndex: number = 0
  showmenu: boolean = true

  constructor(options: IPreviewImageState) {
    this.currentIndex = options.currentIndex
    this.showmenu = options.showmenu
  }
}

const previewImageUrls: string[] = new ObservedArray()
const previewImageState = new PreviewImageState({
  currentIndex: 0,
  showmenu: true
})

interface IPreviewImageOptions {
  urls: string[],
  current?: string
  showmenu?: boolean
}

export function previewImage(options: IPreviewImageOptions, page: Object) {
  // // 切页面relaunch到其他页面不影响预览界面显示
  let ctx:UIContext
  let currentWindow = getCurrentWindow()
  if(currentWindow) {
    ctx = currentWindow.getUIContext() as UIContext
  }else{
    ctx = new UIContext()
  }
  previewImageUrls.splice(0, previewImageUrls.length)
  const urls = options.urls
  const currentUrl = options.current || urls[0] || ''
  previewImageState.currentIndex = Math.max(0, urls.indexOf(currentUrl))
  previewImageState.showmenu = options.showmenu === false ? false : true
  urls.forEach(url => {
    previewImageUrls.push(url)
  })
  let contentNode: ComponentContent<ImagePreviewerParams> = new ComponentContent(ctx, wrapBuilder(ImagePreviewer),
    new ImagePreviewerParams(previewImageUrls, previewImageState));
  PromptAction.setContext(ctx);
  PromptAction.setContentNode(contentNode);
  PromptAction.openDialog();
}

export function closePreviewImage() {
  PromptAction.closeDialog()
}