public abstract class TW_Function {
  private final System.Type t;

  private final List<SObject> updateRecords = new List<SObject>();

  private TW_Context ctx;

  protected TW_Function(System.Type t) {
    this.t = t;
  }

  public void setContext(TW_Context ctx) {
    if (this.ctx != null) {
      throw new InvalidContextException('Context can only be set once');
    }
    this.ctx = ctx;
  }

  public TW_Context getContext() {
    return this.ctx;
  }

  public System.Type getType() {
    return this.t;
  }

  public List<SObject> filteredRecords() {
    if (this.ctx == null) {
      throw new InvalidContextException('Context must be set to perform this action. Run setContext(TW_Context ctx) first');
    }
    return ctx.filteredRecords(this.t);
  }

  protected virtual void beforeInsertPreProcess() {
  }
  protected virtual void afterInsertPreProcess(ASB_Select selection) {
  }
  protected virtual void beforeUpdatePreProcess(ASB_Select selection) {
  }
  protected virtual void afterUpdatePreProcess(ASB_Select selection) {
  }
  protected virtual void beforeDeletePreProcess(ASB_Select selection) {
  }
  protected virtual void afterDeletePreProcess(ASB_Select selection) {
  }
  protected virtual void afterUndeletePreProcess(ASB_Select selection) {
  }

