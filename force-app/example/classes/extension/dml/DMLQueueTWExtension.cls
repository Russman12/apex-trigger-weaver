/**
 * Example extension that shares one DML queue between all actions implementing DMLQueueAware,
 * and flushes it once after every action has executed. This keeps DML bulkified across actions.
 *
 * Register it on a trigger handler with addExtension:
 * ```
 * new TW_Handler(Account.getSObjectType()).addExtension(new DMLQueueTWExtension()).execute();
 * ```
 */
public with sharing class DMLQueueTWExtension extends TW_Extension {
  @TestVisible
  private final DMLQueue queue = new DMLQueue();

  /**
   * Inject the shared queue into every action that performs DML
   */
  public override void onStart(TW_Context ctx, List<TW_Action> actions) {
    for (TW_Action action : actions) {
      if (action instanceof DMLQueueAware) {
        ((DMLQueueAware) action).setDMLQueue(queue);
      }
    }
  }

  /**
   * Flush all queued DML once every action has executed
   */
  public override void afterExecute(TW_Context ctx) {
    queue.flush();
  }
}
