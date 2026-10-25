/**
 * @description Holds the trigger state for a single TW_Handler execution and is shared by every
 * action and plugin in that execution. Provides access to the trigger records, the record
 * currently being processed, and the registered plugins.
 * @internal
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
  private Map<System.Type, TW_Plugin> plugins = new Map<System.Type, TW_Plugin>();

  /**
   * @description The record currently being filtered or executed. Set by the framework before each
   * filter and handler method call.
   */
  public SObject currentRecord;

  /**
   * @description Creates a new TW_Context instance from the running trigger. TW_Handler verifies
   * that a trigger is executing before creating the context.
   * @example
   * ```
   * TW_Context ctx = new TW_Context();
   * ```
   */
  public TW_Context() {
  }

  /**
   * @description Sets the plugins registered for the running execution, keyed by the type they
   * were registered under.
   * @param plugins The registered plugins.
   */
  public void setPlugins(Map<System.Type, TW_Plugin> plugins) {
    this.plugins = plugins;
  }

  /**
   * @description Returns the plugin registered under the given type. Throws MissingPluginException
   * if no plugin is registered under the type.
   * @param pluginType The type the plugin was registered under.
   * @return The registered plugin.
   * @example
   * ```
   * MyPlugin plugin = (MyPlugin) ctx.getPlugin(MyPlugin.class);
   * ```
   */
  public TW_Plugin getPlugin(System.Type pluginType) {
    TW_Plugin plugin = plugins.get(pluginType);
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
   * TW_Context ctx = new TW_Context();
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
   * TW_Context ctx = new TW_Context();
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
   * TW_Context ctx = new TW_Context();
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
   * TW_Context ctx = new TW_Context();
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
   * TW_Context ctx = new TW_Context();
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
   * @description Represents an exception thrown when a required plugin is not registered.
   */
  public class MissingPluginException extends Exception {
  }
}
