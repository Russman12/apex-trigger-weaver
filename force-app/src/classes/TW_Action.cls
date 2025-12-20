/**
 * @description Contains common functionality relating to a specific trigger weaver action.
 * @group Framework
 */
public abstract class TW_Action {
  private System.Type t;

  @TestVisible
  private TW_Context ctx;

  /**
   * @description Returns the DML queue used to enqueue DML operations.
   * @return DML queue.
   */
  @TestVisible
  protected TW_DMLQueueable getDMLQueue() {
    return this.ctx.getDMLQueue();
  }

  /**
   * @description Sets the context for the trigger weaver action.
   * @param ctx The context to set.
   */
  public void setContext(TW_Context ctx) {
    if (this.ctx != null) {
      throw new InvalidContextException('Context can only be set once');
    }
    this.ctx = ctx;
  }

  /**
   * @description Returns the context for the trigger weaver action.
   * @return The context.
   */
  public TW_Context getContext() {
    return this.ctx;
  }

  /**
   * @description Returns the type of this instance.
   * @return The type of this instance.
   */
  public System.Type getType() {
    return this.t;
  }

  /**
   * @description assigns the type of this instance.
   */
  public void setType(System.Type t) {
    this.t = t;
  }

  /**
   * @description Returns all filtered records for a given trigger weaver action.
   * @return Filtered records.
   */
  public List<SObject> filteredRecords() {
    if (this.ctx == null) {
      throw new InvalidContextException('Context must be set to perform this action. Run setContext(TW_Context ctx) first');
    }
    return ctx.filteredRecords(this.t);
  }

  /**
   * @description Logic that executes once for the action before primary before insert logic.
   */
  @TestVisible
  protected virtual void beforeInsertSetup() {
  }
  /**
   * @description Logic that executes once for the action before primary after insert logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  @TestVisible
  protected virtual void afterInsertSetup(TW_QuerySelectionable selection) {
  }
  /**
   * @description Logic that executes once for the action before primary before update logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  @TestVisible
  protected virtual void beforeUpdateSetup(TW_QuerySelectionable selection) {
  }
  /**
   * @description Logic that executes once for the action before primary after update logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  @TestVisible
  protected virtual void afterUpdateSetup(TW_QuerySelectionable selection) {
  }
  /**
   * @description Logic that executes once for the action before primary before delete logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  @TestVisible
  protected virtual void beforeDeleteSetup(TW_QuerySelectionable selection) {
  }
  /**
   * @description Logic that executes once for the action before primary after delete logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  @TestVisible
  protected virtual void afterDeleteSetup(TW_QuerySelectionable selection) {
  }
  /**
   * @description Logic that executes once for the action before primary after undelete logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  @TestVisible
  protected virtual void afterUndeleteSetup(TW_QuerySelectionable selection) {
  }

  /**
   * @description Overridable method used to determine which records should be processed
   * in before insert context. This method is called before the primary logic for each
   * record. If true, the record will be processed. Default true.
   * @param SObject newRecord The new record from trigger.
   * @return Boolean indicating whether the record should be processed.
   */
  @TestVisible
  protected virtual Boolean beforeInsertFilter(SObject newRecord) {
    return true;
  }
  /**
   * @description Overridable method used to determine which records should be processed
   * in after insert context. This method is called before the primary logic for each
   * record. If true, the record will be processed. Default true.
   * @param SObject newRecord The new record from trigger.
   * @return Boolean indicating whether the record should be processed.
   */
  @TestVisible
  protected virtual Boolean afterInsertFilter(SObject newRecord) {
    return true;
  }
  /**
   * @description Overridable method used to determine which records should be processed
   * in before update context. This method is called before the primary logic for each
   * record. If true, the record will be processed. Default true.
   * @param SObject newRecord The new record from trigger.
   * @return Boolean indicating whether the record should be processed.
   */
  @TestVisible
  protected virtual Boolean beforeUpdateFilter(SObject oldRecord, SObject newRecord) {
    return true;
  }
  /**
   * @description Overridable method used to determine which records should be processed
   * in after update context. This method is called before the primary logic for each
   * record. If true, the record will be processed. Default true.
   * @param SObject newRecord The new record from trigger.
   * @return Boolean indicating whether the record should be processed.
   */
  @TestVisible
  protected virtual Boolean afterUpdateFilter(SObject oldRecord, SObject newRecord) {
    return true;
  }
  /**
   * @description Overridable method used to determine which records should be processed
   * in before delete context. This method is called before the primary logic for each
   * record. If true, the record will be processed. Default true.
   * @param SObject newRecord The new record from trigger.
   * @return Boolean indicating whether the record should be processed.
   */
  @TestVisible
  protected virtual Boolean beforeDeleteFilter(SObject oldRecord) {
    return true;
  }
  /**
   * @description Overridable method used to determine which records should be processed
   * in after delete context. This method is called before the primary logic for each
   * record. If true, the record will be processed. Default true.
   * @param SObject newRecord The new record from trigger.
   * @return Boolean indicating whether the record should be processed.
   */
  @TestVisible
  protected virtual Boolean afterDeleteFilter(SObject oldRecord) {
    return true;
  }
  /**
   * @description Overridable method used to determine which records should be processed
   * in after undelete context. This method is called before the primary logic for each
   * record. If true, the record will be processed. Default true.
   * @param SObject newRecord The new record from trigger.
   * @return Boolean indicating whether the record should be processed.
   */
  @TestVisible
  protected virtual Boolean afterUndeleteFilter(SObject newRecord) {
    return true;
  }

