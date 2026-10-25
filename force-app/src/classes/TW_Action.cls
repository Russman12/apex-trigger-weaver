/**
 * @description Base class for a unit of trigger logic. Extend this class and override the filter
 * and handler methods for the trigger operations the action handles; methods that are not
 * overridden do nothing. An action runs when an active TW_Action__mdt record whose DeveloperName
 * matches the class name is configured for the SObject.
 * @group Framework
 */
public abstract class TW_Action {
  @TestVisible
  private TW_Context ctx;

  /**
   * @description Sets the trigger context used by this action. Called by TW_Handler when the
   * action is created. Throws InvalidActionException if the context has already been set.
   * @param ctx The context to set.
   */
  public void setContext(TW_Context ctx) {
    if (this.ctx != null) {
      throw new InvalidActionException('Context can only be set once');
    }
    this.ctx = ctx;
  }

  /**
   * @description Returns the old versions of all records in the trigger (Trigger.old).
   * @return Old records, or null in insert context.
   */
  public List<SObject> oldRecords() {
    return ctx.getOld();
  }

  /**
   * @description Returns the new versions of all records in the trigger (Trigger.new).
   * @return New records, or null in delete context.
   */
  public List<SObject> newRecords() {
    return ctx.getNew();
  }

  /**
   * @description Returns this execution's instance of the given plugin type, allowing the action to
   * use the functionality the plugin provides. Throws TW_Context.MissingPluginException if the type
   * is not listed in the plugin registry.
   * @param pluginType The plugin type, as listed in the plugin registry.
   * @return The plugin instance.
   * @example
   * ```
   * MyPlugin plugin = (MyPlugin) getPlugin(MyPlugin.class);
   * ```
   */
  @TestVisible
  protected TW_Plugin.Plugin getPlugin(System.Type pluginType) {
    return ctx.getPlugin(pluginType);
  }

  /**
   * @description Returns true if the field value differs between the old and new versions of the
   * record currently being filtered or executed. Throws TW_Context.InvalidContextException if not
   * in update context.
   * @param field Field to check.
   * @return True if the field has changed.
   */
  @TestVisible
  protected Boolean isChanged(Schema.SObjectField field) {
    return ctx.isChanged(field);
  }

  /**
   * @description Returns true if any of the given field values differ between the old and new
   * versions of the record currently being filtered or executed. Throws
   * TW_Context.InvalidContextException if not in update context.
   * @param fields Fields to check.
   * @return True if any of the fields have changed.
   */
  @TestVisible
  protected Boolean anyChanged(Schema.SObjectField[] fields) {
    return ctx.anyChanged(fields);
  }

  /**
   * @description Returns true if all of the given field values differ between the old and new
   * versions of the record currently being filtered or executed. Throws
   * TW_Context.InvalidContextException if not in update context.
   * @param fields Fields to check.
   * @return True if all of the fields have changed.
   */
  @TestVisible
  protected Boolean allChanged(Schema.SObjectField[] fields) {
    return ctx.allChanged(fields);
  }

