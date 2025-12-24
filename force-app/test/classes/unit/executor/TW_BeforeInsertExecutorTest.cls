/**
 * @description Provides test coverage for TW_BeforeInsertExecutor
 */
@IsTest
public class TW_BeforeInsertExecutorTest {
  private static final Mock CTX_MOCK = Mock.forType(TW_Context.class);
  private static final TW_Context CTX_STUB = (TW_Context) CTX_MOCK.stub;
  private static final Mock ACTION_MOCK = Mock.forType(TW_Action.class);
  private static final TW_Action ACTION_STUB = (TW_Action) ACTION_MOCK.stub;
  private static final Mock QUERY_MOCK = Mock.forType(TW_Query.class);
  private static final TW_Query QUERY_STUB = (TW_Query) QUERY_MOCK.stub;
  private static final Mock SELECTOR_MOCK = Mock.forType(TW_QuerySelector.class);
  private static final TW_QuerySelector SELECTOR_STUB = (TW_QuerySelector) SELECTOR_MOCK.stub;

  /**
   * Ensures filteredRecords returns as expected
   */
  @IsTest
  static void filteredRecords() {
    TW_Executor executor = new TW_BeforeInsertExecutor(CTX_STUB);

    Account newAcc1 = new Account(Name = 'new one');
    Account newAcc2 = new Account(Name = 'new two');
    List<SObject> newRecs = new List<Account>{ newAcc1, newAcc2 };

    MethodSpy getNewSpy = CTX_MOCK.spyOn('getNew');
    getNewSpy.returns(newRecs);

    MethodSpy filterSpy = ACTION_MOCK.spyOn('beforeInsertFilter');
    filterSpy.returnsOnce(true);
    filterSpy.returnsOnce(false);

    Test.startTest();
    List<SObject> actual = executor.filteredRecords(ACTION_STUB);
    Test.stopTest();

    Expect.that(getNewSpy).hasBeenCalledTimes(1);
    Expect.that(filterSpy).hasBeenCalledTimes(2);
    Expect.that(filterSpy).hasBeenCalledWith(newAcc1);
    Expect.that(filterSpy).hasBeenCalledWith(newAcc2);

    System.Assert.areEqual(1, actual.size(), 'unexpected records returned');
    System.Assert.areEqual(newAcc1, actual[0], 'unexpected records returned');
  }

  /**
   * Ensures setup executes as expected
   */
  @IsTest
  static void setup() {
    TW_Executor executor = new TW_BeforeInsertExecutor(CTX_STUB);

    MethodSpy setupSpy = ACTION_MOCK.spyOn('beforeInsertSetup');

    Test.startTest();
    executor.setup(ACTION_STUB);
    Test.stopTest();

    Expect.that(setupSpy).hasBeenCalledTimes(1);
  }

  /**
   * Ensures execute runs as expected
   */
  @IsTest
  static void execute() {
    TW_Executor executor = new TW_BeforeInsertExecutor(CTX_STUB);

    SObject triggerRec = new Account(Name = 'Triggered Account');

    MethodSpy primaryMethodSpy = ACTION_MOCK.spyOn('beforeInsert');

    Test.startTest();
    executor.execute(ACTION_STUB, triggerRec);
    Test.stopTest();

    Expect.that(primaryMethodSpy).hasBeenCalledTimes(1);
    Expect.that(primaryMethodSpy).hasBeenCalledWith(triggerRec);
  }
}
