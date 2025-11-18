export class Fonts {

  static FONTS: string[] = [
    'system',
    'serif'
  ]

  static FONT_NAME: Record<string, ResourceStr> = {
    'system': $r('app.string.system_font'),
    'serif': $r('app.string.source_han_serif_font')
  }

  static FONT_PATH: Record<string, string> = {
    'system': '',
    'serif': 'fonts/SourceHanSerifCN-VF.ttf'
  }

}