  /**
   * @description Primary logic that executes for each record before insert.
   * @param SObject newRecord The new record from trigger.
   */
  @TestVisible
  protected virtual void beforeInsert(SObject newRecord) {
  }
  /**
   * @description Primary logic that executes for each record after insert.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   * @return List of records to insert.
   */
  @TestVisible
  protected virtual void afterInsert(SObject newRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record before update.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   * @return List of records to insert.
   */
  @TestVisible
  protected virtual void beforeUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record after update.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   */
  @TestVisible
  protected virtual void afterUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record before delete.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   */
  @TestVisible
  protected virtual void beforeDelete(SObject oldRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record after delete.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   */
  @TestVisible
  protected virtual void afterDelete(SObject oldRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record after undelete.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   */
  @TestVisible
  protected virtual void afterUndelete(SObject newRecord, SObject queriedRecord) {
  }

  /**
   * @description Primary logic that executes for each record after delete.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   */
  public void executeSetup(TW_QuerySelectionable selection) {
    if (this.ctx == null) {
      throw new InvalidContextException('Context must be set to perform this action. Run setContext(TW_Context ctx) first');
    }

    switch on this.ctx.getOperation() {
      when BEFORE_INSERT {
        this.beforeInsertSetup();
        for (SObject newRecord : this.ctx.getNew()) {
          if (this.beforeInsertFilter(newRecord)) {
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
      when AFTER_INSERT {
        this.afterInsertSetup(selection);
        for (SObject newRecord : this.ctx.getNew()) {
          if (this.afterInsertFilter(newRecord)) {
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
      when BEFORE_UPDATE {
        this.beforeUpdateSetup(selection);
        for (SObject newRecord : this.ctx.getNew()) {
          SObject oldRecord = this.ctx.getOldMap().get(newRecord.Id);
          if (this.beforeUpdateFilter(oldRecord, newRecord)) {
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
      when AFTER_UPDATE {
        this.afterUpdateSetup(selection);
        for (SObject newRecord : this.ctx.getNew()) {
          SObject oldRecord = this.ctx.getOldMap().get(newRecord.Id);
          if (this.afterUpdateFilter(oldRecord, newRecord)) {
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
      when BEFORE_DELETE {
        this.beforeDeleteSetup(selection);
        for (SObject oldRecord : this.ctx.getOld()) {
          if (this.beforeDeleteFilter(oldRecord)) {
            ctx.addFilteredRecord(this.t, oldRecord);
          }
        }
      }
      when AFTER_DELETE {
        this.afterDeleteSetup(selection);
        for (SObject oldRecord : this.ctx.getOld()) {
          if (this.afterDeleteFilter(oldRecord)) {
            ctx.addFilteredRecord(this.t, oldRecord);
          }
        }
      }
      when AFTER_UNDELETE {
        this.afterUndeleteSetup(selection);
        for (SObject newRecord : this.ctx.getNew()) {
          if (this.afterUndeleteFilter(newRecord)) {
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
    }
  }
  /**
   * @description Executes primary functionality for trigger weaver action for each record which meets filter criteria.
   */
  public void execute() {
    if (this.ctx == null) {
      throw new InvalidContextException('Context must be set to perform this action. Run setContext(TW_Context ctx) first');
    }
    switch on this.ctx.getOperation() {
      when BEFORE_INSERT {
        for (SObject newRecord : this.ctx.filteredRecords()) {
          if (this.beforeInsertFilter(newRecord)) {
            this.beforeInsert(newRecord);
          }
        }
      }
      when AFTER_INSERT {
        for (SObject newRecord : this.ctx.filteredRecords()) {
          if (this.afterInsertFilter(newRecord)) {
            this.afterInsert(newRecord, this.ctx.getQueriedRecordMap().get(newRecord.Id));
          }
        }
      }
      when BEFORE_UPDATE {
        for (SObject newRecord : this.ctx.filteredRecords()) {
          SObject oldRecord = this.ctx.getOldMap().get(newRecord.Id);
          if (this.beforeUpdateFilter(oldRecord, newRecord)) {
            this.beforeUpdate(oldRecord, newRecord, this.ctx.getQueriedRecordMap().get(newRecord.Id));
          }
        }
      }
      when AFTER_UPDATE {
        for (SObject newRecord : this.ctx.filteredRecords()) {
          SObject oldRecord = this.ctx.getOldMap().get(newRecord.Id);
          if (this.afterUpdateFilter(oldRecord, newRecord)) {
            this.afterUpdate(oldRecord, newRecord, this.ctx.getQueriedRecordMap().get(newRecord.Id));
          }
        }
      }
      when BEFORE_DELETE {
        for (SObject oldRecord : this.ctx.filteredRecords()) {
          if (this.beforeDeleteFilter(oldRecord)) {
            this.beforeDelete(oldRecord, this.ctx.getQueriedRecordMap().get(oldRecord.Id));
          }
        }
      }
      when AFTER_DELETE {
        for (SObject oldRecord : this.ctx.filteredRecords()) {
          if (this.afterDeleteFilter(oldRecord)) {
            this.afterDelete(oldRecord, this.ctx.getQueriedRecordMap().get(oldRecord.Id));
          }
        }
      }
      when AFTER_UNDELETE {
        for (SObject newRecord : this.ctx.filteredRecords()) {
          if (this.afterUndeleteFilter(newRecord)) {
            this.afterUndelete(newRecord, this.ctx.getQueriedRecordMap().get(newRecord.Id));
          }
        }
      }
    }
  }

  public class InvalidContextException extends Exception {
  }
}
