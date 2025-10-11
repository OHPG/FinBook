import fs from '@ohos.file.fs';

export class XUtil {

  private static readonly FONTS = [".ttf", ".woff2", ".otf"]

  public static isFont(path: string): boolean {
    let pathLc = path.toLowerCase();
    let find = XUtil.FONTS.find((value) => pathLc.endsWith(value))
    return find ? true : false;
  }

  public static loadFileFromAssets(context: Context, path: string): ArrayBuffer | undefined {
    try {
      let value: Uint8Array = context.resourceManager.getRawFileContentSync(path);
      return value.buffer as ArrayBuffer;
    } catch (error) {
      // ignore
    }
    return undefined
  }

  public static loadFileFromPath(filePath: string): ArrayBuffer {
    try {
      let stats = fs.statSync(filePath);
      let file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      let buffer = new ArrayBuffer(stats.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);
      return buffer;
    } catch (err) {
      return new ArrayBuffer(0);
    }
  }

}