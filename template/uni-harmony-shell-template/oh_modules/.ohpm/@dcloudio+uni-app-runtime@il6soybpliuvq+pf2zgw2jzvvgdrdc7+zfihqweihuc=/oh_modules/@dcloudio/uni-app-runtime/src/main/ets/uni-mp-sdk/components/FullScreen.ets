@Observed
export class FullScreenState {
  isFullScreen: boolean;

  constructor() {
    this.isFullScreen = false
  }
}

export const fullScreenState = new FullScreenState();
