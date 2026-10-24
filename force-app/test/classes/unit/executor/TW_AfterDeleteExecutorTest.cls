/**
 * @description Provides test coverage for TW_AfterDeleteExecutor
 */
@IsTest
public class TW_AfterDeleteExecutorTest {
  private static final Mock CTX_MOCK = Mock.forType(TW_Context.class);
  private static final TW_Context CTX_STUB = (TW_Context) CTX_MOCK.stub;
  private static final Mock ACTION_MOCK = Mock.forType(TW_Action.class);
  private static final TW_Action ACTION_STUB = (TW_Action) ACTION_MOCK.stub;

  private static final TW_Executor executor = new TW_AfterDeleteExecutor(CTX_STUB);

  /**
   * Ensures filteredRecords returns as expected
   */
  @IsTest
  static void filteredRecords() {
    Account acc1 = new Account(Name = 'one');
    Account acc2 = new Account(Name = 'two');
    List<SObject> recs = new List<Account>{ acc1, acc2 };

    MethodSpy getRecSpy = CTX_MOCK.spyOn('getOld');
    getRecSpy.returns(recs);

    MethodSpy filterSpy = ACTION_MOCK.spyOn('afterDeleteFilter');
    filterSpy.returns(false);
    filterSpy.returnsOnce(true);

    Test.startTest();
    List<SObject> actual = executor.filteredRecords(ACTION_STUB);
    Test.stopTest();

    Expect.that(getRecSpy).hasBeenCalledTimes(1);
    Expect.that(filterSpy).hasBeenCalledTimes(2);
    Expect.that(filterSpy).hasBeenCalledWith(acc1);
    Expect.that(filterSpy).hasBeenCalledWith(acc2);

    System.Assert.areEqual(1, actual.size(), 'unexpected records returned');
    System.Assert.areEqual(acc1, actual[0], 'unexpected records returned');
  }

  /**
   * Ensures execute runs as expected
   */
  @IsTest
  static void execute() {
    SObject triggerRec = new Account(Name = 'Triggered Account');

    MethodSpy primaryMethodSpy = ACTION_MOCK.spyOn('afterDelete');

    Test.startTest();
    executor.execute(ACTION_STUB, triggerRec);
    Test.stopTest();

    Expect.that(primaryMethodSpy).hasBeenCalledTimes(1);
    Expect.that(primaryMethodSpy).hasBeenCalledWith(triggerRec);
  }
}
