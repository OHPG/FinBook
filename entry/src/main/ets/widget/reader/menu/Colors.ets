export class Colors {
  static themeList: string[] = [
    'white',
    'yellow',
    'pink',
    'green',
    'dark',
    'whiteSky',
    'darkSky'
  ];
  static THEME_BUTTON_BACKGROUND: Record<string, Resource> = {
    'white': $r('app.color.ic_white_theme_button_background'),
    'yellow': $r('app.color.ic_yellow_theme_button_background'),
    'pink': $r('app.color.ic_pink_theme_button_background'),
    'green': $r('app.color.ic_green_theme_button_background'),
    'dark': $r('app.color.ic_dark_theme_button_background'),
    'whiteSky': $r('app.color.ic_white_theme_button_background'),
    'darkSky': $r('app.color.ic_dark_theme_button_background')
  }
  static THEME_PAGE_COLOR: Record<string, string> = {
    'white': '#FFFFFF',
    'yellow': '#BD9063',
    'pink': '#FFE4E5',
    'green': '#C5E7CE',
    'dark': '#202224',
    'whiteSky': '#FFFFFF',
    'darkSky': '#202224'
  }
  static themeBorderColor: Record<number, Resource> = {
    0: $r('app.color.ic_border_select_white'),
    1: $r('app.color.ic_border_select_yellow'),
    2: $r('app.color.ic_border_select_pink'),
    3: $r('app.color.ic_border_select_green'),
    4: $r('app.color.ic_border_select_white'),
    5: $r('app.color.ic_border_select_white'),
    6: $r('app.color.ic_border_select_white')
  }

}