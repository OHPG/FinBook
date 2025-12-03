import { fileUri, picker } from "@kit.CoreFileKit";
import fs from '@ohos.file.fs';

export class AppDir {

  private rootDir?: string

  constructor(context: Context) {

  }

  private async acquireAppUri(context: Context): Promise<string> {
    let documentPicker = new picker.DocumentViewPicker(context);
    let options = new picker.DocumentSaveOptions()
    options.pickerMode = picker.DocumentPickerMode.DOWNLOAD;
    let selectResult: string[] = await documentPicker.save(options);
    let url = selectResult[0];
    let videosDir = new fileUri.FileUri(url + "/Videos").path
    let stat: fs.Stat | undefined
    try {
      stat = await fs.stat(videosDir)
    } catch (e) {
      // file not found.
      try {
        fs.mkdirSync(videosDir)
      } catch (e2) {
        throw new Error("Create directory failed.")
      }
    }

    if (stat && !stat.isDirectory()) {
      throw new Error("Folder type error.")
    }
    return videosDir
  }

  /**
   * 生成共享下载路径uri
   * @returns
   */
  public async acquireRootUri(context: Context): Promise<string> {
    if (!this.rootDir) {
      this.rootDir = await this.acquireAppUri(context)
    }
    return this.rootDir
  }

}