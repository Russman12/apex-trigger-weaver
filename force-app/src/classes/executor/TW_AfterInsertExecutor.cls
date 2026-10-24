/**
 * @description Handles After Insert trigger context execution
 * @internal
 */
public with sharing class TW_AfterInsertExecutor implements TW_Executor {
  private final TW_Context ctx;

  public TW_AfterInsertExecutor(TW_Context ctx) {
    this.ctx = ctx;
  }

  public List<SObject> filteredRecords(TW_Action a) {
    List<SObject> filteredRecords = new List<SObject>();
    for (SObject r : ctx.getNew()) {
      ctx.currentRecord = r;
      if (a.afterInsertFilter(r)) {
        filteredRecords.add(r);
      }
    }

    return filteredRecords;
  }

  public void execute(TW_Action a, SObject r) {
    a.afterInsert(r);
  }
}
