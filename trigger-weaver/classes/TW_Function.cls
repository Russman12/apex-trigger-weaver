public abstract class TW_Function {
  private Action a;
  public void setAction(System.TriggerOperation operation) {
    switch on operation {
      when BEFORE_INSERT {
        a = new BeforeInsertAction();
      }
      when AFTER_INSERT {
        a = new AfterInsertAction();
      }
      when BEFORE_UPDATE {
        a = new BeforeUpdateAction();
      }
      when AFTER_UPDATE {
        a = new AfterUpdateAction();
      }
      when BEFORE_DELETE {
        a = new BeforeDeleteAction();
      }
      when AFTER_DELETE {
        a = new AfterDeleteAction();
      }
      when AFTER_UNDELETE {
        a = new AfterUndeleteAction();
      }
    }
  }

  protected virtual ASB_Select beforeUpdateSelection(ASB_Select selection) {
    return selection;
  }
  protected virtual ASB_Select afterUpdateSelection(ASB_Select selection) {
    return selection;
  }
  protected virtual ASB_Select beforeDeleteSelection(ASB_Select selection) {
    return selection;
  }
  protected virtual ASB_Select afterDeleteSelection(ASB_Select selection) {
    return selection;
  }
  protected virtual ASB_Select afterUndeleteSelection(ASB_Select selection) {
    return selection;
  }

  public ASB_Select querySelection(ASB_Select selection) {
    return this.a.selection(this, selection);
  }

  protected virtual List<SObject> beforeInsert(TW_Context ctx) {
    return null;
  }
  protected virtual List<SObject> beforeInsert(SObject newRecord) {
    return null;
  }
  protected virtual List<SObject> afterInsert(TW_Context ctx) {
    return null;
  }
  protected virtual List<SObject> afterInsert(SObject newRecord) {
    return null;
  }
  protected virtual List<SObject> beforeUpdate(TW_Context ctx) {
    return null;
  }
  protected virtual List<SObject> beforeUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
    return null;
  }
  protected virtual List<SObject> afterUpdate(TW_Context ctx) {
    return null;
  }
  protected virtual List<SObject> afterUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
    return null;
  }
  protected virtual List<SObject> beforeDelete(TW_Context ctx) {
    return null;
  }
  protected virtual List<SObject> beforeDelete(SObject oldRecord, SObject queriedRecord) {
    return null;
  }
  protected virtual List<SObject> afterDelete(TW_Context ctx) {
    return null;
  }
  protected virtual List<SObject> afterDelete(SObject oldRecord, SObject queriedRecord) {
    return null;
  }
  protected virtual List<SObject> afterUndelete(TW_Context ctx) {
    return null;
  }
  protected virtual List<SObject> afterUndelete(SObject newRecord, SObject queriedRecord) {
    return null;
  }

  public void execute(TW_Context ctx) {
    a.execute(this, ctx);
  }

  private interface Action {
    void execute(TW_Function function, TW_Context ctx);
    ASB_Select selection(TW_Function function, ASB_Select selection);
  }

  private class BeforeInsertAction implements Action {
    private BeforeInsertAction() {
    }
    public void execute(TW_Function function, TW_Context ctx) {
      function.beforeInsert(ctx);
      for (SObject newRecord : ctx.newRecords) {
        function.beforeInsert(newRecord);
      }
    }
    public ASB_SELECT selection(TW_Function function, ASB_Select selection) {
      return selection;
    }
  }
  private class AfterInsertAction implements Action {
    private AfterInsertAction() {
    }
    public void execute(TW_Function function, TW_Context ctx) {
      function.afterInsert(ctx);
      for (SObject newRecord : ctx.newRecords) {
        function.afterInsert(newRecord);
      }
    }
    public ASB_Select selection(TW_Function function, ASB_Select selection) {
      return selection;
    }
  }
  private class BeforeUpdateAction implements Action {
    private BeforeUpdateAction() {
    }
    public void execute(TW_Function function, TW_Context ctx) {
      function.beforeUpdate(ctx);
      for (SObject newRecord : ctx.newRecords) {
        function.beforeUpdate(ctx.oldRecordsMap.get(newRecord.Id), newRecord, ctx.queriedRecordsMap.get(newRecord.Id));
      }
    }
    public ASB_Select selection(TW_Function function, ASB_Select selection) {
      return function.beforeUpdateSelection(selection);
    }
  }
  private class AfterUpdateAction implements Action {
    private AfterUpdateAction() {
    }
    public void execute(TW_Function function, TW_Context ctx) {
      function.afterUpdate(ctx);
      for (SObject newRecord : ctx.newRecords) {
        function.afterUpdate(ctx.oldRecordsMap.get(newRecord.Id), newRecord, ctx.queriedRecordsMap.get(newRecord.Id));
      }
    }
    public ASB_Select selection(TW_Function function, ASB_Select selection) {
      return function.afterUpdateSelection(selection);
    }
  }
  private class BeforeDeleteAction implements Action {
    private BeforeDeleteAction() {
    }
    public void execute(TW_Function function, TW_Context ctx) {
      function.beforeDelete(ctx);
      for (SObject oldRecord : ctx.oldRecords) {
        function.beforeDelete(oldRecord, ctx.queriedRecordsMap.get(oldRecord.Id));
      }
    }
    public ASB_Select selection(TW_Function function, ASB_Select selection) {
      return function.beforeDeleteSelection(selection);
    }
  }
  private class AfterDeleteAction implements Action {
    private AfterDeleteAction() {
    }
    public void execute(TW_Function function, TW_Context ctx) {
      function.afterDelete(ctx);
      for (SObject oldRecord : ctx.oldRecords) {
        function.afterDelete(oldRecord, ctx.queriedRecordsMap.get(oldRecord.Id));
      }
    }
    public ASB_Select selection(TW_Function function, ASB_Select selection) {
      return function.afterDeleteSelection(selection);
    }
  }
  private class AfterUndeleteAction implements Action {
    private AfterUndeleteAction() {
    }
    public void execute(TW_Function function, TW_Context ctx) {
      function.afterUndelete(ctx);
      for (SObject newRecord : ctx.newRecords) {
        function.afterUndelete(newRecord, ctx.queriedRecordsMap.get(newRecord.Id));
      }
    }
    public ASB_Select selection(TW_Function function, ASB_Select selection) {
      return function.afterUndeleteSelection(selection);
    }
  }
}