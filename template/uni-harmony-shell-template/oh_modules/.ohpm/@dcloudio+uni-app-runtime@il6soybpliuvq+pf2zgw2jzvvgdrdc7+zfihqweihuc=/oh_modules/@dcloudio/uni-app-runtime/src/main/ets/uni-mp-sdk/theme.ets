@Observed
export class ThemeState {
  tabBarBackground?: string;
  isDark?: boolean

  constructor() {
  }
}

export const themeState = new ThemeState();

export function setThemeState(state: ThemeState) {
  if (typeof state.tabBarBackground === 'string') {
    themeState.tabBarBackground = state.tabBarBackground
  }
  if (typeof state.isDark === 'boolean') {
    themeState.isDark = state.isDark
  }
}