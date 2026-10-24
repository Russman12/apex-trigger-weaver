/**
 * Implemented by actions that perform DML. When DMLQueueTWExtension is registered, it injects
 * a DML queue shared by all actions in the trigger execution, and flushes it once after every
 * action has executed.
 *
 * ```
 * public class MyAction extends TW_Action implements DMLQueueAware {
 *   private DMLQueue dml;
 *
 *   public void setDMLQueue(DMLQueue queue) {
 *     this.dml = queue;
 *   }
 *
 *   public override void afterInsert(SObject newRecord) {
 *     dml.enqueueInsert(new Task(WhatId = newRecord.Id, Subject = 'Follow up'));
 *   }
 * }
 * ```
 */
public interface DMLQueueAware {
  /**
   * Receives the shared DML queue. Called once before the action's filters execute.
   * @param queue The shared DML queue.
   */
  void setDMLQueue(DMLQueue queue);
}
