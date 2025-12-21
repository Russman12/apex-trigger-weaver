/**
 * @description Encapsulates orchestration for executing TW_Action hooks. Moves executeSetup and execute
 *              responsibilities out of TW_Action to keep actions focused on business logic.
 * @group Framework
 */
public with sharing class TW_ActionExecutor {
  /**
   * @description Executes setup flow for an action: per-phase setup + filtering to populate context.
   * @param action Action instance (must already have its type set via action.setType()).
   * @param ctx Trigger Weaver context (must be non-null).
   * @param selection Query selection provider for phases that require related data configuration.
   */
  public void executeSetup(TW_Action action, TW_Context ctx, TW_QuerySelectionable selection) {
    if (ctx == null) {
      throw new InvalidContextException('Context must be provided to execute setup.');
    }
    if (action == null) {
      throw new InvalidContextException('Action must be provided to execute setup.');
    }
    // Ensure the action has the same context used system-wide.
    action.setContext(ctx);

    switch on ctx.getOperation() {
      when BEFORE_INSERT {
        action.beforeInsertSetup();
        for (SObject newRecord : ctx.getNew()) {
          if (action.beforeInsertFilter(newRecord)) {
            ctx.addFilteredRecord(action.getType(), newRecord);
          }
        }
      }
      when AFTER_INSERT {
        action.afterInsertSetup(selection);
        for (SObject newRecord : ctx.getNew()) {
          if (action.afterInsertFilter(newRecord)) {
            ctx.addFilteredRecord(action.getType(), newRecord);
          }
        }
      }
      when BEFORE_UPDATE {
        action.beforeUpdateSetup(selection);
        for (SObject newRecord : ctx.getNew()) {
          ctx.currentUpdateRecord = newRecord;
          SObject oldRecord = ctx.getOldMap().get(newRecord.Id);
          if (action.beforeUpdateFilter(oldRecord, newRecord)) {
            ctx.addFilteredRecord(action.getType(), newRecord);
          }
        }
      }
      when AFTER_UPDATE {
        action.afterUpdateSetup(selection);
        for (SObject newRecord : ctx.getNew()) {
          ctx.currentUpdateRecord = newRecord;
          SObject oldRecord = ctx.getOldMap().get(newRecord.Id);
          if (action.afterUpdateFilter(oldRecord, newRecord)) {
            ctx.addFilteredRecord(action.getType(), newRecord);
          }
        }
      }
      when BEFORE_DELETE {
        action.beforeDeleteSetup(selection);
        for (SObject oldRecord : ctx.getOld()) {
          if (action.beforeDeleteFilter(oldRecord)) {
            ctx.addFilteredRecord(action.getType(), oldRecord);
          }
        }
      }
      when AFTER_DELETE {
        action.afterDeleteSetup(selection);
        for (SObject oldRecord : ctx.getOld()) {
          if (action.afterDeleteFilter(oldRecord)) {
            ctx.addFilteredRecord(action.getType(), oldRecord);
          }
        }
      }
      when AFTER_UNDELETE {
        action.afterUndeleteSetup(selection);
        for (SObject newRecord : ctx.getNew()) {
          if (action.afterUndeleteFilter(newRecord)) {
            ctx.addFilteredRecord(action.getType(), newRecord);
          }
        }
      }
    }
  }

  /**
   * @description Executes per-record primary logic for an action using the already filtered records
   *              and any queried related data present in the context.
   * @param action Action instance (must already have its type set via action.setType()).
   * @param ctx Trigger Weaver context (must be non-null).
   */
  public void execute(TW_Action action, TW_Context ctx) {
    if (ctx == null) {
      throw new InvalidContextException('Context must be provided to execute action.');
    }
    if (action == null) {
      throw new InvalidContextException('Action must be provided to execute action.');
    }

    switch on ctx.getOperation() {
      when BEFORE_INSERT {
        for (SObject newRecord : ctx.filteredRecords()) {
          if (action.beforeInsertFilter(newRecord)) {
            action.beforeInsert(newRecord);
          }
        }
      }
      when AFTER_INSERT {
        for (SObject newRecord : ctx.filteredRecords()) {
          if (action.afterInsertFilter(newRecord)) {
            action.afterInsert(newRecord, ctx.getQueriedRecordMap().get(newRecord.Id));
          }
        }
      }
      when BEFORE_UPDATE {
        for (SObject newRecord : ctx.filteredRecords()) {
          ctx.currentUpdateRecord = newRecord;
          SObject oldRecord = ctx.getOldMap().get(newRecord.Id);
          if (action.beforeUpdateFilter(oldRecord, newRecord)) {
            action.beforeUpdate(oldRecord, newRecord, ctx.getQueriedRecordMap().get(newRecord.Id));
          }
        }
      }
      when AFTER_UPDATE {
        for (SObject newRecord : ctx.filteredRecords()) {
          ctx.currentUpdateRecord = newRecord;
          SObject oldRecord = ctx.getOldMap().get(newRecord.Id);
          if (action.afterUpdateFilter(oldRecord, newRecord)) {
            action.afterUpdate(oldRecord, newRecord, ctx.getQueriedRecordMap().get(newRecord.Id));
          }
        }
      }
      when BEFORE_DELETE {
        for (SObject oldRecord : ctx.filteredRecords()) {
          if (action.beforeDeleteFilter(oldRecord)) {
            action.beforeDelete(oldRecord, ctx.getQueriedRecordMap().get(oldRecord.Id));
          }
        }
      }
      when AFTER_DELETE {
        for (SObject oldRecord : ctx.filteredRecords()) {
          if (action.afterDeleteFilter(oldRecord)) {
            action.afterDelete(oldRecord, ctx.getQueriedRecordMap().get(oldRecord.Id));
          }
        }
      }
      when AFTER_UNDELETE {
        for (SObject newRecord : ctx.filteredRecords()) {
          if (action.afterUndeleteFilter(newRecord)) {
            action.afterUndelete(newRecord, ctx.getQueriedRecordMap().get(newRecord.Id));
          }
        }
      }
    }
  }

  public class InvalidContextException extends Exception {
  }
}
