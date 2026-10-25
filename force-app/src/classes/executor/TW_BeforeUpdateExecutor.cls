/**
 * @description Runs actions' before update filter and handler methods.
 * @internal
 */
public with sharing class TW_BeforeUpdateExecutor implements TW_Executor {
  private final TW_Context ctx;

  /**
   * @description Creates an executor for the given context.
   * @param ctx The context providing the trigger records.
   */
  public TW_BeforeUpdateExecutor(TW_Context ctx) {
    this.ctx = ctx;
  }

  /**
   * @description Returns the trigger records that pass the action's before update filter.
   * @param a The action whose filter is applied.
   * @return The records that passed the filter.
   */
  public List<SObject> filteredRecords(TW_Action a) {
    List<SObject> filteredRecords = new List<SObject>();
    for (SObject r : ctx.getNew()) {
      ctx.currentRecord = r;
      if (a.beforeUpdateFilter(ctx.getOld(r), r)) {
        filteredRecords.add(r);
      }
    }

    return filteredRecords;
  }

  /**
   * @description Calls the action's before update handler method for the given record.
   * @param a The action to execute.
   * @param r The record to execute the action on.
   */
  public void execute(TW_Action a, SObject r) {
    a.beforeUpdate(ctx.getOld(r), r);
  }
}