  /**
   * @description Determines whether a record is processed by this action in before insert context.
   * Called for every trigger record before any action's handler method runs. Override to limit
   * which records are processed; returns true by default.
   * @param newRecord The new version of the record from the trigger.
   * @return True if the record should be processed.
   */
  @TestVisible
  public virtual Boolean beforeInsertFilter(SObject newRecord) {
    return true;
  }
  /**
   * @description Determines whether a record is processed by this action in after insert context.
   * Called for every trigger record before any action's handler method runs. Override to limit
   * which records are processed; returns true by default.
   * @param newRecord The new version of the record from the trigger.
   * @return True if the record should be processed.
   */
  @TestVisible
  public virtual Boolean afterInsertFilter(SObject newRecord) {
    return true;
  }
  /**
   * @description Determines whether a record is processed by this action in before update context.
   * Called for every trigger record before any action's handler method runs. Override to limit
   * which records are processed; returns true by default.
   * @param oldRecord The old version of the record from the trigger.
   * @param newRecord The new version of the record from the trigger.
   * @return True if the record should be processed.
   */
  @TestVisible
  public virtual Boolean beforeUpdateFilter(SObject oldRecord, SObject newRecord) {
    return true;
  }
  /**
   * @description Determines whether a record is processed by this action in after update context.
   * Called for every trigger record before any action's handler method runs. Override to limit
   * which records are processed; returns true by default.
   * @param oldRecord The old version of the record from the trigger.
   * @param newRecord The new version of the record from the trigger.
   * @return True if the record should be processed.
   */
  @TestVisible
  public virtual Boolean afterUpdateFilter(SObject oldRecord, SObject newRecord) {
    return true;
  }
  /**
   * @description Determines whether a record is processed by this action in before delete context.
   * Called for every trigger record before any action's handler method runs. Override to limit
   * which records are processed; returns true by default.
   * @param oldRecord The old version of the record from the trigger.
   * @return True if the record should be processed.
   */
  @TestVisible
  public virtual Boolean beforeDeleteFilter(SObject oldRecord) {
    return true;
  }
  /**
   * @description Determines whether a record is processed by this action in after delete context.
   * Called for every trigger record before any action's handler method runs. Override to limit
   * which records are processed; returns true by default.
   * @param oldRecord The old version of the record from the trigger.
   * @return True if the record should be processed.
   */
  @TestVisible
  public virtual Boolean afterDeleteFilter(SObject oldRecord) {
    return true;
  }
  /**
   * @description Determines whether a record is processed by this action in after undelete context.
   * Called for every trigger record before any action's handler method runs. Override to limit
   * which records are processed; returns true by default.
   * @param newRecord The new version of the record from the trigger.
   * @return True if the record should be processed.
   */
  @TestVisible
  public virtual Boolean afterUndeleteFilter(SObject newRecord) {
    return true;
  }

  /**
   * @description Runs the action's logic in before insert context. Called once for each record that
   * passed the filter. Override to implement the action; does nothing by default.
   * @param newRecord The new version of the record from the trigger.
   */
  @TestVisible
  public virtual void beforeInsert(SObject newRecord) {
  }
  /**
   * @description Runs the action's logic in after insert context. Called once for each record that
   * passed the filter. Override to implement the action; does nothing by default.
   * @param newRecord The new version of the record from the trigger.
   */
  @TestVisible
  public virtual void afterInsert(SObject newRecord) {
  }
  /**
   * @description Runs the action's logic in before update context. Called once for each record that
   * passed the filter. Override to implement the action; does nothing by default.
   * @param oldRecord The old version of the record from the trigger.
   * @param newRecord The new version of the record from the trigger.
   */
  @TestVisible
  public virtual void beforeUpdate(SObject oldRecord, SObject newRecord) {
  }
  /**
   * @description Runs the action's logic in after update context. Called once for each record that
   * passed the filter. Override to implement the action; does nothing by default.
   * @param oldRecord The old version of the record from the trigger.
   * @param newRecord The new version of the record from the trigger.
   */
  @TestVisible
  public virtual void afterUpdate(SObject oldRecord, SObject newRecord) {
  }
  /**
   * @description Runs the action's logic in before delete context. Called once for each record that
   * passed the filter. Override to implement the action; does nothing by default.
   * @param oldRecord The old version of the record from the trigger.
   */
  @TestVisible
  public virtual void beforeDelete(SObject oldRecord) {
  }
  /**
   * @description Runs the action's logic in after delete context. Called once for each record that
   * passed the filter. Override to implement the action; does nothing by default.
   * @param oldRecord The old version of the record from the trigger.
   */
  @TestVisible
  public virtual void afterDelete(SObject oldRecord) {
  }
  /**
   * @description Runs the action's logic in after undelete context. Called once for each record that
   * passed the filter. Override to implement the action; does nothing by default.
   * @param newRecord The new version of the record from the trigger.
   */
  @TestVisible
  public virtual void afterUndelete(SObject newRecord) {
  }

  /**
   * @description Thrown when an action is used incorrectly, such as setting its context more than once.
   */
  public class InvalidActionException extends Exception {
  }
}
