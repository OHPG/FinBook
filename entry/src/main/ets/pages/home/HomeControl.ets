export class HomeControl {

  public callback?: Callback<void, boolean>

  public goBack(): boolean {
    if (this.callback) {
      return this.callback()
    }
    return false
  }

}