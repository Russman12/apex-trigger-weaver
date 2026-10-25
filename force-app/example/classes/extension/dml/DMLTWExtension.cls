/**
 * Example extension that collects DML from every action in the trigger execution and performs one
 * DML statement per operation once every action has executed. This keeps DML bulkified across
 * actions. Execution is AllOrNone so if any record fails DML, an exception is thrown.
 *
 * Register it on a trigger handler with addExtension:
 * ```
 * new TW_Handler(Account.getSObjectType()).addExtension(DMLTWExtension.class).execute();
 * ```
 *
 * Then enqueue DML from any action:
 * ```
 * public override void afterInsert(SObject newRecord) {
 *   DMLTWExtension dml = (DMLTWExtension) getExtension(DMLTWExtension.class);
 *   dml.enqueueInsert(new Task(WhatId = newRecord.Id, Subject = 'Follow up'));
 * }
 * ```
 */
public with sharing class DMLTWExtension extends TW_Extension {
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
   * Executes DML for all queued records once every action has executed. Records are sorted so
   * records of the same SObject type are grouped together.
   */
  public override void afterExecute(TW_Context ctx) {
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
