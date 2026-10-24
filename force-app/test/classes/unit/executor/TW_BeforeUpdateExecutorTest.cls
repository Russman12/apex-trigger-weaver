/**
 * @description Provides test coverage for TW_BeforeUpdateExecutor
 */
@IsTest
public class TW_BeforeUpdateExecutorTest {
  private static final Mock CTX_MOCK = Mock.forType(TW_Context.class);
  private static final TW_Context CTX_STUB = (TW_Context) CTX_MOCK.stub;
  private static final Mock ACTION_MOCK = Mock.forType(TW_Action.class);
  private static final TW_Action ACTION_STUB = (TW_Action) ACTION_MOCK.stub;

  private static final TW_Executor executor = new TW_BeforeUpdateExecutor(CTX_STUB);

  /**
   * Ensures filteredRecords returns as expected
   */
  @IsTest
  static void filteredRecords() {
    Account oldAcc1 = new Account(Name = 'old one');
    Account oldAcc2 = new Account(Name = 'old two');
    List<SObject> oldRecs = new List<Account>{ oldAcc1, oldAcc2 };

    Account newAcc1 = new Account(Name = 'new one');
    Account newAcc2 = new Account(Name = 'new two');
    List<SObject> newRecs = new List<Account>{ newAcc1, newAcc2 };

    MethodSpy getNewSpy = CTX_MOCK.spyOn('getNew');
    getNewSpy.returns(newRecs);

    MethodSpy getOldRecSpy = CTX_MOCK.spyOn('getOld');
    getOldRecSpy.returnsOnce(oldAcc1);
    getOldRecSpy.returnsOnce(oldAcc2);

    MethodSpy filterSpy = ACTION_MOCK.spyOn('beforeUpdateFilter');
    filterSpy.returnsOnce(true);
    filterSpy.returnsOnce(false);

    Test.startTest();
    List<SObject> actual = executor.filteredRecords(ACTION_STUB);
    Test.stopTest();

    Expect.that(getNewSpy).hasBeenCalledTimes(1);
    Expect.that(getOldRecSpy).hasBeenCalledTimes(2);
    Expect.that(getOldRecSpy).hasBeenCalledWith(newAcc1);
    Expect.that(getOldRecSpy).hasBeenCalledWith(newAcc2);
    Expect.that(filterSpy).hasBeenCalledTimes(2);
    Expect.that(filterSpy).hasBeenCalledWith(oldAcc1, newAcc1);
    Expect.that(filterSpy).hasBeenCalledWith(oldAcc2, newAcc2);

    System.Assert.areEqual(1, actual.size(), 'unexpected records returned');
    System.Assert.areEqual(newAcc1, actual[0], 'unexpected records returned');
    System.Assert.areEqual(newAcc2, CTX_STUB.currentRecord, 'current record not set while filtering');
  }

  /**
   * Ensures execute runs as expected
   */
  @IsTest
  static void execute() {
    SObject triggerRec = new Account(Name = 'Triggered Account');
    SObject oldRec = new Account(Name = 'Old Account');

    MethodSpy getOldRecSpy = CTX_MOCK.spyOn('getOld');
    getOldRecSpy.returns(oldRec);

    MethodSpy primaryMethodSpy = ACTION_MOCK.spyOn('beforeUpdate');

    Test.startTest();
    executor.execute(ACTION_STUB, triggerRec);
    Test.stopTest();

    Expect.that(getOldRecSpy).hasBeenCalledTimes(1);
    Expect.that(getOldRecSpy).hasBeenCalledWith(triggerRec);
    Expect.that(primaryMethodSpy).hasBeenCalledTimes(1);
    Expect.that(primaryMethodSpy).hasBeenCalledWith(oldRec, triggerRec);
  }
}
