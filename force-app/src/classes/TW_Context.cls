/**
 * @description Contains functionality relating to the global trigger execution. Data and functions
 * contained within this class should be common to all trigger weaver actions part of the running
 * execution context.
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
   * @description The current record which is being executed.
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
   * @description Returns the plugin registered under the given type. Throws an exception if no
   * plugin is registered under the type.
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
   * @descriptions Returns new trigger records.
   * @return New trigger records.
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
   * @description Returns new trigger records as a Map<Id, SObject>.
   * @return New trigger records map.
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
   * @description Returns old trigger records.
   * @return Old trigger records.
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
   * @description Returns old trigger record for the given record. The
   * given record must have an Id set.
   * @return The old record.
   */
  public SObject getOld(SObject r) {
    return oldRecsMap.get(r.Id);
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
    return oldRecsMap;
  }

  /**
   * @description Returns either new trigger records if set, else returns old records.
   * @return The list of trigger records
   */
  public List<SObject> getRecords() {
    if (newRecs != null && !newRecs.isEmpty()) {
      return newRecs;
    }
    return oldRecs;
  }

  /**
   * @Returns True if the field has changed for the current record. Throws exception if not update context.
   * @param field Field to check.
   */
  public Boolean isChanged(Schema.SObjectField field) {
    if (!isUpdate) {
      throw new InvalidContextException('isChanged can only be called in an update context');
    }
    return getOld(currentRecord).get(field) != currentRecord.get(field);
  }

  /**
   * @Returns True if any of the given fields have changed for the current record. Throws exception if not update context.
   * @param fields Fields to check.
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
   * @Returns True if all of the given fields have changed for the current record. Throws exception if not update context.
   * @param fields Fields to check.
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
   * @description Represents an exception relating to the context.
   */
  public class InvalidContextException extends Exception {
  }

  /**
   * @description Represents an exception thrown when a required plugin is not registered.
   */
  public class MissingPluginException extends Exception {
  }
}
