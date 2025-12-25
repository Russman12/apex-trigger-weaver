/**
 * @description Provides test coverage for TW_Handler
 */
@IsTest
public class TW_HandlerTest {
  private static final Mock CTX_MOCK = Mock.forType(TW_Context.class);
  private static final TW_Context CTX_STUB = (TW_Context) CTX_MOCK.stub;
  private static final Mock EXEC_FACTORY_MOCK = Mock.forType(TW_ExecutorFactory.class);
  private static final TW_ExecutorFactory EXEC_FACTORY_STUB = (TW_ExecutorFactory) EXEC_FACTORY_MOCK.stub;
  private static final Mock EXEC_MOCK = Mock.forType(TW_Executor.class);
  private static final TW_Executor EXEC_STUB = (TW_Executor) EXEC_MOCK.stub;
  private static final Mock ACTION_REG_MOCK = Mock.forType(TW_ActionRegistry.class);
  private static final TW_ActionRegistry ACTION_REG_STUB = (TW_ActionRegistry) ACTION_REG_MOCK.stub;
  private static final Mock DML_QUEUE_MOCK = Mock.forType(TW_DMLQueue.class);
  private static final TW_DMLQueue DML_QUEUE_STUB = (TW_DMLQueue) DML_QUEUE_MOCK.stub;

  /**
   * Ensures addBypass adds bypass as expected
   */
  @IsTest
  static void addBypass() {
    Test.startTest();
    TW_Handler.addBypass(MyAction1.class);
    Test.stopTest();

    System.Assert.isTrue(TW_Handler.BYPASSES.contains(MyAction1.class), 'expected bypass not included');
  }

  /**
   * Ensures removeBypass removes bypass as expected
   */
  @IsTest
  static void removeBypass() {
    TW_Handler.addBypass(MyAction1.class);

    Test.startTest();
    TW_Handler.removeBypass(MyAction1.class);
    Test.stopTest();

    System.Assert.isFalse(TW_Handler.BYPASSES.contains(MyAction1.class), 'bypass not removed');
  }

  /**
   * Ensures clear clear all bypasses as expected
   */
  @IsTest
  static void clearBypasses() {
    TW_Handler.addBypass(MyAction1.class);
    TW_Handler.addBypass(MyAction2.class);

    Test.startTest();
    TW_Handler.clearBypasses();
    Test.stopTest();

    System.Assert.areEqual(0, TW_Handler.BYPASSES.size(), 'bypasses not cleared');
  }

