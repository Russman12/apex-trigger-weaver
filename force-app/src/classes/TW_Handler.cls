/**
 * @description Entry point for trigger weaver.
 * @usage Create a handler in an SObject's trigger and call execute to run the active actions
 * configured for that SObject, which the handler reads from the running trigger, along with the org's plugins. Plugins are listed by the org's plugin
 * registry, a class named `TW_PluginRegistry` that implements `TW_Plugin.Registry`, and run for
 * every SObject.
 * @example
 * ```
 * trigger AccountTrigger on Account(before insert, after insert, before update, after update) {
 *   new TW_Handler().execute();
 * }
 * ```
 * @group Framework
 */
public class TW_Handler {
  @TestVisible
  private static final Set<Type> BYPASSES = new Set<Type>();
  @TestVisible
  private static TW_ActionRegistry actionRegistry = new TW_ActionRegistry();
  @TestVisible
  private static String pluginRegistryName = 'TW_PluginRegistry';
  @TestVisible
  private static TW_Plugin.Registry pluginRegistry;
  @TestVisible
  private static Boolean pluginRegistryLoaded = false;

  /**
   * @description Prevents the given action from running in any handler execution for the rest of
   * the transaction, or until the bypass is removed.
   * @param action The TW_Action type to bypass.
   */
  public static void addBypass(System.Type action) {
    BYPASSES.add(action);
  }

  /**
   * @description Removes the bypass for the given action so it runs in subsequent handler executions.
   * @param action The TW_Action type to stop bypassing.
   */
  public static void removeBypass(System.Type action) {
    BYPASSES.remove(action);
  }

  /**
   * @description Returns whether the given action is bypassed.
   * @param action The TW_Action type to check.
   * @return True if the action is bypassed.
   */
  public static Boolean isBypassed(System.Type action) {
    return BYPASSES.contains(action);
  }

  /**
   * @description Removes all bypasses so every active action runs in subsequent handler executions.
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
  private final List<TW_Plugin.Plugin> plugins = new List<TW_Plugin.Plugin>();
  @TestVisible
  private final Map<System.Type, TW_Plugin.Plugin> pluginsByType = new Map<System.Type, TW_Plugin.Plugin>();

  /**
   * @description Creates a handler for the running trigger's SObject type and creates a new instance
   * of each plugin listed by the org's plugin registry, shared by every action in this execution.
   * Throws InvalidContextException if called outside a trigger, and InvalidPluginException if the
   * registry does not implement TW_Plugin.Registry or lists an invalid or duplicate plugin type.
   */
  public TW_Handler() {
    //throw execption if not in trigger context
    if (!Trigger.isExecuting) {
      throw new InvalidContextException('Unable to create TW_Handler outside of a trigger context');
    }

    this.sObjType = sObjectTypeOf(Trigger.new, Trigger.old);
    registerPlugins();
    this.ctx = new TW_Context(sObjType, pluginsByType);
    this.executorFactory = new TW_ExecutorFactory(this.ctx);
  }

  // For tests, which run outside a trigger, so they supply the SObject type
  @TestVisible
  private TW_Handler(Schema.SObjectType sObjType) {
    this.sObjType = sObjType;
  }

  // Every trigger has at least one record: new records, or only old ones when deleting
  @TestVisible
  private static Schema.SObjectType sObjectTypeOf(List<SObject> newRecs, List<SObject> oldRecs) {
    return (newRecs != null ? newRecs : oldRecs)[0].getSObjectType();
  }

  @TestVisible
  private void registerPlugins() {
    TW_Plugin.Registry registry = loadPluginRegistry();
    if (registry == null) {
      return;
    }

    List<System.Type> pluginTypes = registry.plugins();
    if (pluginTypes == null) {
      return;
    }

    for (System.Type t : pluginTypes) {
      if (pluginsByType.containsKey(t)) {
        throw new InvalidPluginException('Plugin already registered for ' + t);
      }
      Object plugin = t.newInstance();
      if (!(plugin instanceof TW_Plugin.Plugin)) {
        throw new InvalidPluginException(t + ' does not implement TW_Plugin.Plugin');
      }
      plugins.add((TW_Plugin.Plugin) plugin);
      pluginsByType.put(t, (TW_Plugin.Plugin) plugin);
    }
  }

