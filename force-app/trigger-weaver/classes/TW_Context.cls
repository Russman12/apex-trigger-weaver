/**
 * Contains functionality relating to the global trigger execution context to be shared amongst all trigger weaver functions.
 * @author Russell Laboe
 * @since 11/07/2024
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
  private final Map<System.Type, ASB_Select> querySelections;

  public TW_Context(Schema.SObjectField idField, Map<Id, SObject> queriedRecordsMap) {
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
    this.querySelections = new Map<System.Type, ASB_Select>();

    this.queriedRecordsMap = queriedRecordsMap;
  }

  public void addQuerySelection(Type t, ASB_Select selection) {
    System.debug('adding?');
    this.querySelections.put(t, selection);
  }

  public Map<Type, ASB_Select> getQuerySelections() {
    return this.querySelections;
  }

  public ASB_Select getQuerySelection(Type t) {
    return this.querySelections.get(t);
  }

  public Boolean isQueryContext() {
    return QUERY_CONTEXTS.contains(Trigger.operationType);
  }

  public System.TriggerOperation getOperation() {
    return this.operation;
  }

  public List<SObject> getNew() {
    return this.newRecords;
  }

  public Map<Id, SObject> getNewMap() {
    return this.newRecordsMap;
  }

  public List<SObject> getOld() {
    return this.oldRecords;
  }

  public Map<Id, SObject> getOldMap() {
    return this.oldRecordsMap;
  }

  public Map<Id, SObject> getQueriedRecordMap() {
    return this.queriedRecordsMap.deepClone();
  }

  public List<SObject> filteredRecords() {
    return this.globalFilteredRecords;
  }
  public List<SObject> filteredRecords(System.Type t) {
    return this.filteredRecords.get(t);
  }
  public void addFilteredRecord(System.Type t, SObject record) {
    if (!this.filteredRecords.containsKey(t)) {
      this.filteredRecords.put(t, new List<SObject>());
    }
    this.filteredRecords.get(t).add(record);
    this.globalFilteredRecords.add(record);
  }

  public class InvalidContextException extends Exception {
  }
}
