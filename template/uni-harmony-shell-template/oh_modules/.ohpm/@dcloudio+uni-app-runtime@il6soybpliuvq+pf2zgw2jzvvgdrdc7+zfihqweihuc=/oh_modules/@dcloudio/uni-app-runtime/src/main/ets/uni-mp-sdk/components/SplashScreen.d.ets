@Component
export declare struct SplashScreen {
    private controller;
    private canvasWidth;
    private canvasHeight;
    private centerX;
    private centerY;
    private radius;
    private progress;
    private timerId;
    private imageSize;
    private currentMP;
    private miniAppName?;
    @State
    logoSrc?: PixelMap | DrawableDescriptor | null;
    aboutToAppear(): void;
    aboutToDisappear(): void;
    startAnimation(): void;
    draw(): void;
    build(): void;
}
