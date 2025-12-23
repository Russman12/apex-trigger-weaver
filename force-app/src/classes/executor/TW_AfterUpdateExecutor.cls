public with sharing class TW_AfterUpdateExecutor implements TW_Executor {
  private final TW_Context ctx;

  public TW_AfterUpdateExecutor(TW_Context ctx) {
    this.ctx = ctx;
  }

  public List<SObject> filteredRecords(TW_Action a) {
    List<SObject> filteredRecords = new List<SObject>();
    for (SObject r : ctx.getNew()) {
      if (a.afterUpdateFilter(ctx.getOld(r), r)) {
        filteredRecords.add(r);
      }
    }

    return filteredRecords;
  }

  public void setup(TW_Action a) {
    a.afterUpdateSetup(ctx.getQuery().getSelector());
  }

  public void execute(TW_Action a, SObject r) {
    a.afterUpdate(ctx.getOld(r), r, ctx.getQueriedRecord(r));
  }
}
