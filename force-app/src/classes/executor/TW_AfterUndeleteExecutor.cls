public with sharing class TW_AfterUndeleteExecutor implements TW_Executor {
  private final TW_Context ctx;

  public TW_AfterUndeleteExecutor(TW_Context ctx) {
    this.ctx = ctx;
  }

  public List<SObject> filteredRecords(TW_Action a) {
    List<SObject> filteredRecords = new List<SObject>();
    for (SObject r : ctx.getNew()) {
      if (a.afterUndeleteFilter(ctx.getOld(r))) {
        filteredRecords.add(r);
      }
    }

    return filteredRecords;
  }

  public void setup(TW_Action a) {
    a.afterUndeleteSetup(ctx.getQuery().getSelector());
  }

  public void execute(TW_Action a, SObject r) {
    a.afterUndelete(r, ctx.getQueriedRecord(r));
  }
}
