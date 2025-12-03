import fs from '@ohos.file.fs';
import { image } from '@kit.ImageKit';

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/9/12 16:19
 * @Version V1.0
 * @Description: 
 */
export class ImageUtil {

  /**
   * 图片保存成文件
   * https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/image-encoding
   * @param pixel
   * @param path
   * @returns
   */
  public static async packImage(pixel: PixelMap, path: string): Promise<void> {
    let packer: image.ImagePacker | undefined
    let file: fs.File | undefined
    try {
      // 文件夹不存在，再创建
      file = await fs.open(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      let packOpts : image.PackingOption = { format:"image/jpeg", quality:90 };
      packOpts.desiredDynamicRange = image.PackingDynamicRange.AUTO;
      packer = image.createImagePacker();
      await packer.packToFile(pixel, file.fd, packOpts)
      await fs.close(file.fd)
      file = undefined
    } catch (e) {
      // 出错时，删除临时文件
      try {
        await fs.unlink(path)
      } catch (e) {
      }
      throw e as Error
    } finally {
      if (packer) {
        try {
          await packer.release()
        } catch (e) {
          // ignore
        }
      }
      if (file) {
        try {
          await fs.close(file.fd)
        } catch (e) {
          // ignore
        }
        file = undefined
      }
    }
  }

  /**
   * 读取图片
   * @param path
   * @returns
   */
  public static async readImage(path: string): Promise<PixelMap> {
    let imageSource: image.ImageSource | undefined
    try {
      imageSource = image.createImageSource(path);
      let opts: image.DecodingOptions = { editable: false };
      return await imageSource.createPixelMap(opts)
    } finally {
      await imageSource?.release()
    }
  }

}