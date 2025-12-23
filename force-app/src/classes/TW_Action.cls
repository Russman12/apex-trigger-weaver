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
  public TW_DMLQueue getDMLQueue() {
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
   * @description Returns the old records for the current trigger context.
   * @return Old records.
   */
  public List<SObject> oldRecords() {
    return this.ctx.getOld();
  }

  /**
   * @description Returns the new records for the current trigger context.
   * @return New records.
   */
  public List<SObject> newRecords() {
    return this.ctx.getOld();
  }

  /**
   * @description Returns true if the field has changed for the current record. Returns false if
   * not update context.
   * @param field Field to check.
   * @return True if the field has changed.
   */
  protected Boolean isChanged(Schema.SObjectField field) {
    System.TriggerOperation ctxOp = this.ctx.getOperation();
    if (ctxOp == System.TriggerOperation.BEFORE_UPDATE || ctxOp == System.TriggerOperation.BEFORE_UPDATE) {
      return this.ctx.getOldMap().get(this.ctx.currentRecord.Id).get(field) != this.ctx.currentRecord.get(field);
    }
    return false;
  }

  /**
   * @description Returns true if any of the provided fields have changed for the current record.
   * Returns false if not update context.
   * @param fields Fields to check.
   * @return True if any of the fields have changed.
   */
  protected Boolean anyChanged(Schema.SObjectField[] fields) {
    System.TriggerOperation ctxOp = this.ctx.getOperation();
    if (ctxOp == System.TriggerOperation.BEFORE_UPDATE || ctxOp == System.TriggerOperation.BEFORE_UPDATE) {
      SObject oldRec = this.ctx.getOldMap().get(this.ctx.currentRecord.Id);
      for (Schema.SObjectField field : fields) {
        if (oldRec.get(field) != this.ctx.currentRecord.get(field)) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * @description Returns true if all of the provided fields have changed for the current record.
   * Returns false if not update context.
   * @param fields Fields to check.
   * @return True if all of the fields have changed.
   */
  protected Boolean allChanged(Schema.SObjectField[] fields) {
    System.TriggerOperation ctxOp = this.ctx.getOperation();
    if (ctxOp == System.TriggerOperation.BEFORE_UPDATE || ctxOp == System.TriggerOperation.BEFORE_UPDATE) {
      SObject oldRec = this.ctx.getOldMap().get(this.ctx.currentRecord.Id);
      for (Schema.SObjectField field : fields) {
        if (oldRec.get(field) == this.ctx.currentRecord.get(field)) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  /**
   * @description Logic that executes once for the action before primary before insert logic.
   */
  @TestVisible
  public virtual void beforeInsertSetup() {
  }
  /**
   * @description Logic that executes once for the action before primary after insert logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  @TestVisible
  public virtual void afterInsertSetup(TW_QuerySelector selection) {
  }
  /**
   * @description Logic that executes once for the action before primary before update logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  @TestVisible
  public virtual void beforeUpdateSetup(TW_QuerySelector selection) {
  }
  /**
   * @description Logic that executes once for the action before primary after update logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  @TestVisible
  public virtual void afterUpdateSetup(TW_QuerySelector selection) {
  }
  /**
   * @description Logic that executes once for the action before primary before delete logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  @TestVisible
  public virtual void beforeDeleteSetup(TW_QuerySelector selection) {
  }
  /**
   * @description Logic that executes once for the action before primary after delete logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  @TestVisible
  public virtual void afterDeleteSetup(TW_QuerySelector selection) {
  }
  /**
   * @description Logic that executes once for the action before primary after undelete logic.
   * @param TW_QuerySelectionable selection The selection that will be used to query related records.
   */
  @TestVisible
  public virtual void afterUndeleteSetup(TW_QuerySelector selection) {
  }

  /**
   * @description Overridable method used to determine which records should be processed
   * in before insert context. This method is called before the primary logic for each
   * record. If true, the record will be processed. Default true.
   * @param SObject newRecord The new record from trigger.
   * @return Boolean indicating whether the record should be processed.
   */
  @TestVisible
  public virtual Boolean beforeInsertFilter(SObject newRecord) {
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
  public virtual Boolean afterInsertFilter(SObject newRecord) {
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
  public virtual Boolean beforeUpdateFilter(SObject oldRecord, SObject newRecord) {
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
  public virtual Boolean afterUpdateFilter(SObject oldRecord, SObject newRecord) {
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
  public virtual Boolean beforeDeleteFilter(SObject oldRecord) {
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
  public virtual Boolean afterDeleteFilter(SObject oldRecord) {
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
  public virtual Boolean afterUndeleteFilter(SObject newRecord) {
    return true;
  }

  /**
   * @description Primary logic that executes for each record before insert.
   * @param SObject newRecord The new record from trigger.
   */
  @TestVisible
  public virtual void beforeInsert(SObject newRecord) {
  }
  /**
   * @description Primary logic that executes for each record after insert.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   * @return List of records to insert.
   */
  @TestVisible
  public virtual void afterInsert(SObject newRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record before update.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   * @return List of records to insert.
   */
  @TestVisible
  public virtual void beforeUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record after update.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   */
  @TestVisible
  public virtual void afterUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record before delete.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   */
  @TestVisible
  public virtual void beforeDelete(SObject oldRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record after delete.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   */
  @TestVisible
  public virtual void afterDelete(SObject oldRecord, SObject queriedRecord) {
  }
  /**
   * @description Primary logic that executes for each record after undelete.
   * @param SObject newRecord The new record from trigger.
   * @param SObject queriedRecord The record with queried data applied.
   */
  @TestVisible
  public virtual void afterUndelete(SObject newRecord, SObject queriedRecord) {
  }

  public class InvalidContextException extends Exception {
  }
}
