/**
 * @description Creates the TW_Executor for the trigger operation of a context.
 * @internal
 */
public with sharing class TW_ExecutorFactory {
  TW_Context ctx;

  /**
   * @description Creates a factory for the given context.
   * @param ctx The context whose trigger operation determines the executor.
   */
  public TW_ExecutorFactory(TW_Context ctx) {
    this.ctx = ctx;
  }

  /**
   * @description Returns the executor for the context's trigger operation.
   * @return The executor for the current operation.
   */
  public TW_Executor make() {
    switch on ctx.getOperation() {
      when BEFORE_INSERT {
        return new TW_BeforeInsertExecutor(this.ctx);
      }
      when AFTER_INSERT {
        return new TW_AfterInsertExecutor(this.ctx);
      }
      when BEFORE_UPDATE {
        return new TW_BeforeUpdateExecutor(this.ctx);
      }
      when AFTER_UPDATE {
        return new TW_AfterUpdateExecutor(this.ctx);
      }
      when BEFORE_DELETE {
        return new TW_BeforeDeleteExecutor(this.ctx);
      }
      when AFTER_DELETE {
        return new TW_AfterDeleteExecutor(this.ctx);
      }
      when AFTER_UNDELETE {
        return new TW_AfterUndeleteExecutor(this.ctx);
      }
    }
    return null;
  }
}
