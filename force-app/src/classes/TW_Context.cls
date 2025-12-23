/**
 * @description Contains functionality relating to the global trigger execution. Data and functions
 * contained within this class should be common to all trigger weaver actions part of the running
 * execution context.
 * @group Framework
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
   * @description Returns true if the current trigger operation is a candidate for querying.
   * @return True if the current trigger operation is a candidate for querying.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * Boolean isQueryContext = ctx.isQueryContext();
   * ```
   */
  public Boolean isQueryContext() {
    return QUERY_CONTEXTS.contains(Trigger.operationType);
  }

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

  public SObject getNew(SObject r) {
    return Trigger.newMap.get(r.Id);
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

  public SObject getOld(SObject r) {
    return Trigger.oldMap.get(r.Id);
  }

  /**
   * @description Returns old or new records depending trigger context.
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
   * @description Represents an exception relating to the context.
   */
  public class InvalidContextException extends Exception {
  }
}
