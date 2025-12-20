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

  private final List<SObject> oldRecords;
  private final List<SObject> newRecords;
  private final Map<Id, SObject> oldRecordsMap;
  private final Map<Id, SObject> newRecordsMap;
  private final Map<Id, SObject> queriedRecordsMap;
  private final System.TriggerOperation operation;

  private final Map<System.Type, List<SObject>> filteredRecords;
  private final List<SObject> globalFilteredRecords;
  private final TW_DMLQueueable dmlQueue;

  /**
   * @description Creates a new TW_Context instance. Throws exception if not in trigger context.
   * @param idField The Id field of the SObject type.
   * @throws InvalidContextException if not in trigger context.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * ```
   */
  public TW_Context(Map<Id, SObject> queriedRecordsMap, TW_DMLQueueable dmlQueue) {
    //throw execption if not in trigger context
    if (!Trigger.isExecuting) {
      throw new InvalidContextException('Unable to create TW_Handler outside of a trigger context');
    }

    this.oldRecords = Trigger.old;
    this.newRecords = Trigger.new;
    this.oldRecordsMap = Trigger.oldMap;
    this.newRecordsMap = Trigger.newMap;
    this.operation = Trigger.operationType;
    this.filteredRecords = new Map<System.Type, List<SObject>>();
    this.globalFilteredRecords = new List<SObject>();
    this.dmlQueue = dmlQueue;
    this.queriedRecordsMap = queriedRecordsMap;
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
    return this.operation;
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
    return this.newRecords;
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
    return this.newRecordsMap;
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
    return this.oldRecords;
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
    return this.oldRecordsMap;
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
    return this.queriedRecordsMap.deepClone();
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
  public TW_DMLQueueable getDMLQueue() {
    return this.dmlQueue;
  }

  /**
   * @description Returns all filtered records.
   * @return Filtered records.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * List<SObject> filteredRecs = ctx.filteredRecords();
   * ```
   */
  public List<SObject> filteredRecords() {
    return this.globalFilteredRecords;
  }

  /**
   * @description Returns all filtered records for a given functionality.
   * @return Filtered records.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * List<SObject> filteredRecs = ctx.filteredRecords(MyFunc.class);
   * ```
   */
  public List<SObject> filteredRecords(System.Type t) {
    return this.filteredRecords.get(t);
  }

  /**
   * @description Adds a record to the filtered records list.
   * @param record Record to add.
   * @example
   * ```
   */
  public void addFilteredRecord(System.Type t, SObject record) {
    if (!this.filteredRecords.containsKey(t)) {
      this.filteredRecords.put(t, new List<SObject>());
    }
    this.filteredRecords.get(t).add(record);
    this.globalFilteredRecords.add(record);
  }

  /**
   * @description Represents an exception relating to the context.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * try {
   */
  public class InvalidContextException extends Exception {
  }
}
