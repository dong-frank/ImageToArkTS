import { bundleManager } from '@kit.AbilityKit';
import { getAbilityContext, getCurrentMP, getRealPath } from '../sdk';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';

function getFileContentSync(url: string) {
  const fd = fileIo.openSync(url, fileIo.OpenMode.READ_ONLY).fd
  const data = new ArrayBuffer(fileIo.statSync(fd).size)
  fileIo.readSync(fd, data)
  return data
}

@Component
export struct SplashScreen {
  private controller: CanvasRenderingContext2D = new CanvasRenderingContext2D();
  private canvasWidth: number = 150 * 0.75;
  private canvasHeight: number = 150 * 0.75;
  private centerX: number = 75 * 0.75;
  private centerY: number = 75 * 0.75;
  private radius: number = 50 * 0.75;
  private progress: number = 0;
  private timerId: number = 0;
  private imageSize: number = 70
  private currentMP = getCurrentMP()
  private miniAppName?: string
  @State logoSrc?: PixelMap | DrawableDescriptor | null = null

  aboutToAppear() {
    const resourceMgr = getAbilityContext()!.resourceManager;
    const mpStartWindowIcon = this.currentMP?.startWindowIcon
    this.miniAppName = this.currentMP?.appName
    const startWindowIcon =
      mpStartWindowIcon ? getRealPath(`${mpStartWindowIcon.startsWith('/') ? '' : '/'}${mpStartWindowIcon}`) : undefined
    this.startAnimation();
    if (startWindowIcon == null) {
      let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_METADATA;
      bundleManager.getBundleInfoForSelf(bundleFlags).then(async (data) => {
        this.logoSrc = resourceMgr.getDrawableDescriptor(data.appInfo.iconId).getPixelMap()
      })
    } else {
      let imageResource = image.createImageSource(getFileContentSync(startWindowIcon));
      let opts: image.DecodingOptions = { editable: true }
      this.logoSrc = imageResource.createPixelMapSync(opts)
    }
  }

  aboutToDisappear() {
    if (this.timerId) {
      clearInterval(this.timerId);
    }
  }

  startAnimation() {
    this.timerId = setInterval(() => {
      this.progress += 0.01;
      if (this.progress >= 1) {
        this.progress = 0;
        this.controller.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
      } else {
        this.draw();
      }
    }, 16);
  }

  draw() {
    const ctx = this.controller;
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 计算当前阶段要绘制的角度
    const totalAngle = 2 * Math.PI;
    const currentAngle = totalAngle * this.progress;

    // 绘制圆形路径
    ctx.beginPath();
    ctx.moveTo(this.centerX, this.centerY - this.radius); // 从顶部开始

    if (currentAngle > 0) {
      ctx.arc(
        this.centerX,
        this.centerY,
        this.radius,
        -Math.PI / 2,
        -Math.PI / 2 + currentAngle,
        false
      );
    }

    ctx.strokeStyle = '#AAA';
    ctx.lineWidth = 1;
    ctx.stroke();
  }

  build() {
    Column() {
      Stack() {
        // 画布绘制动画
        Canvas(this.controller)
          .width(this.canvasWidth)
          .height(this.canvasHeight)

        // 图片定位到圆中心
        Image(this.logoSrc)
          .width(this.imageSize)
          .height(this.imageSize)
          .borderRadius('50%')
          .clip(true)
      }
      .width(this.canvasWidth)
      .height(this.canvasHeight)

      Text(this.miniAppName)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMP?.startWindowBackground ?? '#FFFFFF')
    .padding({ top: 200 })
  }
}