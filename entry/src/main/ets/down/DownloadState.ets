/**
 * 下载状态模型，供 UI 层响应式绑定
 */
@Observed
export class DownloadState {

  /** 是否正在下载 */
  downloading: boolean = false

  /** 已下载字节数 */
  processed: number = 0

  /** 文件总字节数，-1 表示未知 */
  total: number = -1

  /** 当前下载速度，单位 bytes/s */
  speed: number = 0

  // 速度采样用的内部状态
  private lastTimestamp: number = 0
  private lastProcessed: number = 0

  /**
   * 进度 0~1，-1 表示总大小未知
   */
  get progress(): number {
    if (this.total <= 0) {
      return -1
    }
    return this.processed / this.total
  }

  /**
   * 格式化进度百分比，如 "45%"，未知时返回 ""
   */
  get progressText(): string {
    if (this.progress < 0) {
      return ''
    }
    return Math.floor(this.progress * 100) + '%'
  }

  /**
   * 格式化速度，如 "1.2 MB/s" / "512 KB/s"
   */
  get speedText(): string {
    if (this.speed <= 0) {
      return ''
    }
    if (this.speed >= 1024 * 1024) {
      return (this.speed / 1024 / 1024).toFixed(1) + ' MB/s'
    }
    if (this.speed >= 1024) {
      return Math.floor(this.speed / 1024) + ' KB/s'
    }
    return Math.floor(this.speed) + ' B/s'
  }

  /**
   * 格式化已下载/总大小，如 "12 MB / 27 MB"
   */
  get sizeText(): string {
    if (this.total <= 0) {
      return DownloadState.formatSize(this.processed)
    }
    return DownloadState.formatSize(this.processed) + ' / ' + DownloadState.formatSize(this.total)
  }

  /**
   * 收到进度回调时调用，同时计算实时速度（每 500ms 采样一次）
   */
  update(processed: number, total: number): void {
    const now = Date.now()
    const elapsed = (now - this.lastTimestamp) / 1000
    if (this.lastTimestamp > 0 && elapsed >= 0.5) {
      this.speed = (processed - this.lastProcessed) / elapsed
      this.lastTimestamp = now
      this.lastProcessed = processed
    } else if (this.lastTimestamp === 0) {
      this.lastTimestamp = now
      this.lastProcessed = processed
    }
    this.processed = processed
    this.total = total
  }

  /** 开始下载前重置状态 */
  start(): void {
    this.downloading = true
    this.processed = 0
    this.total = -1
    this.speed = 0
    this.lastTimestamp = 0
    this.lastProcessed = 0
  }

  /** 下载完成或失败后重置 */
  finish(): void {
    this.downloading = false
    this.processed = 0
    this.total = -1
    this.speed = 0
    this.lastTimestamp = 0
    this.lastProcessed = 0
  }

  private static formatSize(bytes: number): string {
    if (bytes >= 1024 * 1024 * 1024) {
      return (bytes / 1024 / 1024 / 1024).toFixed(1) + ' GB'
    }
    if (bytes >= 1024 * 1024) {
      return (bytes / 1024 / 1024).toFixed(1) + ' MB'
    }
    if (bytes >= 1024) {
      return Math.floor(bytes / 1024) + ' KB'
    }
    return bytes + ' B'
  }
}
