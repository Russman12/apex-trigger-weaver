/**
 * @description Contains functionality relating to the global trigger execution. Data and functions
 * contained within this class should be common to all trigger weaver actions part of the running
 * execution context.
 * @internal
 */
public with sharing class TW_Context {
  private static final Set<System.TriggerOperation> QUERY_CONTEXTS = new Set<System.TriggerOperation>{
    System.TriggerOperation.AFTER_INSERT,
    System.TriggerOperation.BEFORE_UPDATE,
    System.TriggerOperation.AFTER_UPDATE,
    System.TriggerOperation.BEFORE_DELETE,
    System.TriggerOperation.AFTER_DELETE,
    System.TriggerOperation.AFTER_UNDELETE
  };

  private final TW_DMLQueue dmlQueue;
  private final TW_Query query;

  private Map<Id, SObject> queriedRecords;

  /**
   * @description The current record which is being executed.
   */
  public SObject currentRecord;

  /**
   * @description Creates a new TW_Context instance. Throws exception if not in trigger context.
   * @param idField The Id field of the SObject type.
   * @throws InvalidContextException if not in trigger context.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * ```
   */
  public TW_Context(TW_DMLQueue dmlQueue, TW_Query query) {
    //throw execption if not in trigger context
    if (!Trigger.isExecuting) {
      throw new InvalidContextException('Unable to create TW_Handler outside of a trigger context');
    }

    this.dmlQueue = dmlQueue;
    this.query = query;
  }

  /**
   * @description Returns the query instance.
   * @return The query instance.
   */
  public TW_Query getQuery() {
    return query;
  }

  /**
   * @description Returns the current trigger operation.
   * @return The current trigger operation.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * System.TriggerOperation operation = ctx.getOperation();
   * ```
   */
  public System.TriggerOperation getOperation() {
    return Trigger.operationType;
  }

  /**
   * @descriptions Returns new trigger records.
   * @return New trigger records.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * List<SObject> newRecords = ctx.getNew();
   * ```
   */
  public List<SObject> getNew() {
    return Trigger.new;
  }

  /**
   * @description Returns new trigger records as a Map<Id, SObject>.
   * @return New trigger records map.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * Map<Id, SObject> newRecordsMap = ctx.getNewMap();
   * ```
   */
  public Map<Id, SObject> getNewMap() {
    return Trigger.newMap;
  }

  /**
   * @description Returns old trigger records.
   * @return Old trigger records.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * List<SObject> oldRecords = ctx.getOld();
   * ```
   */
  public List<SObject> getOld() {
    return Trigger.old;
  }

  /**
   * @description Returns old trigger record for the given record. The
   * given record must have an Id set.
   * @return The old record.
   */
  public SObject getOld(SObject r) {
    return Trigger.oldMap.get(r.Id);
  }

  /**
   * @description Returns old trigger records as a Map<Id, SObject>.
   * @return Old trigger records map.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * Map<Id, SObject> oldRecordsMap = ctx.getOldMap();
   * ```
   */
  public Map<Id, SObject> getOldMap() {
    return Trigger.oldMap;
  }

  /**
   * @description Returns either new trigger records if set, else returns old records.
   * @return The list of trigger records
   */
  public List<SObject> getRecords() {
    if (Trigger.new != null && !Trigger.new.isEmpty()) {
      return Trigger.new;
    }
    return Trigger.old;
  }

  /**
   * @description Returns queried records as a Map<Id, SObject>. Records are cloned to ensure immutabillity.
   * @return Queried records map.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * Map<Id, SObject> queriedRecordsMap = ctx.getQueriedRecordMap();
   * ```
   */
  public Map<Id, SObject> getQueriedRecordMap() {
    if (queriedRecords == null) {
      throw new InvalidContextException('unable to retrieve queried records before setup completes');
    }
    return queriedRecords.deepClone();
  }

  /**
   * @description Returns queried instance of the given record. Executes query if results are unset.
   * This should only be called after the query selector is fully constructed.
   * @return The SObject record.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * SObject queriedRec1 = ctx.getQueriedRecord(rec1); // executes query and returns record
   * SObject queriedRec2 = ctx.getQueriedRecord(rec2); // returns record and does not query again
   * ```
   */
  public SObject getQueriedRecord(SObject rec) {
    if (queriedRecords == null) {
      queriedRecords = new Map<Id, SObject>();
      if (query.getSelector().isSet()) {
        queriedRecords = new Map<Id, SObject>(this.query.run(getRecords()));
      }
    }
    return queriedRecords.get(rec.Id).clone(true, true, true, true);
  }

  /**
   * @description Returns the DML queue used to enqueue DML operations.
   * @return DML queue.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * TW_DMLQueueable dmlQueue = ctx.getDMLQueue();
   * ```
   */
  public TW_DMLQueue getDMLQueue() {
    return this.dmlQueue;
  }

  /**
   * @Returns True if the field has changed for the current record. Throws exception if not update context.
   * @param field Field to check.
   */
  public Boolean isChanged(Schema.SObjectField field) {
    if (!Trigger.isUpdate) {
      throw new InvalidContextException('isChanged can only be called in an update context');
    }
    return getOld(currentRecord).get(field) != currentRecord.get(field);
  }

  /**
   * @Returns True if any of the given fields have changed for the current record. Throws exception if not update context.
   * @param fields Fields to check.
   */
  public Boolean anyChanged(List<Schema.SObjectField> fields) {
    if (!Trigger.isUpdate) {
      throw new InvalidContextException('isChanged can only be called in an update context');
    }
    SObject oldRec = getOld(currentRecord);
    for (Schema.SObjectField field : fields) {
      if (oldRec.get(field) != currentRecord.get(field)) {
        return true;
      }
    }
    return false;
  }

  /**
   * @Returns True if all of the given fields have changed for the current record. Throws exception if not update context.
   * @param fields Fields to check.
   */
  public Boolean allChanged(List<Schema.SObjectField> fields) {
    if (!Trigger.isUpdate) {
      throw new InvalidContextException('isChanged can only be called in an update context');
    }
    SObject oldRec = getOld(currentRecord);
    for (Schema.SObjectField field : fields) {
      if (oldRec.get(field) == currentRecord.get(field)) {
        return false;
      }
    }
    return true;
  }

  /**
   * @description Represents an exception relating to the context.
   */
  public class InvalidContextException extends Exception {
  }
}