  /**
   * Ensures constructor throws outside of trigger context
   */
  @IsTest
  static void constructorException() {
    Test.startTest();
    try {
      TW_Handler handler = new TW_Handler(Schema.Account.getSObjectType());
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_Handler.InvalidContextException.class, 'unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures newQuery returns TW_DefaultQuery as expected
   */
  @IsTest
  static void newQuery() {
    TW_Handler handler = new TW_Handler();

    Test.startTest();
    TW_Query q = handler.newQuery(Account.getSObjectType());
    Test.stopTest();

    System.Assert.isInstanceOfType(q, TW_DefaultQuery.class, 'context query not set as expected');
  }

  /**
   * Ensures newQuery returns TW_DefaultQuery as expected
   */
  @IsTest
  static void newDMLQueue() {
    TW_Handler handler = new TW_Handler();

    Test.startTest();
    TW_DMLQueue d = handler.newDMLQueue();
    Test.stopTest();

    System.Assert.isInstanceOfType(d, TW_DefaultDMLQueue.class, 'context dmlQueue not set as expected');
  }

  /**
   * Ensures execute runs all registered actions
   */
  @IsTest
  static void execute() {
    List<System.Type> actions = new List<System.Type>{ MyAction1.class, MyAction2.class };
    List<SObject> filteredRecs = new List<SObject>{ new Account(Name = 'acc1'), new Account(Name = 'acc2') };

    MethodSpy execFactoryMakeSpy = EXEC_FACTORY_MOCK.spyOn('make');
    execFactoryMakeSpy.returns(EXEC_STUB);

    MethodSpy activeActionsSpy = ACTION_REG_MOCK.spyOn('activeActions');
    activeActionsSpy.returns(actions);

    MethodSpy execFilteredRecSpy = EXEC_MOCK.spyOn('filteredRecords');
    execFilteredRecSpy.returns(filteredRecs);

    MethodSpy execSetupSpy = EXEC_MOCK.spyOn('setup');

    MethodSpy runQuerySpy = EXEC_MOCK.spyOn('runQuery');

    MethodSpy execSpy = EXEC_MOCK.spyOn('execute');

    MethodSpy getDmlQueueSpy = CTX_MOCK.spyOn('getDMLQueue');
    getDmlQueueSpy.returns(DML_QUEUE_STUB);

    MethodSpy flushSpy = DML_QUEUE_MOCK.spyOn('flush');

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler handler = new TW_Handler();
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;

    Test.startTest();
    handler.execute();
    Test.stopTest();

    Expect.that(execFactoryMakeSpy).hasBeenCalledTimes(1);
    Expect.that(execFilteredRecSpy).hasBeenCalledTimes(2);
    Expect.that(activeActionsSpy).hasBeenCalledTimes(1);
    Expect.that(execSetupSpy).hasBeenCalledTimes(2);
    Expect.that(runQuerySpy).hasBeenCalledTimes(1);
    Expect.that(execSpy).hasBeenCalledTimes(4);
    Expect.that(getDmlQueueSpy).hasBeenCalledTimes(1);
    Expect.that(flushSpy).hasBeenCalledTimes(1);
  }

  /**
   * Ensures execute skips bypassed actions
   */
  @IsTest
  static void executeBypass() {
    List<System.Type> actions = new List<System.Type>{ MyAction1.class, MyAction2.class };
    List<SObject> filteredRecs = new List<SObject>{ new Account(Name = 'acc1'), new Account(Name = 'acc2') };

    MethodSpy execFactoryMakeSpy = EXEC_FACTORY_MOCK.spyOn('make');
    execFactoryMakeSpy.returns(EXEC_STUB);

    MethodSpy activeActionsSpy = ACTION_REG_MOCK.spyOn('activeActions');
    activeActionsSpy.returns(actions);

    MethodSpy execFilteredRecSpy = EXEC_MOCK.spyOn('filteredRecords');
    execFilteredRecSpy.returns(filteredRecs);

    MethodSpy execSetupSpy = EXEC_MOCK.spyOn('setup');

    MethodSpy runQuerySpy = EXEC_MOCK.spyOn('runQuery');

    MethodSpy execSpy = EXEC_MOCK.spyOn('execute');

    MethodSpy getDmlQueueSpy = CTX_MOCK.spyOn('getDMLQueue');
    getDmlQueueSpy.returns(DML_QUEUE_STUB);

    MethodSpy flushSpy = DML_QUEUE_MOCK.spyOn('flush');

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler.BYPASSES.add(MyAction1.class);
    TW_Handler handler = new TW_Handler();
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;

    Test.startTest();
    handler.execute();
    Test.stopTest();

    Expect.that(execFilteredRecSpy).hasBeenCalledTimes(1);
    Expect.that(activeActionsSpy).hasBeenCalledTimes(1);
    Expect.that(execSetupSpy).hasBeenCalledTimes(1);
    Expect.that(execSpy).hasBeenCalledTimes(2);
  }

  /**
   * Ensures execute skips actions with no records
   */
  @IsTest
  static void executeNoRecs() {
    List<System.Type> actions = new List<System.Type>{ MyAction1.class, MyAction2.class };
    List<SObject> filteredRecs = new List<SObject>{ new Account(Name = 'acc1'), new Account(Name = 'acc2') };

    MethodSpy execFactoryMakeSpy = EXEC_FACTORY_MOCK.spyOn('make');
    execFactoryMakeSpy.returns(EXEC_STUB);

    MethodSpy activeActionsSpy = ACTION_REG_MOCK.spyOn('activeActions');
    activeActionsSpy.returns(actions);

    MethodSpy execFilteredRecSpy = EXEC_MOCK.spyOn('filteredRecords');
    execFilteredRecSpy.returns(filteredRecs);
    execFilteredRecSpy.returnsOnce(new List<SObject>());

    MethodSpy execSetupSpy = EXEC_MOCK.spyOn('setup');

    MethodSpy runQuerySpy = EXEC_MOCK.spyOn('runQuery');

    MethodSpy execSpy = EXEC_MOCK.spyOn('execute');

    MethodSpy getDmlQueueSpy = CTX_MOCK.spyOn('getDMLQueue');
    getDmlQueueSpy.returns(DML_QUEUE_STUB);

    MethodSpy flushSpy = DML_QUEUE_MOCK.spyOn('flush');

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler handler = new TW_Handler();
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;

    Test.startTest();
    handler.execute();
    Test.stopTest();

    Expect.that(execFilteredRecSpy).hasBeenCalledTimes(2);
    Expect.that(execSetupSpy).hasBeenCalledTimes(1);
    Expect.that(execSpy).hasBeenCalledTimes(2);
  }

  /**
   * Ensures execute skips with no actions
   */
  @IsTest
  static void executeNoActions() {
    MethodSpy activeActionsSpy = ACTION_REG_MOCK.spyOn('activeActions');
    activeActionsSpy.returns(new List<System.Type>{});

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler handler = new TW_Handler();
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;

    Test.startTest();
    handler.execute();
    Test.stopTest();
  }

  /**
   * Ensures execute skips with null actions
   */
  @IsTest
  static void executeNullActions() {
    MethodSpy activeActionsSpy = ACTION_REG_MOCK.spyOn('activeActions');
    activeActionsSpy.returns(null);

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler handler = new TW_Handler();
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;

    Test.startTest();
    handler.execute();
    Test.stopTest();
  }

  private class MyAction1 extends TW_Action {
  }

  private class MyAction2 extends TW_Action {
  }
}
