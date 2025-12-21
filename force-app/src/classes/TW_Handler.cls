/**
 * @description Contains functionality relating to the global trigger execution.
 * @group Framework
 */
public virtual class TW_Handler {
  private static final Set<System.TriggerOperation> QUERY_CONTEXTS = new Set<System.TriggerOperation>{
    System.TriggerOperation.AFTER_INSERT,
    System.TriggerOperation.BEFORE_UPDATE,
    System.TriggerOperation.AFTER_UPDATE,
    System.TriggerOperation.BEFORE_DELETE,
    System.TriggerOperation.AFTER_DELETE,
    System.TriggerOperation.AFTER_UNDELETE
  };

  private static final Set<Type> BYPASSES = new Set<Type>();
  private static Map<Schema.SObjectType, List<TW_Action__mdt>> activeTWSBySObj;

  private static List<TW_Action__mdt> getActiveTWSForSObj(Schema.SObjectType sObjType) {
    if (activeTWSBySObj == null) {
      activeTWSBySObj = new Map<Schema.SObjectType, List<TW_Action__mdt>>();
      for (TW_Action__mdt tw : TW_Action__mdt.getAll().values()) {
        if (tw.Active__c) {
          SObjectType twSObjType = ((SObject) Type.forName(tw.SObject_Name__c).newInstance()).getSObjectType();
          if (!activeTWSBySObj.containsKey(twSObjType)) {
            activeTWSBySObj.put(twSObjType, new List<TW_Action__mdt>());
          }
          activeTWSBySObj.get(twSObjType).add(tw);
        }
      }
    }

    return activeTWSBySObj.get(sObjType);
  }

  /**
   * @description Bypasses given trigger weaver action to prevent multiple executions.
   * @param action TW_Action to bypass.
   */
  public static void addBypass(System.Type action) {
    BYPASSES.add(action);
  }

  /**
   * @description Removes given trigger weaver action from bypasses allowing it to be executed multiple times.
   * @param action TW_Action to bypass.
   */
  public static void removeBypass(System.Type action) {
    BYPASSES.remove(action);
  }

  /**
   * @description Removes all bypasses allowing all trigger weaver actions to be executed multiple times.
   */
  public static void clearBypasses() {
    BYPASSES.clear();
  }

  /**
   * @description Creates a new TW_Handler instance.
   * @param sObjType The SObject type to handle.
   * @return TW_Handler instance.
   */
  public static TW_Handler make(Schema.SObjectType sObjType) {
    return new TW_Handler(sObjType);
  }

  private List<TW_Action> actions = new List<TW_Action>();
  private final TW_Queryable query;
  private final TW_DMLQueueable dmlQueue;
  private final TW_ActionExecutor executor;
  private final SObjectType sObjType;
  private final TW_Context ctx;
  private final Map<String, Object> queryBinds;
  private final Map<Id, SObject> queriedRecordsMap;
  private final TW_QuerySelectionable selection;

  private TW_Handler(Schema.SObjectType sObjType) {
    this.sObjType = sObjType;

    this.query = this.newQueryable();
    query.fromSObject(sObjType);

    this.selection = query.getSelection();
    this.dmlQueue = this.newQueueable();
    this.executor = new TW_ActionExecutor();
    this.queriedRecordsMap = new Map<Id, SObject>();

    this.ctx = new TW_Context(queriedRecordsMap, this.newQueueable());
    this.queryBinds = new Map<String, Object>();
    this.autoRegister();
  }

  /**
   * @description Creates a new TW_Queryable instance. This method can be overridden to provide a custom query implementation.
   * @return Default TW_Query instance.
   */
  protected virtual TW_Queryable newQueryable() {
    return new TW_Query();
  }

  /**
   * @description Creates new TW_DMLQueueable instance. This method can be overridden to provide a custom queueable implementation.
   * @return Default TW_DMLQueue instance.
   */
  protected virtual TW_DMLQueueable newQueueable() {
    return new TW_DMLQueue();
  }

  private TW_Handler autoRegister() {
    List<TW_Action__mdt> tws = getActiveTWSForSObj(this.sObjType);
    if (tws == null) {
      return this;
    }

    for (TW_Action__mdt tw : tws) {
      System.Type t = System.Type.forName(tw.DeveloperName);
      TW_Action action = (TW_Action) t.newInstance();
      action.setType(t);
      this.actions.add(action);
    }

    return this;
  }

  /**
   * @description Executes all registered trigger weaver actions.
   */
  public void execute() {
    for (TW_Action action : this.actions) {
      if (BYPASSES.contains(action.getType())) {
        continue;
      }

      // Action orchestration handled by executor; context is set within executor
      this.executor.executeSetup(action, this.ctx, this.selection);
    }

    if (this.selection.isSet() && this.ctx.isQueryContext() && this.ctx.filteredRecords().size() > 0) {
      List<SObject> queryResults = this.query.run(this.ctx.filteredRecords());
      this.queriedRecordsMap.putAll(new Map<Id, SObject>(queryResults));
    }

    for (TW_Action action : actions) {
      if (BYPASSES.contains(action.getType())) {
        continue;
      }
      this.executor.execute(action, this.ctx);
    }

    this.ctx.getDMLQueue().flush();
  }
}
