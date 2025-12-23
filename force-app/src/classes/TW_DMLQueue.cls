/**
 * @description Represents functionality that queues and executes DML operations
 */
public interface TW_DMLQueue {
  /**
   * @description Enqueues an insert operation for the given record.
   * @param record Record to insert.
   * @example
   * ```
   * TW_DMLQueueable dmlQueue = new TW_DMLQueueable();
   * dmlQueue.enqueueInsert(record);
   * ```
   */
  void enqueueInsert(SObject record);

  /**
   * @description Enqueues an update operation for the given record.
   * @param record Record to update.
   * @example
   * ```
   * TW_DMLQueueable dmlQueue = new TW_DMLQueueable();
   * dmlQueue.enqueueUpdate(record);
   * ```
   */
  void enqueueUpdate(SObject record);

  /**
   * @description Enqueues a delete operation for the given record.
   * @param record Record to delete.
   * @example
   * ```
   * TW_DMLQueueable dmlQueue = new TW_DMLQueueable();
   * dmlQueue.enqueueDelete(record);
   * ```
   */
  void enqueueDelete(SObject record);

  /**
   * @description Enqueues an undelete operation for the given record.
   * @param record Record to undelete.
   * @example
   * ```
   * TW_DMLQueueable dmlQueue = new TW_DMLQueueable();
   * dmlQueue.enqueueUndelete(record);
   * ```
   */
  void enqueueUndelete(SObject record);

  /**
   * @description Flushes the queue and executes all queued DML operations.
   * @return List of errors that occurred during the execution of the DML operations.
   */
  List<String> flush();
}
