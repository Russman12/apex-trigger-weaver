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
    TW_DMLQueue actualQueue = action.getDMLQueue();
    Test.stopTest();

    Expect.that(getDMLQueueSpy).hasBeenCalledTimes(1);
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
   * Ensures oldRecords delegates to context
   */
  @IsTest
  static void oldRecords() {
    TW_Action action = new MyAction();
    action.ctx = ctxStub;

    List<SObject> records = new List<SObject>{ new Account() };

    MethodSpy spy = ctxMock.spyOn('getOld');
    spy.returns(records);

    Test.startTest();
    System.Assert.areEqual(records, action.oldRecords(), 'unexpected result returned');
    Test.stopTest();

    Expect.that(spy).hasBeenCalledTimes(1);
  }

  /**
   * Ensures newRecords delegates to context
   */
  @IsTest
  static void newRecords() {
    TW_Action action = new MyAction();
    action.ctx = ctxStub;

    List<SObject> records = new List<SObject>{ new Account() };

    MethodSpy spy = ctxMock.spyOn('getNew');
    spy.returns(records);

    Test.startTest();
    System.Assert.areEqual(records, action.newRecords(), 'unexpected result returned');
    Test.stopTest();

    Expect.that(spy).hasBeenCalledTimes(1);
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
      System.Assert.isInstanceOfType(e, TW_Action.InvalidActionException.class, 'unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures isChanged delegates to context
   */
  @IsTest
  static void isChanged() {
    TW_Action action = new MyAction();
    action.ctx = ctxStub;

    MethodSpy spy = ctxMock.spyOn('isChanged');
    spy.returns(true);

    Test.startTest();
    System.Assert.isTrue(action.isChanged(Account.Name), 'unexpected result returned');
    Test.stopTest();

    Expect.that(spy).hasBeenCalledTimes(1);
    Expect.that(spy).hasBeenCalledWith(Account.Name);
  }

  /**
   * Ensures anyChanged delegates to context
   */
  @IsTest
  static void anyChanged() {
    TW_Action action = new MyAction();
    action.ctx = ctxStub;

    MethodSpy spy = ctxMock.spyOn('anyChanged');
    spy.returns(true);

    SObjectField[] fields = new List<SObjectField>{ Account.Name, Account.Phone };

    Test.startTest();
    System.Assert.isTrue(action.anyChanged(fields), 'unexpected result returned');
    Test.stopTest();

    Expect.that(spy).hasBeenCalledTimes(1);
    Expect.that(spy).hasBeenCalledWith(fields);
  }

  /**
   * Ensures anyChanged delegates to context
   */
  @IsTest
  static void allChanged() {
    TW_Action action = new MyAction();
    action.ctx = ctxStub;

    MethodSpy spy = ctxMock.spyOn('allChanged');
    spy.returns(true);

    SObjectField[] fields = new List<SObjectField>{ Account.Name, Account.Phone };

    Test.startTest();
    System.Assert.isTrue(action.allChanged(fields), 'unexpected result returned');
    Test.stopTest();

    Expect.that(spy).hasBeenCalledTimes(1);
    Expect.that(spy).hasBeenCalledWith(fields);
  }

  /**
   * Ensures context method calls perform no action by default
   */
  @IsTest
  static void contextCallsEmpty() {
    TW_Action action = new MyAction();
    TW_QuerySelector selection = new MySelection();
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

  private class MyQueue implements TW_DMLQueue {
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

  private class MySelection implements TW_QuerySelector {
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

  private class MyAction extends TW_Action {
  }
}
