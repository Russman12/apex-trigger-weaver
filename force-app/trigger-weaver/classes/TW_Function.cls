/**
 * @description Contains common functionality relating to a specific trigger weaver function.
 * @group Framework
 */
public abstract class TW_Function {
  private final System.Type t;

  private TW_Context ctx;

  /**
   * @description Creates a new TW_Function instance.
   * @param t The type of the trigger weaver function.
   */
  protected TW_Function(System.Type t) {
    this.t = t;
  }

  /**
   * @description Returns the DML queue used to enqueue DML operations.
   * @return DML queue.
   */
  protected TW_DMLQueueable getDMLQueue() {
    return this.ctx.getDMLQueue();
  }

  /**
   * @description Sets the context for the trigger weaver function.
   * @param ctx The context to set.
   */
  public void setContext(TW_Context ctx) {
    if (this.ctx != null) {
      throw new InvalidContextException('Context can only be set once');
    }
    this.ctx = ctx;
  }

  /**
   * @description Returns the context for the trigger weaver function.
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
   * @description Returns all filtered records for a given functionality.
   * @return Filtered records.
   */
  public List<SObject> filteredRecords() {
    if (this.ctx == null) {
      throw new InvalidContextException('Context must be set to perform this action. Run setContext(TW_Context ctx) first');
    }
    return ctx.filteredRecords(this.t);
  }

  /**
   * @description Logic that executes once for the function before primary before insert logic.
   */
  protected virtual void beforeInsertPreProcess() {
  }
  /**
   * @description Logic that executes once for the function before primary after insert logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  protected virtual void afterInsertPreProcess(TW_QuerySelectionable selection) {
  }
  /**
   * @description Logic that executes once for the function before primary before update logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  protected virtual void beforeUpdatePreProcess(TW_QuerySelectionable selection) {
  }
  /**
   * @description Logic that executes once for the function before primary after update logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  protected virtual void afterUpdatePreProcess(TW_QuerySelectionable selection) {
  }
  /**
   * @description Logic that executes once for the function before primary before delete logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  protected virtual void beforeDeletePreProcess(TW_QuerySelectionable selection) {
  }
  /**
   * @description Logic that executes once for the function before primary after delete logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  protected virtual void afterDeletePreProcess(TW_QuerySelectionable selection) {
  }
  /**
   * @description Logic that executes once for the function before primary after undelete logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  protected virtual void afterUndeletePreProcess(TW_QuerySelectionable selection) {
  }

  /**
   * @description Primary logic that executes for each record before insert.
   * @param SObject newRecord The new record from trigger.
   */
  protected virtual void beforeInsert(SObject newRecord) {
  }
  /**
   * @description Primary logic that executes for each record after insert.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   * @return List of records to insert.
   */
  protected virtual void afterInsert(SObject newRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record before update.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   * @return List of records to insert.
   */
  protected virtual void beforeUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record after update.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   */
  protected virtual void afterUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record before delete.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   */
  protected virtual void beforeDelete(SObject oldRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record after delete.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   */
  protected virtual void afterDelete(SObject oldRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record before delete.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   */
  protected virtual void afterUndelete(SObject newRecord, SObject queriedRecord) {
  }

  /**
   * @description Overridable method used to determine which records should be processed
   * in before insert context. This method is called before the primary logic for each
   * record. If true, the record will be processed. Default true.
   * @param SObject newRecord The new record from trigger.
   * @return Boolean indicating whether the record should be processed.
   */
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
  protected virtual Boolean afterUndeleteFilter(SObject newRecord) {
    return true;
  }

  /**
   * @description Executes the pre-process logic for the trigger weaver function.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  public void executePreProcess(TW_QuerySelectionable selection) {
    if (this.ctx == null) {
      throw new InvalidContextException('Context must be set to perform this action. Run setContext(TW_Context ctx) first');
    }

    switch on this.ctx.getOperation() {
      when BEFORE_INSERT {
        this.beforeInsertPreProcess();
        for (SObject newRecord : this.ctx.getNew()) {
          if (this.beforeInsertFilter(newRecord)) {
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
      when AFTER_INSERT {
        this.afterInsertPreProcess(selection);
        for (SObject newRecord : this.ctx.getNew()) {
          if (this.afterInsertFilter(newRecord)) {
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
      when BEFORE_UPDATE {
        this.beforeUpdatePreProcess(selection);
        for (SObject newRecord : this.ctx.getNew()) {
          SObject oldRecord = this.ctx.getOldMap().get(newRecord.Id);
          if (this.beforeUpdateFilter(oldRecord, newRecord)) {
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
      when AFTER_UPDATE {
        this.afterUpdatePreProcess(selection);
        for (SObject newRecord : this.ctx.getNew()) {
          SObject oldRecord = this.ctx.getOldMap().get(newRecord.Id);
          if (this.afterUpdateFilter(oldRecord, newRecord)) {
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
      when BEFORE_DELETE {
        this.beforeDeletePreProcess(selection);
        for (SObject oldRecord : this.ctx.getOld()) {
          if (this.beforeDeleteFilter(oldRecord)) {
            ctx.addFilteredRecord(this.t, oldRecord);
          }
        }
      }
      when AFTER_DELETE {
        this.afterDeletePreProcess(selection);
        for (SObject oldRecord : this.ctx.getOld()) {
          if (this.afterDeleteFilter(oldRecord)) {
            ctx.addFilteredRecord(this.t, oldRecord);
          }
        }
      }
      when AFTER_UNDELETE {
        this.afterUndeletePreProcess(selection);
        for (SObject newRecord : this.ctx.getNew()) {
          if (this.afterUndeleteFilter(newRecord)) {
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
    }
  }

  /**
   * @description Executes primary functionality for trigger weaver function for each record which meets filter criteria.
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
