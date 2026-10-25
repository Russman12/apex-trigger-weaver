/**
 * @description Holds the trigger state for a single TW_Handler execution.
 * @usage One context is created for each trigger execution and shared by every action and plugin in
 * that execution. It provides access to the trigger records, the record currently being processed,
 * and the plugins listed in the plugin registry.
 *
 * Plugins receive the context as the `ctx` parameter of every lifecycle hook. Actions use it
 * indirectly through the TW_Action methods, such as `newRecords` and `isChanged`. The framework
 * creates the context, so plugins and actions never construct one.
 * @group Framework
 * @example
 * ```
 * public void onError(TW_Context ctx, Exception e) {
 *   System.debug(LoggingLevel.ERROR, ctx.getOperation() + ' failed for ' + ctx.getRecords().size() + ' record(s)');
 * }
 * ```
 */
public with sharing class TW_Context {
  @TestVisible
  private TriggerOperation triggerOp = Trigger.operationType;
  @TestVisible
  private List<SObject> newRecs = Trigger.new;
  @TestVisible
  private Map<Id, SObject> newRecsMap = Trigger.newMap;
  @TestVisible
  private List<SObject> oldRecs = Trigger.old;
  @TestVisible
  private Map<Id, SObject> oldRecsMap = Trigger.oldMap;
  @TestVisible
  private Boolean isUpdate = Trigger.isUpdate;
  @TestVisible
  private Map<System.Type, TW_Plugin.Plugin> plugins = new Map<System.Type, TW_Plugin.Plugin>();

  /**
   * @description The record currently being filtered or executed. Set by the framework before each
   * filter and handler method call.
   */
  public SObject currentRecord;

  /**
   * @description Creates a new TW_Context instance from the running trigger. For framework use;
   * TW_Handler creates the context for each execution.
   */
  public TW_Context() {
  }

  /**
   * @description Creates a new TW_Context instance from the running trigger with the plugins for the
   * execution, keyed by their type. For framework use; TW_Handler creates the context for each
   * execution.
   * @param plugins The plugins for the execution.
   */
  public TW_Context(Map<System.Type, TW_Plugin.Plugin> plugins) {
    this.plugins = plugins;
  }

  /**
   * @description Returns this execution's instance of the given plugin type. Throws
   * MissingPluginException if the type is not listed in the plugin registry.
   * @param pluginType The plugin type, as listed in the plugin registry.
   * @return The plugin instance.
   * @example
   * ```
   * MyPlugin plugin = (MyPlugin) ctx.getPlugin(MyPlugin.class);
   * ```
   */
  public TW_Plugin.Plugin getPlugin(System.Type pluginType) {
    TW_Plugin.Plugin plugin = plugins.get(pluginType);
    if (plugin == null) {
      throw new MissingPluginException('No plugin registered for ' + pluginType);
    }
    return plugin;
  }

  /**
   * @description Returns the current trigger operation.
   * @return The current trigger operation.
   * @example
   * ```
   * System.TriggerOperation operation = ctx.getOperation();
   * ```
   */
  public System.TriggerOperation getOperation() {
    return triggerOp;
  }

  /**
   * @description Returns new trigger records (Trigger.new).
   * @return New trigger records, or null in delete context.
   * @example
   * ```
   * List<SObject> newRecords = ctx.getNew();
   * ```
   */
  public List<SObject> getNew() {
    return newRecs;
  }

  /**
   * @description Returns new trigger records as a Map<Id, SObject> (Trigger.newMap).
   * @return New trigger records map, or null in before insert and delete contexts.
   * @example
   * ```
   * Map<Id, SObject> newRecordsMap = ctx.getNewMap();
   * ```
   */
  public Map<Id, SObject> getNewMap() {
    return newRecsMap;
  }

  /**
   * @description Returns old trigger records (Trigger.old).
   * @return Old trigger records, or null in insert and undelete contexts.
   * @example
   * ```
   * List<SObject> oldRecords = ctx.getOld();
   * ```
   */
  public List<SObject> getOld() {
    return oldRecs;
  }

  /**
   * @description Returns the old version of the given record. The given record must have an Id
   * set and old records must be available (update or delete context).
   * @param r The record to get the old version of.
   * @return The old record, or null if no old record exists for the Id.
   */
  public SObject getOld(SObject r) {
    return oldRecsMap.get(r.Id);
  }

  /**
   * @description Returns old trigger records as a Map<Id, SObject> (Trigger.oldMap).
   * @return Old trigger records map, or null in insert and undelete contexts.
   * @example
   * ```
   * Map<Id, SObject> oldRecordsMap = ctx.getOldMap();
   * ```
   */
  public Map<Id, SObject> getOldMap() {
    return oldRecsMap;
  }

  /**
   * @description Returns the new trigger records if any exist, otherwise the old trigger records.
   * @return The list of trigger records.
   */
  public List<SObject> getRecords() {
    if (newRecs != null && !newRecs.isEmpty()) {
      return newRecs;
    }
    return oldRecs;
  }

  /**
   * @description Returns true if the field value differs between the old and new versions of
   * currentRecord. Throws InvalidContextException if not in update context.
   * @param field Field to check.
   * @return True if the field has changed.
   */
  public Boolean isChanged(Schema.SObjectField field) {
    if (!isUpdate) {
      throw new InvalidContextException('isChanged can only be called in an update context');
    }
    return getOld(currentRecord).get(field) != currentRecord.get(field);
  }

  /**
   * @description Returns true if any of the given field values differ between the old and new
   * versions of currentRecord. Throws InvalidContextException if not in update context.
   * @param fields Fields to check.
   * @return True if any of the fields have changed.
   */
  public Boolean anyChanged(List<Schema.SObjectField> fields) {
    if (!isUpdate) {
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
   * @description Returns true if all of the given field values differ between the old and new
   * versions of currentRecord. Throws InvalidContextException if not in update context.
   * @param fields Fields to check.
   * @return True if all of the fields have changed.
   */
  public Boolean allChanged(List<Schema.SObjectField> fields) {
    if (!isUpdate) {
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
   * @description Thrown when a context method is called in a trigger operation that does not support it.
   */
  public class InvalidContextException extends Exception {
  }

  /**
   * @description Represents an exception thrown when a requested plugin is not listed in the plugin registry.
   */
  public class MissingPluginException extends Exception {
  }
}