  protected virtual List<SObject> beforeInsert(SObject newRecord) {
    return null;
  }
  protected virtual List<SObject> afterInsert(SObject newRecord, SObject queriedRecord) {
    return null;
  }
  protected virtual List<SObject> beforeUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
    return null;
  }
  protected virtual List<SObject> afterUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
    return null;
  }
  protected virtual List<SObject> beforeDelete(SObject oldRecord, SObject queriedRecord) {
    return null;
  }
  protected virtual List<SObject> afterDelete(SObject oldRecord, SObject queriedRecord) {
    return null;
  }
  protected virtual List<SObject> afterUndelete(SObject newRecord, SObject queriedRecord) {
    return null;
  }

  protected virtual Boolean beforeInsertFilter(SObject newRecord) {
    return true;
  }
  protected virtual Boolean afterInsertFilter(SObject newRecord) {
    return true;
  }
  protected virtual Boolean beforeUpdateFilter(SObject oldRecord, SObject newRecord) {
    return true;
  }
  protected virtual Boolean afterUpdateFilter(SObject oldRecord, SObject newRecord) {
    return true;
  }
  protected virtual Boolean beforeDeleteFilter(SObject oldRecord) {
    return true;
  }
  protected virtual Boolean afterDeleteFilter(SObject oldRecord) {
    return true;
  }
  protected virtual Boolean afterUndeleteFilter(SObject newRecord) {
    return true;
  }

  public void executePreProcess() {
    if (this.ctx == null) {
      throw new InvalidContextException('Context must be set to perform this action. Run setContext(TW_Context ctx) first');
    }

    ASB_Select selection = ASB_Select.make();
    switch on this.ctx.getOperation() {
      when BEFORE_INSERT {
        this.beforeInsertPreProcess();
        for (SObject newRecord : this.ctx.getNew()) {
          if (this.beforeInsertFilter(newRecord)) {
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
      when AFTER_INSERT {
        this.afterInsertPreProcess(selection);
        for (SObject newRecord : this.ctx.getNew()) {
          if (this.afterInsertFilter(newRecord)) {
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
      when BEFORE_UPDATE {
        this.beforeUpdatePreProcess(selection);
        for (SObject newRecord : this.ctx.getNew()) {
          SObject oldRecord = this.ctx.getOldMap().get(newRecord.Id);
          if (this.beforeUpdateFilter(oldRecord, newRecord)) {
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
      when AFTER_UPDATE {
        this.afterUpdatePreProcess(selection);
        for (SObject newRecord : this.ctx.getNew()) {
          SObject oldRecord = this.ctx.getOldMap().get(newRecord.Id);
          if (this.afterUpdateFilter(oldRecord, newRecord)) {
            System.debug('adding');
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
      when BEFORE_DELETE {
        this.beforeDeletePreProcess(selection);
        for (SObject oldRecord : this.ctx.getOld()) {
          if (this.beforeDeleteFilter(oldRecord)) {
            ctx.addFilteredRecord(this.t, oldRecord);
          }
        }
      }
      when AFTER_DELETE {
        this.afterDeletePreProcess(selection);
        for (SObject oldRecord : this.ctx.getOld()) {
          if (this.afterDeleteFilter(oldRecord)) {
            ctx.addFilteredRecord(this.t, oldRecord);
          }
        }
      }
      when AFTER_UNDELETE {
        this.afterUndeletePreProcess(selection);
        for (SObject newRecord : this.ctx.getNew()) {
          if (this.afterUndeleteFilter(newRecord)) {
            ctx.addFilteredRecord(this.t, newRecord);
          }
        }
      }
    }
    System.debug(selection.clauseString());
    if (selection.hasElements()) {
      System.debug('has elements');
      this.ctx.addQuerySelection(this.t, selection);
    }
  }

  public void execute() {
    if (this.ctx == null) {
      throw new InvalidContextException('Context must be set to perform this action. Run setContext(TW_Context ctx) first');
    }
    switch on this.ctx.getOperation() {
      when BEFORE_INSERT {
        for (SObject newRecord : this.ctx.filteredRecords()) {
          if (this.beforeInsertFilter(newRecord)) {
            this.beforeInsert(newRecord);
          }
        }
      }
      when AFTER_INSERT {
        for (SObject newRecord : this.ctx.filteredRecords()) {
          if (this.afterInsertFilter(newRecord)) {
            this.afterInsert(newRecord, this.ctx.getQueriedRecordMap().get(newRecord.Id));
          }
        }
      }
      when BEFORE_UPDATE {
        for (SObject newRecord : this.ctx.filteredRecords()) {
          SObject oldRecord = this.ctx.getOldMap().get(newRecord.Id);
          if (this.beforeUpdateFilter(oldRecord, newRecord)) {
            this.beforeUpdate(oldRecord, newRecord, this.ctx.getQueriedRecordMap().get(newRecord.Id));
          }
        }
      }
      when AFTER_UPDATE {
        for (SObject newRecord : this.ctx.filteredRecords()) {
          SObject oldRecord = this.ctx.getOldMap().get(newRecord.Id);
          if (this.afterUpdateFilter(oldRecord, newRecord)) {
            this.afterUpdate(oldRecord, newRecord, this.ctx.getQueriedRecordMap().get(newRecord.Id));
          }
        }
      }
      when BEFORE_DELETE {
        for (SObject oldRecord : this.ctx.filteredRecords()) {
          if (this.beforeDeleteFilter(oldRecord)) {
            this.beforeDelete(oldRecord, this.ctx.getQueriedRecordMap().get(oldRecord.Id));
          }
        }
      }
      when AFTER_DELETE {
        for (SObject oldRecord : this.ctx.filteredRecords()) {
          if (this.afterDeleteFilter(oldRecord)) {
            this.afterDelete(oldRecord, this.ctx.getQueriedRecordMap().get(oldRecord.Id));
          }
        }
      }
      when AFTER_UNDELETE {
        for (SObject newRecord : this.ctx.filteredRecords()) {
          if (this.afterUndeleteFilter(newRecord)) {
            this.afterUndelete(newRecord, this.ctx.getQueriedRecordMap().get(newRecord.Id));
          }
        }
      }
    }
  }

  protected void updateRecord(SObject rec) {
    this.updateRecords.add(rec);
  }

  public List<SObject> getUpdates() {
    return this.updateRecords.deepClone(true);
  }

  public class InvalidContextException extends Exception {
  }
}
