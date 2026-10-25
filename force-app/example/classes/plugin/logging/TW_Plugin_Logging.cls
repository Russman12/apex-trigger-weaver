/**
 * Example plugin that logs a summary of each trigger execution: the operation, how many
 * actions had records to process, and the SOQL queries and DML statements consumed (including
 * any nested trigger executions caused by TW_Plugin_DML flushing its queued DML).
 *
 * Register it on a trigger handler with addPlugin:
 * ```
 * new TW_Handler(Account.getSObjectType()).addPlugin(TW_Plugin_Logging.class).execute();
 * ```
 */
public with sharing class TW_Plugin_Logging extends TW_Plugin {
  private Integer startQueries;
  private Integer startDmlStatements;
  private Integer activeActions = 0;

  /**
   * Capture limits before any action logic runs
   */
  public override void onStart(TW_Context ctx, List<TW_Action> actions) {
    startQueries = Limits.getQueries();
    startDmlStatements = Limits.getDmlStatements();
  }

  /**
   * Count each action that has records to process
   */
  public override void onActionSetup(TW_Context ctx, TW_Action action, List<SObject> records) {
    activeActions++;
  }

  /**
   * Log failures before the exception is rethrown by the handler
   */
  public override void onError(TW_Context ctx, Exception e) {
    System.debug(LoggingLevel.ERROR, ctx.getOperation() + ' failed: ' + e.getMessage());
  }

  /**
   * Log the execution summary
   */
  public override void onFinish(TW_Context ctx) {
    System.debug(
      LoggingLevel.INFO,
      ctx.getOperation() +
        ': ' +
        activeActions +
        ' action(s) executed, ' +
        (Limits.getQueries() - startQueries) +
        ' queries, ' +
        (Limits.getDmlStatements() - startDmlStatements) +
        ' DML statements'
    );
  }
}
