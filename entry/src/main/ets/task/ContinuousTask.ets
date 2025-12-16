import { wantAgent } from "@kit.AbilityKit"
import { backgroundTaskManager } from "@kit.BackgroundTasksKit"
import BuildProfile from 'BuildProfile';

export class ContinuousTask {

  private context: Context

  private inLongTimeTask = false

  constructor(context: Context) {
    this.context = context
  }

  isInContinuous(): boolean {
    return this.inLongTimeTask
  }

  /**
   * Start a long-time task.
   */
  async startContinuousTask(): Promise<void> {
    if (this.inLongTimeTask) {
      return
    }
    if (BuildProfile.DEBUG) {
      console.info("ContinuousTask", 'start background.');
    }
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: this.context.applicationInfo.name,
          abilityName: 'EntryAbility'
        }
      ],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    let tmpWantAgent = await wantAgent.getWantAgent(wantAgentInfo);
    await backgroundTaskManager.startBackgroundRunning(this.context,
      backgroundTaskManager.BackgroundMode.DATA_TRANSFER, tmpWantAgent);
    this.inLongTimeTask = true
    if (BuildProfile.DEBUG) {
      console.info("ContinuousTask", 'start background finish.');
    }
  }

  /**
   * Close a long-time task.
   */
  async stopContinuousTask(): Promise<void> {
    if (!this.inLongTimeTask) {
      return
    }
    if (BuildProfile.DEBUG) {
      console.info("ContinuousTask", 'stop background.');
    }
    await backgroundTaskManager.stopBackgroundRunning(this.context)
    this.inLongTimeTask = false
    if (BuildProfile.DEBUG) {
      console.info("ContinuousTask", 'stop background end.');
    }
  }

}