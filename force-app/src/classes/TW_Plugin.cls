/**
 * @description Defines the interfaces used to build plugins.
 * @usage A plugin implements one or more of the lifecycle hook interfaces, which are invoked during
 * trigger execution. A plugin that only provides services to actions, with no hooks, implements
 * `TW_Plugin.Plugin` directly.
 *
 * Plugins are listed by the org's plugin registry, a class named `TW_PluginRegistry` that implements
 * `TW_Plugin.Registry`. Every listed plugin runs for every SObject using the framework, in the order
 * listed. Without a registry, no plugins run. Hooks are only invoked when at least one non-bypassed
 * action is registered for the SObject.
 *
 * One instance is created per trigger execution and shared by every action in that execution.
 * Public methods added to the plugin are available to actions through `TW_Action.getPlugin`,
 * so a single class can hold both the lifecycle behaviour and the API actions use. To share data
 * across every execution in the transaction, such as reference records queried once, hold it in a
 * static variable on the plugin class.
 * @group Framework
 * @example
 * ```
 * // Inserts the follow-up tasks queued by actions in one DML statement
 * public with sharing class FollowUpTaskPlugin implements TW_Plugin.AfterExecute, TW_Plugin.OnError {
 *   private final List<Task> tasks = new List<Task>();
 *
 *   // Called by actions
 *   public void addTask(Id recordId) {
 *     tasks.add(new Task(WhatId = recordId, Subject = 'Follow up'));
 *   }
 *
 *   // Runs once after every action has executed
 *   public void afterExecute(TW_Context ctx) {
 *     insert tasks;
 *   }
 *
 *   // Runs if anything throws
 *   public void onError(TW_Context ctx, Exception e) {
 *     System.debug(LoggingLevel.ERROR, 'Follow-up tasks not created: ' + e.getMessage());
 *   }
 * }
 *
 * // List the plugin in the org's registry
 * public class TW_PluginRegistry implements TW_Plugin.Registry {
 *   public List<System.Type> plugins() {
 *     return new List<System.Type>{ FollowUpTaskPlugin.class };
 *   }
 * }
 *
 * // Use the plugin within an action
 * public override void afterInsert(SObject newRecord) {
 *   FollowUpTaskPlugin followUps = (FollowUpTaskPlugin) getPlugin(FollowUpTaskPlugin.class);
 *   followUps.addTask(newRecord.Id);
 * }
 * ```
 */
public abstract class TW_Plugin {
  /**
   * @description Common interface for all plugins. Every hook interface extends it. Implement it
   * directly for a plugin that provides services to actions but uses no lifecycle hooks.
   */
  public interface Plugin {
  }

  /**
   * @description Lists the plugins that run for every SObject using the framework. Implement it in a
   * class named `TW_PluginRegistry` with a public no-arg constructor. The handler creates the
   * registry once per transaction and calls `plugins` each time a handler is created. Throws
   * TW_Handler.InvalidPluginException from the handler if a class named `TW_PluginRegistry` does not
   * implement this interface.
   * @example
   * ```
   * public class TW_PluginRegistry implements TW_Plugin.Registry {
   *   public List<System.Type> plugins() {
   *     return new List<System.Type>{ TW_Plugin_DML.class, TW_Plugin_Logging.class };
   *   }
   * }
   * ```
   */
  public interface Registry {
    /**
     * @description Returns the plugin types to run, in the order they are invoked. Each type must
     * implement TW_Plugin.Plugin, have a public no-arg constructor, and be listed once, otherwise the
     * handler throws TW_Handler.InvalidPluginException. Returning null or an empty list runs no plugins.
     * @return The plugin types to run.
     */
    List<System.Type> plugins();
  }

  /**
   * @description Hook invoked once after actions are resolved and bypasses are applied.
   */
  public interface OnStart extends Plugin {
    /**
     * @description Invoked once after actions are resolved and bypasses are applied.
     * @param ctx The trigger context.
     * @param actions The actions that will be evaluated for this execution.
     */
    void onStart(TW_Context ctx, List<TW_Action> actions);
  }

  /**
   * @description Hook invoked once for each action that has at least one record after filtering.
   */
  public interface OnActionSetup extends Plugin {
    /**
     * @description Invoked once for each action that has at least one record after filtering.
     * @param ctx The trigger context.
     * @param action The action being set up.
     * @param records The records that passed the action's filter.
     */
    void onActionSetup(TW_Context ctx, TW_Action action, List<SObject> records);
  }

  /**
   * @description Hook invoked once after all actions are set up and before any action logic executes.
   */
  public interface BeforeExecute extends Plugin {
    /**
     * @description Invoked once after all actions are set up and before any action logic executes.
     * @param ctx The trigger context.
     */
    void beforeExecute(TW_Context ctx);
  }

  /**
   * @description Hook invoked once after all action logic executes for every record.
   */
  public interface AfterExecute extends Plugin {
    /**
     * @description Invoked once after all action logic executes for every record.
     * @param ctx The trigger context.
     */
    void afterExecute(TW_Context ctx);
  }

  /**
   * @description Hook invoked when an exception is thrown during execution.
   */
  public interface OnError extends Plugin {
    /**
     * @description Invoked when an exception is thrown during execution. The exception is rethrown
     * after all plugins have been notified.
     * @param ctx The trigger context.
     * @param e The exception that was thrown.
     */
    void onError(TW_Context ctx, Exception e);
  }

  /**
   * @description Hook invoked once at the end of execution, regardless of whether an exception was thrown.
   */
  public interface OnFinish extends Plugin {
    /**
     * @description Invoked once at the end of execution, regardless of whether an exception was thrown.
     * @param ctx The trigger context.
     */
    void onFinish(TW_Context ctx);
  }
}
