/**
 * Basic TW_DMLQueueable implementation that allows DML queuing. Execution is AllOrNone
 * so if any record fails DML, an exception is thrown.
 */
public with sharing class TW_DMLQueue implements TW_DMLQueueable {
  private final Map<String, List<SObject>> dmlQueue = new Map<String, List<SObject>>();

  public void enqueueInsert(SObject record) {
    if (!dmlQueue.containsKey('insert')) {
      dmlQueue.put('insert', new List<SObject>());
    }

    dmlQueue.get('insert').add(record);
  }

  public void enqueueUpdate(SObject record) {
    if (!dmlQueue.containsKey('update')) {
      dmlQueue.put('update', new List<SObject>());
    }

    dmlQueue.get('update').add(record);
  }

  public void enqueueDelete(SObject record) {
    if (!dmlQueue.containsKey('delete')) {
      dmlQueue.put('delete', new List<SObject>());
    }

    dmlQueue.get('delete').add(record);
  }

  public void enqueueUndelete(SObject record) {
    if (!dmlQueue.containsKey('undelete')) {
      dmlQueue.put('undelete', new List<SObject>());
    }

    dmlQueue.get('undelete').add(record);
  }

  /**
   * Executes DML for all queued records and clears the queue
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
