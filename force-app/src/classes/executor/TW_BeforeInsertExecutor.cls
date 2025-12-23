/**
 * @description Handles Before Insert trigger context execution
 * @internal
 */
public with sharing class TW_BeforeInsertExecutor implements TW_Executor {
  private final TW_Context ctx;

  public TW_BeforeInsertExecutor(TW_Context ctx) {
    this.ctx = ctx;
  }

  public List<SObject> filteredRecords(TW_Action a) {
    List<SObject> filteredRecords = new List<SObject>();
    for (SObject r : ctx.getNew()) {
      if (a.beforeInsertFilter(r)) {
        filteredRecords.add(r);
      }
    }

    return filteredRecords;
  }

  public void setup(TW_Action a) {
    a.beforeInsertSetup();
  }

  public void execute(TW_Action a, SObject r) {
    a.beforeInsert(r);
  }
}
