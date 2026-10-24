/**
 * Example DML queue that collects records and performs one DML statement per operation when
 * flushed. Execution is AllOrNone so if any record fails DML, an exception is thrown.
 *
 * ```
 * DMLQueue dmlQueue = new DMLQueue();
 * dmlQueue.enqueueInsert(new Account(Name = 'Test Account'));
 * dmlQueue.flush();
 * ```
 */
public with sharing class DMLQueue {
  private final List<SObject> inserts = new List<SObject>();
  private final List<SObject> updates = new List<SObject>();
  private final List<SObject> deletes = new List<SObject>();
  private final List<SObject> undeletes = new List<SObject>();

  /**
   * Enqueues a record for insert
   * @param record The record to enqueue for insert
   */
  public void enqueueInsert(SObject record) {
    inserts.add(record);
  }

  /**
   * Enqueues a record for update
   * @param record The record to enqueue for update
   */
  public void enqueueUpdate(SObject record) {
    updates.add(record);
  }

  /**
   * Enqueues a record for delete
   * @param record The record to enqueue for delete
   */
  public void enqueueDelete(SObject record) {
    deletes.add(record);
  }

  /**
   * Enqueues a record for undelete
   * @param record The record to enqueue for undelete
   */
  public void enqueueUndelete(SObject record) {
    undeletes.add(record);
  }

  /**
   * Executes DML for all queued records and clears the queue. Records are sorted so records of
   * the same SObject type are grouped together.
   */
  public void flush() {
    if (!inserts.isEmpty()) {
      inserts.sort();
      insert inserts;
    }

    if (!updates.isEmpty()) {
      updates.sort();
      update updates;
    }

    if (!deletes.isEmpty()) {
      deletes.sort();
      delete deletes;
    }

    if (!undeletes.isEmpty()) {
      undeletes.sort();
      undelete undeletes;
    }

    inserts.clear();
    updates.clear();
    deletes.clear();
    undeletes.clear();
  }
}
