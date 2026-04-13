@Observed
export declare class ThemeState {
    tabBarBackground?: string;
    isDark?: boolean;
    constructor();
}
export declare const themeState: ThemeState;
export declare function setThemeState(state: ThemeState): void;