  @TestVisible
  private static TW_Plugin.Registry loadPluginRegistry() {
    if (pluginRegistryLoaded) {
      return pluginRegistry;
    }

    System.Type registryType = System.Type.forName(pluginRegistryName);
    if (registryType != null) {
      Object registry = registryType.newInstance();
      if (!(registry instanceof TW_Plugin.Registry)) {
        throw new InvalidPluginException(pluginRegistryName + ' does not implement TW_Plugin.Registry');
      }
      pluginRegistry = (TW_Plugin.Registry) registry;
    }
    pluginRegistryLoaded = true;
    return pluginRegistry;
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
   * @description Runs the active, non-bypassed actions for the SObject against the current trigger
   * operation. `OnInit` plugin hooks are invoked first, before the actions are resolved, so bypasses
   * they add apply to this execution. Each action's filter is evaluated for every record first, then
   * each action's handler method runs for its filtered records. Plugin hooks are invoked at each
   * lifecycle event. Does nothing more, including invoking the other plugin hooks, if no active,
   * non-bypassed actions exist.
   */
  public void execute() {
    for (TW_Plugin.Plugin p : plugins) {
      if (p instanceof TW_Plugin.OnInit) {
        ((TW_Plugin.OnInit) p).onInit(ctx);
      }
    }

    List<TW_Action> registeredActions = registeredActions();
    if (registeredActions.isEmpty()) {
      System.debug(LoggingLevel.FINE, 'No registered TW Actions, exiting');
      return;
    }

    TW_Executor e = executorFactory.make();

    try {
      for (TW_Plugin.Plugin p : plugins) {
        if (p instanceof TW_Plugin.OnStart) {
          ((TW_Plugin.OnStart) p).onStart(ctx, registeredActions);
        }
      }

      Map<TW_Action, List<SObject>> actionRecords = new Map<TW_Action, List<SObject>>();
      for (TW_Action a : registeredActions) {
        System.debug(LoggingLevel.FINE, 'Filtering records for ' + a);
        List<SObject> filteredRecs = e.filteredRecords(a);
        if (!filteredRecs.isEmpty()) {
          actionRecords.put(a, filteredRecs);
          for (TW_Plugin.Plugin p : plugins) {
            if (p instanceof TW_Plugin.OnActionSetup) {
              ((TW_Plugin.OnActionSetup) p).onActionSetup(ctx, a, filteredRecs);
            }
          }
        }
      }

      for (TW_Plugin.Plugin p : plugins) {
        if (p instanceof TW_Plugin.BeforeExecute) {
          ((TW_Plugin.BeforeExecute) p).beforeExecute(ctx);
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

      for (TW_Plugin.Plugin p : plugins) {
        if (p instanceof TW_Plugin.AfterExecute) {
          ((TW_Plugin.AfterExecute) p).afterExecute(ctx);
        }
      }
    } catch (Exception ex) {
      for (TW_Plugin.Plugin p : plugins) {
        if (p instanceof TW_Plugin.OnError) {
          ((TW_Plugin.OnError) p).onError(ctx, ex);
        }
      }
      throw ex;
    } finally {
      for (TW_Plugin.Plugin p : plugins) {
        if (p instanceof TW_Plugin.OnFinish) {
          ((TW_Plugin.OnFinish) p).onFinish(ctx);
        }
      }
    }
  }

  /**
   * @description Thrown when a handler is created outside of a trigger context.
   */
  public class InvalidContextException extends Exception {
  }

  /**
   * @description Thrown when the plugin registry does not implement TW_Plugin.Registry, or lists a
   * type that does not implement TW_Plugin.Plugin or is already listed.
   */
  public class InvalidPluginException extends Exception {
  }
}
