/**
 * @description Contains common functionality relating to a specific trigger weaver action.
 * @group Framework
 */
public abstract class TW_Action {
  @TestVisible
  private TW_Context ctx;

  /**
   * @description Sets the context for the trigger weaver action.
   * @param ctx The context to set.
   */
  public void setContext(TW_Context ctx) {
    if (this.ctx != null) {
      throw new InvalidActionException('Context can only be set once');
    }
    this.ctx = ctx;
  }

  /**
   * @description Returns the old records for the current trigger context.
   * @return Old records.
   */
  public List<SObject> oldRecords() {
    return ctx.getOld();
  }

  /**
   * @description Returns the new records for the current trigger context.
   * @return New records.
   */
  public List<SObject> newRecords() {
    return ctx.getNew();
  }

  /**
   * @description Returns true if the field has changed for the current record. Returns false if
   * not update context.
   * @param field Field to check.
   * @return True if the field has changed.
   */
  @TestVisible
  protected Boolean isChanged(Schema.SObjectField field) {
    return ctx.isChanged(field);
  }

  /**
   * @description Returns true if any of the provided fields have changed for the current record.
   * Returns false if not update context.
   * @param fields Fields to check.
   * @return True if any of the fields have changed.
   */
  @TestVisible
  protected Boolean anyChanged(Schema.SObjectField[] fields) {
    return ctx.anyChanged(fields);
  }

  /**
   * @description Returns true if all of the provided fields have changed for the current record.
   * Returns false if not update context.
   * @param fields Fields to check.
   * @return True if all of the fields have changed.
   */
  @TestVisible
  protected Boolean allChanged(Schema.SObjectField[] fields) {
    return ctx.allChanged(fields);
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
   */
  @TestVisible
  public virtual void afterInsert(SObject newRecord) {
  }
  /**
   * @description Primary logic that executes for each record before update.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject newRecord The new record from trigger.
   */
  @TestVisible
  public virtual void beforeUpdate(SObject oldRecord, SObject newRecord) {
  }
  /**
   * @description Primary logic that executes for each record after update.
   * @param SObject oldRecord The old record from trigger.
   * @param SObject newRecord The new record from trigger.
   */
  @TestVisible
  public virtual void afterUpdate(SObject oldRecord, SObject newRecord) {
  }
  /**
   * @description Primary logic that executes for each record before delete.
   * @param SObject oldRecord The old record from trigger.
   */
  @TestVisible
  public virtual void beforeDelete(SObject oldRecord) {
  }
  /**
   * @description Primary logic that executes for each record after delete.
   * @param SObject oldRecord The old record from trigger.
   */
  @TestVisible
  public virtual void afterDelete(SObject oldRecord) {
  }
  /**
   * @description Primary logic that executes for each record after undelete.
   * @param SObject newRecord The new record from trigger.
   */
  @TestVisible
  public virtual void afterUndelete(SObject newRecord) {
  }

  public class InvalidActionException extends Exception {
  }
}
