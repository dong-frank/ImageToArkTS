import { FullScreenState } from './FullScreen';
export interface ITitleNView {
    titleText?: string;
    backgroundColor?: string;
    titleColor?: string;
    autoBackButton?: boolean;
    loading?: boolean;
}
@Component
export declare struct NavBar {
    onBackClick?: () => void;
    @State
    fullScreenState: FullScreenState;
    @Prop
    titleNView: ITitleNView;
    @Consume
    isMain: boolean;
    titleMargin: number;
    aboutToAppear(): void;
    build(): void;
}
