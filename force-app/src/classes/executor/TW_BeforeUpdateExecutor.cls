/**
 * @description Handles Before Update trigger context execution
 * @internal
 */
public with sharing class TW_BeforeUpdateExecutor implements TW_Executor {
  private final TW_Context ctx;

  public TW_BeforeUpdateExecutor(TW_Context ctx) {
    this.ctx = ctx;
  }

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

  public void execute(TW_Action a, SObject r) {
    a.beforeUpdate(ctx.getOld(r), r);
  }
}
