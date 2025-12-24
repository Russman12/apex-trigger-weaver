/**
 * @description Contains functionality relating to the global trigger execution.
 * @group Framework
 */
public virtual class TW_Handler {
  @TestVisible
  private static final Set<Type> BYPASSES = new Set<Type>();
  @TestVisible
  private static TW_ActionRegistry actionRegistry = new TW_ActionRegistry();

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

  @TestVisible
  private TW_Context ctx;
  @TestVisible
  private Schema.SObjectType sObjType;
  @TestVisible
  private TW_ExecutorFactory executorFactory;

  public TW_Handler(Schema.SObjectType sObjType) {
    //throw execption if not in trigger context
    if (!Trigger.isExecuting) {
      throw new InvalidContextException('Unable to create TW_Handler outside of a trigger context');
    }

    this.sObjType = sObjType;
    this.ctx = new TW_Context(newDMLQueue(), newQuery(sObjType));
    this.executorFactory = new TW_ExecutorFactory(this.ctx);
  }

  @TestVisible
  private TW_Handler() {
  }

  /**
   * @description Creates a new TW_Queryable instance. This method can be overridden to provide a custom query implementation.
   * @return Default TW_Query instance.
   */
  @TestVisible
  protected virtual TW_Query newQuery(SObjectType sObjType) {
    return new TW_DefaultQuery(sObjType);
  }

  /**
   * @description Creates new TW_DMLQueueable instance. This method can be overridden to provide a custom queueable implementation.
   * @return Default TW_DMLQueue instance.
   */
  @TestVisible
  protected virtual TW_DMLQueue newDMLQueue() {
    return new TW_DefaultDMLQueue();
  }

  private List<TW_Action> registeredActions() {
    List<TW_Action> activeActions = new List<TW_Action>();
    List<System.Type> actionTypes = actionRegistry.activeActions(sObjType);
    if (actionTypes == null || actionTypes.isEmpty()) {
      return activeActions;
    }

    for (System.Type t : actionTypes) {
      if (BYPASSES.contains(t)) {
        continue;
      }
      TW_Action action = (TW_Action) t.newInstance();
      action.setContext(ctx);
      activeActions.add(action);
    }

    return activeActions;
  }

  /**
   * @description Executes all registered trigger actions.
   */
  public void execute() {
    List<TW_Action> registeredActions = registeredActions();
    if (registeredActions.isEmpty()) {
      return;
    }

    TW_Executor e = executorFactory.make();

    Map<TW_Action, List<SObject>> actionRecords = new Map<TW_Action, List<SObject>>();
    for (TW_Action a : registeredActions) {
      List<SObject> filteredRecs = e.filteredRecords(a);
      if (!filteredRecs.isEmpty()) {
        actionRecords.put(a, filteredRecs);
        e.setup(a);
      }
    }

    e.runQuery();

    for (TW_Action a : registeredActions) {
      if (actionRecords.containsKey(a)) {
        for (SObject r : actionRecords.get(a)) {
          ctx.currentRecord = r;
          e.execute(a, r);
        }
      }
    }

    ctx.getDMLQueue().flush();
  }

  /**
   * @description Represents an exception relating to the context.
   */
  public class InvalidContextException extends Exception {
  }
}
