public with sharing class TW_ExecutorFactory {
  TW_Context ctx;

  public TW_ExecutorFactory(TW_Context ctx) {
    this.ctx = ctx;
  }

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
    throw new InvalidContextException('There is no valid executor for this context');
  }

  /**
   * @description Represents an exception relating to the context.
   */
  public class InvalidContextException extends Exception {
  }
}
