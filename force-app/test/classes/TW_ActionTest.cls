@IsTest
public with sharing class TW_ActionTest {
  private static Mock ctxMock = Mock.forType(TW_Context.class);
  private static TW_Context ctxStub = (TW_Context) ctxMock.stub;

  /**
   * Ensures that the DMLQueue is returned correctly.
   */
  @IsTest
  static void getDMLQueue() {
    TW_Action action = new MyAction();
    action.ctx = ctxStub;
    MyQueue expectedQueue = new MyQueue();

    MethodSpy getDMLQueueSpy = ctxMock.spyOn('getDMLQueue');
    getDMLQueueSpy.returns(expectedQueue);

    Test.startTest();
    TW_DMLQueueable actualQueue = action.getDMLQueue();
    Test.stopTest();

    System.Assert.areEqual(expectedQueue, actualQueue, 'Unexpected dml queue returned');
  }

  /**
   * Ensures that setContext assigns the context.
   */
  @IsTest
  static void setContext() {
    TW_Action action = new MyAction();

    Test.startTest();
    action.setContext(ctxStub);
    Test.stopTest();

    System.Assert.areEqual(ctxStub, action.ctx, 'Context not set as expected');
  }

  /**
   * Ensures InvalidContextException is thrown if context set more than once.
   */
  @IsTest
  static void setContextErr() {
    TW_Action action = new MyAction();
    action.setContext(ctxStub);

    Test.startTest();
    try {
      action.setContext(ctxStub);
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_Action.InvalidContextException.class, 'unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures filteredRecords returns expected results.
   */
  @IsTest
  static void filteredRecords() {
    TW_Action action = new MyAction();
    action.ctx = ctxStub;
    List<SObject> expectedRecs = new List<SObject>{ new Account(Name = 'myacc') };

    MethodSpy filteredRecsSpy = ctxMock.spyOn('filteredRecords');
    filteredRecsSpy.returns(expectedRecs);

    Test.startTest();
    List<SObject> actualRecs = action.filteredRecords();
    Test.stopTest();

    System.Assert.areEqual(expectedRecs, actualRecs, 'Unexpected records returned');
  }

  /**
   * Ensures filteredRecords throws InvalidContextException if context is unset.
   */
  @IsTest
  static void filteredRecordsErr() {
    TW_Action action = new MyAction();
    List<SObject> expectedRecs = new List<SObject>{ new Account(Name = 'myacc') };

    MethodSpy filteredRecsSpy = ctxMock.spyOn('filteredRecords');
    filteredRecsSpy.returns(expectedRecs);

    Test.startTest();
    try {
      action.filteredRecords();
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_Action.InvalidContextException.class, 'unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures context method calls perform no action by default
   */
  @IsTest
  static void contextCallsEmpty() {
    TW_Action action = new MyAction();
    TW_QuerySelectionable selection = new MySelection();
    Account rec = new Account();

    Test.startTest();
    //setup methods
    action.beforeInsertSetup();
    action.afterInsertSetup(selection);
    action.beforeUpdateSetup(selection);
    action.afterUpdateSetup(selection);
    action.beforeDeleteSetup(selection);
    action.afterDeleteSetup(selection);
    action.afterUndeleteSetup(selection);

    //filter methods
    System.assert.isTrue(action.beforeInsertFilter(rec), 'unexpected filter result returned');
    System.assert.isTrue(action.afterInsertFilter(rec), 'unexpected filter results returned');
    System.assert.isTrue(action.beforeUpdateFilter(rec, rec), 'unexpected filter results returned');
    System.assert.isTrue(action.afterUpdateFilter(rec, rec), 'unexpected filter results returned');
    System.assert.isTrue(action.beforeDeleteFilter(rec), 'unexpected filter results returned');
    System.assert.isTrue(action.afterDeleteFilter(rec), 'unexpected filter results returned');
    System.assert.isTrue(action.afterUndeleteFilter(rec), 'unexpected filter results returned');

    //primary function methods
    action.beforeInsert(rec);
    action.afterInsert(rec, rec);
    action.beforeUpdate(rec, rec, rec);
    action.afterUpdate(rec, rec, rec);
    action.beforeDelete(rec, rec);
    action.afterDelete(rec, rec);
    action.afterUndelete(rec, rec);
    Test.stopTest();
  }

  private class MyQueue implements TW_DMLQueueable {
    public void enqueueInsert(SObject record) {
    }
    public void enqueueUpdate(SObject record) {
    }
    public void enqueueDelete(SObject record) {
    }
    public void enqueueUndelete(SObject record) {
    }
    public List<String> flush() {
      return null;
    }
  }

  private class MySelection implements TW_QuerySelectionable {
    public Boolean isSet() {
      return true;
    }
    public void addField(Schema.SObjectField field) {
    }
    public void addFields(Schema.SObjectField[] fields) {
    }
    public void addParentField(Schema.SObjectField[] relationshipPath) {
    }
    public void addChildField(Schema.SObjectField relationshipField, Schema.SObjectField childField) {
    }
    public void addChildParentField(Schema.SObjectField relationshipField, Schema.SObjectField[] relationshipPath) {
    }
    public String toClauseString() {
      return null;
    }
  }

  private class MyEmptyAction extends TW_Action {
    private MyEmptyAction() {
      super(MyEmptyAction.class);
    }
  }

  private class MyAction extends TW_Action {
    private Map<String, Object> methodCalls = new Map<String, Object>();

    private Boolean filterReturnVal = true;

    private MyAction() {
      super(MyAction.class);
    }

    protected override void beforeInsertSetup() {
      methodCalls.put('beforeInsertSetup', null);
    }
    protected override void afterInsertSetup(TW_QuerySelectionable selection) {
      methodCalls.put('afterInsertSetup', selection);
    }
    protected override void beforeUpdateSetup(TW_QuerySelectionable selection) {
      methodCalls.put('beforeUpdateSetup', selection);
    }
    protected override void afterUpdateSetup(TW_QuerySelectionable selection) {
      methodCalls.put('afterUpdateSetup', selection);
    }
    protected override void beforeDeleteSetup(TW_QuerySelectionable selection) {
      methodCalls.put('beforeDeleteSetup', selection);
    }
    protected override void afterDeleteSetup(TW_QuerySelectionable selection) {
      methodCalls.put('afterDeleteSetup', selection);
    }
    protected override void afterUndeleteSetup(TW_QuerySelectionable selection) {
      methodCalls.put('afterUndeleteSetup', selection);
    }

    protected override Boolean beforeInsertFilter(SObject newRecord) {
      methodCalls.put('beforeInsertFilter', newRecord);
      return this.filterReturnVal;
    }
    protected override Boolean afterInsertFilter(SObject newRecord) {
      methodCalls.put('afterInsertFilter', newRecord);
      return this.filterReturnVal;
    }
    protected override Boolean beforeUpdateFilter(SObject oldRecord, SObject newRecord) {
      methodCalls.put('beforeUpdateFilter', new List<Object>{ oldRecord, newRecord });
      return this.filterReturnVal;
    }
    protected override Boolean afterUpdateFilter(SObject oldRecord, SObject newRecord) {
      methodCalls.put('afterUpdateFilter', new List<Object>{ oldRecord, newRecord });
      return this.filterReturnVal;
    }
    protected override Boolean beforeDeleteFilter(SObject oldRecord) {
      methodCalls.put('beforeDeleteFilter', oldRecord);
      return this.filterReturnVal;
    }
    protected override Boolean afterDeleteFilter(SObject oldRecord) {
      methodCalls.put('afterDeleteFilter', oldRecord);
      return this.filterReturnVal;
    }
    protected override Boolean afterUndeleteFilter(SObject newRecord) {
      methodCalls.put('afterUndeleteFilter', newRecord);
      return this.filterReturnVal;
    }

    protected override void beforeInsert(SObject newRecord) {
      methodCalls.put('beforeInsert', newRecord);
    }
    protected override void afterInsert(SObject newRecord, SObject queriedRecord) {
      methodCalls.put('afterInsert', new List<Object>{ newRecord, queriedRecord });
    }
    protected override void beforeUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
      methodCalls.put('beforeUpdate', new List<Object>{ oldRecord, newRecord, queriedRecord });
    }
    protected override void afterUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
      methodCalls.put('afterUpdate', new List<Object>{ oldRecord, newRecord, queriedRecord });
    }
    protected override void beforeDelete(SObject oldRecord, SObject queriedRecord) {
      methodCalls.put('beforeDelete', new List<Object>{ oldRecord, queriedRecord });
    }
    protected override void afterDelete(SObject oldRecord, SObject queriedRecord) {
      methodCalls.put('afterDelete', new List<Object>{ oldRecord, queriedRecord });
    }
    protected override void afterUndelete(SObject newRecord, SObject queriedRecord) {
      methodCalls.put('afterUndelete', new List<Object>{ newRecord, queriedRecord });
    }
  }
}
