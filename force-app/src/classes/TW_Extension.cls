/**
 * @description Defines lifecycle hooks that are invoked during trigger execution. Extend this class
 * and override the hooks needed, then register the extension with `TW_Handler.addExtension` or by
 * overriding `TW_Handler.newExtensions`. Extensions are invoked in the order they are registered.
 * Hooks are only invoked when at least one non-bypassed action is registered for the SObject.
 * @group Framework
 * @example
 * ```
 * new TW_Handler(Account.getSObjectType()).addExtension(new MyExtension()).execute();
 * ```
 */
public abstract class TW_Extension {
  /**
   * @description Invoked once after actions are resolved and bypasses are applied.
   * @param ctx The trigger context.
   * @param actions The actions that will be evaluated for this execution.
   */
  @TestVisible
  public virtual void onStart(TW_Context ctx, List<TW_Action> actions) {
  }

  /**
   * @description Invoked once for each action that has at least one record after filtering.
   * @param ctx The trigger context.
   * @param action The action being set up.
   * @param records The records that passed the action's filter.
   */
  @TestVisible
  public virtual void onActionSetup(TW_Context ctx, TW_Action action, List<SObject> records) {
  }

  /**
   * @description Invoked once after all actions are set up and before any action logic executes.
   * @param ctx The trigger context.
   */
  @TestVisible
  public virtual void beforeExecute(TW_Context ctx) {
  }

  /**
   * @description Invoked once after all action logic executes for every record.
   * @param ctx The trigger context.
   */
  @TestVisible
  public virtual void afterExecute(TW_Context ctx) {
  }

  /**
   * @description Invoked when an exception is thrown during execution. The exception is rethrown
   * after all extensions have been notified.
   * @param ctx The trigger context.
   * @param e The exception that was thrown.
   */
  @TestVisible
  public virtual void onError(TW_Context ctx, Exception e) {
  }

  /**
   * @description Invoked once at the end of execution, regardless of whether an exception was thrown.
   * @param ctx The trigger context.
   */
  @TestVisible
  public virtual void onFinish(TW_Context ctx) {
  }
}
