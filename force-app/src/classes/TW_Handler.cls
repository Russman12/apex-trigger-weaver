/**
 * @description Entry point for trigger weaver. Create a handler in an SObject's trigger and call
 * execute to run the active actions configured for that SObject, along with any registered plugins.
 * Extend this class to provide default plugins by overriding newPlugins.
 * @example
 * ```
 * trigger AccountTrigger on Account(before insert, after insert, before update, after update) {
 *   new TW_Handler(Account.getSObjectType()).execute();
 * }
 * ```
 * @group Framework
 */
public virtual class TW_Handler {
  @TestVisible
  private static final Set<Type> BYPASSES = new Set<Type>();
  @TestVisible
  private static TW_ActionRegistry actionRegistry = new TW_ActionRegistry();

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
  private final List<TW_Plugin> plugins = new List<TW_Plugin>();
  @TestVisible
  private final Map<System.Type, TW_Plugin> pluginsByType = new Map<System.Type, TW_Plugin>();

  /**
   * @description Creates a handler for the given SObject type from the running trigger and registers
   * the plugins returned by newPlugins. Throws InvalidContextException if called outside a trigger.
   * @param sObjType The SObject type the trigger is running on.
   */
  public TW_Handler(Schema.SObjectType sObjType) {
    //throw execption if not in trigger context
    if (!Trigger.isExecuting) {
      throw new InvalidContextException('Unable to create TW_Handler outside of a trigger context');
    }

    this.sObjType = sObjType;
    this.ctx = new TW_Context();
    this.executorFactory = new TW_ExecutorFactory(this.ctx);
    for (System.Type t : newPlugins()) {
      addPlugin(t);
    }
  }

  @TestVisible
  private TW_Handler() {
  }

  /**
   * @description Registers a new instance of the given plugin type. The type must extend
   * TW_Plugin and have a public no-arg constructor. A new instance is created for each handler,
   * so the plugin is shared by every action in this execution only. Actions access it with
   * `getPlugin(pluginType)`. Plugins are invoked in the order they are registered. Throws
   * InvalidPluginException if a plugin is already registered under the type.
   * @param pluginType The plugin type to register.
   * @return This handler, to allow chaining.
   * @example
   * ```
   * new TW_Handler(Account.getSObjectType()).addPlugin(MyPlugin.class).execute();
   * ```
   */
  public TW_Handler addPlugin(System.Type pluginType) {
    return addPlugin(pluginType, (TW_Plugin) pluginType.newInstance());
  }

  /**
   * @description Registers the given plugin instance under the given type. Use this when the
   * plugin requires constructor arguments, or to substitute an implementation for the type.
   * Always pass a new instance; an instance shared between handlers (e.g. held in a static variable)
   * is shared with nested trigger executions. Throws InvalidPluginException if a plugin is already
   * registered under the type.
   * @param pluginType The type actions use to look up the plugin.
   * @param plugin The plugin instance.
   * @return This handler, to allow chaining.
   * @example
   * ```
   * new TW_Handler(Account.getSObjectType()).addPlugin(MyPlugin.class, new MyPlugin('config')).execute();
   * ```
   */
  public TW_Handler addPlugin(System.Type pluginType, TW_Plugin plugin) {
    if (pluginsByType.containsKey(pluginType)) {
      throw new InvalidPluginException('Plugin already registered for ' + pluginType);
    }
    this.plugins.add(plugin);
    this.pluginsByType.put(pluginType, plugin);
    return this;
  }

  /**
   * @description Returns the plugin types registered when the handler is constructed. Override to
   * provide default plugins. Plugins added with addPlugin run after these.
   * @return Empty list of plugin types by default.
   */
  @TestVisible
  protected virtual List<System.Type> newPlugins() {
    return new List<System.Type>();
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
   * operation. Each action's filter is evaluated for every record first, then each action's handler
   * method runs for its filtered records. Plugin hooks are invoked at each lifecycle event. Does
   * nothing, including invoking plugins, if no active, non-bypassed actions exist.
   */
  public void execute() {
    List<TW_Action> registeredActions = registeredActions();
    if (registeredActions.isEmpty()) {
      System.debug(LoggingLevel.FINE, 'No registered TW Actions, exiting');
      return;
    }

    ctx.setPlugins(pluginsByType);
    TW_Executor e = executorFactory.make();

    try {
      for (TW_Plugin p : plugins) {
        p.onStart(ctx, registeredActions);
      }

      Map<TW_Action, List<SObject>> actionRecords = new Map<TW_Action, List<SObject>>();
      for (TW_Action a : registeredActions) {
        System.debug(LoggingLevel.FINE, 'Filtering records for ' + a);
        List<SObject> filteredRecs = e.filteredRecords(a);
        if (!filteredRecs.isEmpty()) {
          actionRecords.put(a, filteredRecs);
          for (TW_Plugin p : plugins) {
            p.onActionSetup(ctx, a, filteredRecs);
          }
        }
      }

      for (TW_Plugin p : plugins) {
        p.beforeExecute(ctx);
      }

      for (TW_Action a : registeredActions) {
        if (actionRecords.containsKey(a)) {
          for (SObject r : actionRecords.get(a)) {
            ctx.currentRecord = r;
            e.execute(a, r);
          }
        }
      }

      for (TW_Plugin p : plugins) {
        p.afterExecute(ctx);
      }
    } catch (Exception ex) {
      for (TW_Plugin p : plugins) {
        p.onError(ctx, ex);
      }
      throw ex;
    } finally {
      for (TW_Plugin p : plugins) {
        p.onFinish(ctx);
      }
    }
  }

  /**
   * @description Thrown when a handler is created outside of a trigger context.
   */
  public class InvalidContextException extends Exception {
  }

  /**
   * @description Thrown when a plugin is registered under a type that is already registered.
   */
  public class InvalidPluginException extends Exception {
  }
}
