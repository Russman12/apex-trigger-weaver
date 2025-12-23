public with sharing class TW_BeforeDeleteExecutor implements TW_Executor {
  private final TW_Context ctx;

  public TW_BeforeDeleteExecutor(TW_Context ctx) {
    this.ctx = ctx;
  }

  public List<SObject> filteredRecords(TW_Action a) {
    List<SObject> filteredRecords = new List<SObject>();
    for (SObject r : ctx.getOld()) {
      if (a.beforeDeleteFilter(r)) {
        filteredRecords.add(r);
      }
    }

    return filteredRecords;
  }

  public void setup(TW_Action a) {
    a.beforeDeleteSetup(ctx.getQuery().getSelector());
  }

  public void execute(TW_Action a, SObject r) {
    a.beforeDelete(r, ctx.getQueriedRecord(r));
  }
}
