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
  @TestVisible
  private final List<TW_Extension> extensions = new List<TW_Extension>();

  public TW_Handler(Schema.SObjectType sObjType) {
    //throw execption if not in trigger context
    if (!Trigger.isExecuting) {
      throw new InvalidContextException('Unable to create TW_Handler outside of a trigger context');
    }

    this.sObjType = sObjType;
    this.ctx = new TW_Context();
    this.executorFactory = new TW_ExecutorFactory(this.ctx);
    this.extensions.addAll(newExtensions());
  }

  @TestVisible
  private TW_Handler() {
  }

  /**
   * @description Registers an extension whose lifecycle hooks are invoked during execution. Extensions
   * are invoked in the order they are registered.
   * @param extension The extension to register.
   * @return This handler, to allow chaining.
   * @example
   * ```
   * new TW_Handler(Account.getSObjectType()).addExtension(new MyExtension()).execute();
   * ```
   */
  public TW_Handler addExtension(TW_Extension extension) {
    this.extensions.add(extension);
    return this;
  }

  /**
   * @description Creates the extensions registered for every execution of this handler. This method
   * can be overridden to provide default extensions. Extensions added with addExtension run after these.
   * @return Empty list of extensions by default.
   */
  @TestVisible
  protected virtual List<TW_Extension> newExtensions() {
    return new List<TW_Extension>();
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
   * @description Executes all registered trigger actions, invoking extension hooks at each lifecycle event.
   */
  public void execute() {
    List<TW_Action> registeredActions = registeredActions();
    if (registeredActions.isEmpty()) {
      System.debug(LoggingLevel.FINE, 'No registered TW Actions, exiting');
      return;
    }

    TW_Executor e = executorFactory.make();

    try {
      for (TW_Extension x : extensions) {
        x.onStart(ctx, registeredActions);
      }

      Map<TW_Action, List<SObject>> actionRecords = new Map<TW_Action, List<SObject>>();
      for (TW_Action a : registeredActions) {
        System.debug(LoggingLevel.FINE, 'Filtering records for ' + a);
        List<SObject> filteredRecs = e.filteredRecords(a);
        if (!filteredRecs.isEmpty()) {
          actionRecords.put(a, filteredRecs);
          for (TW_Extension x : extensions) {
            x.onActionSetup(ctx, a, filteredRecs);
          }
        }
      }

      for (TW_Extension x : extensions) {
        x.beforeExecute(ctx);
      }

      for (TW_Action a : registeredActions) {
        if (actionRecords.containsKey(a)) {
          for (SObject r : actionRecords.get(a)) {
            ctx.currentRecord = r;
            e.execute(a, r);
          }
        }
      }

      for (TW_Extension x : extensions) {
        x.afterExecute(ctx);
      }
    } catch (Exception ex) {
      for (TW_Extension x : extensions) {
        x.onError(ctx, ex);
      }
      throw ex;
    } finally {
      for (TW_Extension x : extensions) {
        x.onFinish(ctx);
      }
    }
  }

  /**
   * @description Represents an exception relating to the context.
   */
  public class InvalidContextException extends Exception {
  }
}
