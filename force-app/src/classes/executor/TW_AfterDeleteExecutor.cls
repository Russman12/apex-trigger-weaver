public with sharing class TW_AfterDeleteExecutor implements TW_Executor {
  private final TW_Context ctx;

  public TW_AfterDeleteExecutor(TW_Context ctx) {
    this.ctx = ctx;
  }

  public List<SObject> filteredRecords(TW_Action a) {
    List<SObject> filteredRecords = new List<SObject>();
    for (SObject r : ctx.getOld()) {
      if (a.afterDeleteFilter(r)) {
        filteredRecords.add(r);
      }
    }

    return filteredRecords;
  }

  public void setup(TW_Action a) {
    a.afterDeleteSetup(ctx.getQuery().getSelector());
  }

  public void execute(TW_Action a, SObject r) {
    a.afterDelete(r, ctx.getQueriedRecord(r));
  }
}
