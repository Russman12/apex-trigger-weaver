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
  private static Map<Schema.SObjectType, List<TW_Action__mdt>> activeActionsBySObj;

  private static List<TW_Action__mdt> getActiveTWSForSObj(Schema.SObjectType sObjType) {
    if (activeActionsBySObj == null) {
      activeActionsBySObj = new Map<Schema.SObjectType, List<TW_Action__mdt>>();
      for (TW_Action__mdt tw : TW_Action__mdt.getAll().values()) {
        if (tw.Active__c) {
          SObjectType twSObjType = ((SObject) Type.forName(tw.SObject_Name__c).newInstance()).getSObjectType();
          if (!activeActionsBySObj.containsKey(twSObjType)) {
            activeActionsBySObj.put(twSObjType, new List<TW_Action__mdt>());
          }
          activeActionsBySObj.get(twSObjType).add(tw);
        }
      }
    }

    return activeActionsBySObj.get(sObjType);
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

  private final TW_Context ctx;
  private final Schema.SObjectType sObjType;

  private TW_Handler(Schema.SObjectType sObjType) {
    this.sObjType = sObjType;
    this.ctx = new TW_Context(newQueueable(), newQueryable(sObjType));
  }

  /**
   * @description Creates a new TW_Queryable instance. This method can be overridden to provide a custom query implementation.
   * @return Default TW_Query instance.
   */
  protected virtual TW_Query newQueryable(SObjectType sObjType) {
    return new TW_DefaultQuery(sObjType);
  }

  /**
   * @description Creates new TW_DMLQueueable instance. This method can be overridden to provide a custom queueable implementation.
   * @return Default TW_DMLQueue instance.
   */
  protected virtual TW_DMLQueue newQueueable() {
    return new TW_DefaultDMLQueue();
  }

  private Map<System.Type, TW_Action> registeredActions() {
    List<TW_Action__mdt> tws = getActiveTWSForSObj(sObjType);
    if (tws == null) {
      return null;
    }

    Map<System.Type, TW_Action> activeActions = new Map<System.Type, TW_Action>();
    for (TW_Action__mdt tw : tws) {
      System.Type t = System.Type.forName(tw.DeveloperName);
      if (BYPASSES.contains(t)) {
        continue;
      }
      TW_Action action = (TW_Action) t.newInstance();
      action.setContext(ctx);
      activeActions.put(t, action);
    }

    return activeActions;
  }

  /**
   * @description Executes all registered trigger weaver actions.
   */
  public void execute() {
    TW_Executor e = getExecutor(ctx.getOperation());
    List<TW_Action> registeredActions = registeredActions().values();

    Map<TW_Action, List<SObject>> actionRecords = new Map<TW_Action, List<SObject>>();
    for (TW_Action a : registeredActions) {
      List<SObject> filteredRecs = e.filteredRecords(a);
      if (!filteredRecs.isEmpty()) {
        actionRecords.put(a, filteredRecs);
        e.setup(a);
      }
    }

    for (TW_Action a : registeredActions) {
      if (actionRecords.containsKey(a)) {
        for (SObject r : actionRecords.get(a)) {
          ctx.currentRecord = r;
          e.execute(a, r);
        }
      }
    }

    this.ctx.getDMLQueue().flush();
  }

  private TW_Executor getExecutor(System.TriggerOperation op) {
    switch on op {
      when BEFORE_INSERT {
        return new TW_BeforeInsertExecutor(this.ctx);
      }
      when AFTER_INSERT {
        return new TW_AfterInsertExecutor(this.ctx);
      }
      when BEFORE_UPDATE {
        return new TW_BeforeUpdateExecutor(this.ctx);
      }
      when AFTER_UPDATE {
        return new TW_AfterUpdateExecutor(this.ctx);
      }
      when BEFORE_DELETE {
        return new TW_BeforeDeleteExecutor(this.ctx);
      }
      when AFTER_DELETE {
        return new TW_AfterDeleteExecutor(this.ctx);
      }
      when AFTER_UNDELETE {
        return new TW_AfterUndeleteExecutor(this.ctx);
      }
    }
    return null;
  }
}
