/**
 * @description Provides test coverage for TW_BeforeDeleteExecutor
 */
@IsTest
public class TW_BeforeDeleteExecutorTest {
  private static final Mock CTX_MOCK = Mock.forType(TW_Context.class);
  private static final TW_Context CTX_STUB = (TW_Context) CTX_MOCK.stub;
  private static final Mock ACTION_MOCK = Mock.forType(TW_Action.class);
  private static final TW_Action ACTION_STUB = (TW_Action) ACTION_MOCK.stub;

  private static final TW_Executor executor = new TW_BeforeDeleteExecutor(CTX_STUB);

  /**
   * Ensures filteredRecords returns as expected
   */
  @IsTest
  static void filteredRecords() {
    Account oldAcc1 = new Account(Name = 'old one');
    Account oldAcc2 = new Account(Name = 'old two');
    List<SObject> oldRecs = new List<Account>{ oldAcc1, oldAcc2 };

    MethodSpy getOldSpy = CTX_MOCK.spyOn('getOld');
    getOldSpy.returns(oldRecs);

    MethodSpy filterSpy = ACTION_MOCK.spyOn('beforeDeleteFilter');
    filterSpy.returnsOnce(true);
    filterSpy.returnsOnce(false);

    Test.startTest();
    List<SObject> actual = executor.filteredRecords(ACTION_STUB);
    Test.stopTest();

    Expect.that(getOldSpy).hasBeenCalledTimes(1);
    Expect.that(filterSpy).hasBeenCalledTimes(2);
    Expect.that(filterSpy).hasBeenCalledWith(oldAcc1);
    Expect.that(filterSpy).hasBeenCalledWith(oldAcc2);

    System.Assert.areEqual(1, actual.size(), 'unexpected records returned');
    System.Assert.areEqual(oldAcc1, actual[0], 'unexpected records returned');
  }

  /**
   * Ensures execute runs as expected
   */
  @IsTest
  static void execute() {
    SObject triggerRec = new Account(Name = 'Triggered Account');

    MethodSpy primaryMethodSpy = ACTION_MOCK.spyOn('beforeDelete');

    Test.startTest();
    executor.execute(ACTION_STUB, triggerRec);
    Test.stopTest();

    Expect.that(primaryMethodSpy).hasBeenCalledTimes(1);
    Expect.that(primaryMethodSpy).hasBeenCalledWith(triggerRec);
  }
}
