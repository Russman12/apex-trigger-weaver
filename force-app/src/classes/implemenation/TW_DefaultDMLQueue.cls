/**
 * @description This class provides a basic TW_DMLQueueable implementation
 * that allows DML queuing. Execution is AllOrNone so if any record fails DML,
 * an exception is thrown.
 *
 * @group Default Implementation
 *
 * @example
 * ```
 * TW_DMLQueue dmlQueue = new TW_DMLQueue();
 * dmlQueue.enqueueInsert(new Account(Name='Test Account'));
 * dmlQueue.flush();
 * ```
 */
public with sharing class TW_DefaultDMLQueue implements TW_DMLQueue {
  private final Map<String, List<SObject>> dmlQueue = new Map<String, List<SObject>>();

  /**
   * @description Enqueues a record for insert
   *
   * @param record The record to enqueue for insert
   *
   * @example
   * ```
   * TW_DMLQueue dmlQueue = new TW_DMLQueue();
   * dmlQueue.enqueueInsert(new Account(Name='Test Account'));
   * dmlQueue.flush();
   * ```
   */
  public void enqueueInsert(SObject record) {
    if (!dmlQueue.containsKey('insert')) {
      dmlQueue.put('insert', new List<SObject>());
    }

    dmlQueue.get('insert').add(record);
  }

  /**
   * @description Enqueues a record for update
   *
   * @param record The record to enqueue for update
   *
   * @example
   * ```
   * TW_DMLQueue dmlQueue = new TW_DMLQueue();
   * dmlQueue.enqueueUpdate(new Account(Name='Test Account'));
   * dmlQueue.flush();
   * ```
   */
  public void enqueueUpdate(SObject record) {
    if (!dmlQueue.containsKey('update')) {
      dmlQueue.put('update', new List<SObject>());
    }

    dmlQueue.get('update').add(record);
  }

  /**
   * @description Enqueues a record for delete
   *
   * @param record The record to enqueue for delete
   *
   * @example
   * ```
   * TW_DMLQueue dmlQueue = new TW_DMLQueue();
   * dmlQueue.enqueueDelete(new Account(Id = '001AAdfbj1j4j12331'));
   * dmlQueue.flush();
   * ```
   */
  public void enqueueDelete(SObject record) {
    if (!dmlQueue.containsKey('delete')) {
      dmlQueue.put('delete', new List<SObject>());
    }

    dmlQueue.get('delete').add(record);
  }

  /**
   * @description Enqueues a record for undelete
   *
   * @param record The record to enqueue for undelete
   *
   * @example
   * ```
   * TW_DMLQueue dmlQueue = new TW_DMLQueue();
   * dmlQueue.enqueueUndelete(new Account(Id = '001AAdfbj1j4j12331'));
   * dmlQueue.flush();
   * ```
   */
  public void enqueueUndelete(SObject record) {
    if (!dmlQueue.containsKey('undelete')) {
      dmlQueue.put('undelete', new List<SObject>());
    }

    dmlQueue.get('undelete').add(record);
  }

  /**
   * @description Executes DML for all queued records and clears the queue
   *
   * @returns null
   *
   * @example
   * ```
   * TW_DMLQueue dmlQueue = new TW_DMLQueue();
   * dmlQueue.enqueueInsert(new Account(Name='Test Account'));
   * dmlQueue.flush();
   * ```
   */
  public List<String> flush() {
    if (this.dmlQueue.containsKey('insert')) {
      List<SObject> inserts = this.dmlQueue.get('insert');
      inserts.sort();
      insert inserts;
    }

    if (this.dmlQueue.containsKey('update')) {
      List<SObject> updates = this.dmlQueue.get('update');
      updates.sort();
      update updates;
    }

    if (this.dmlQueue.containsKey('delete')) {
      List<SObject> deletes = this.dmlQueue.get('delete');
      deletes.sort();
      delete deletes;
    }

    if (this.dmlQueue.containsKey('undelete')) {
      List<SObject> undeletes = this.dmlQueue.get('undelete');
      undeletes.sort();
      undelete undeletes;
    }

    this.dmlQueue.clear();
    return null;
  }
}
