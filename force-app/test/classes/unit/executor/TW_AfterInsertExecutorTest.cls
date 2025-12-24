/**
 * @description Provides test coverage for TW_AfterInsertExecutor
 */
@IsTest
public class TW_AfterInsertExecutorTest {
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
    TW_Executor executor = new TW_AfterInsertExecutor(CTX_STUB);

    Account acc1 = new Account(Name = 'one');
    Account acc2 = new Account(Name = 'two');
    List<SObject> recs = new List<Account>{ acc1, acc2 };

    MethodSpy getRecSpy = CTX_MOCK.spyOn('getNew');
    getRecSpy.returns(recs);

    MethodSpy filterSpy = ACTION_MOCK.spyOn('afterInsertFilter');
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
   * Ensures setup executes as expected
   */
  @IsTest
  static void setup() {
    TW_Executor executor = new TW_AfterInsertExecutor(CTX_STUB);

    MethodSpy getQuerySpy = CTX_MOCK.spyOn('getQuery');
    getQuerySpy.returns(QUERY_STUB);

    MethodSpy getSelectorSpy = QUERY_MOCK.spyOn('getSelector');
    getSelectorSpy.returns(SELECTOR_STUB);

    MethodSpy setupSpy = ACTION_MOCK.spyOn('afterInsertSetup');

    Test.startTest();
    executor.setup(ACTION_STUB);
    Test.stopTest();

    Expect.that(getQuerySpy).hasBeenCalledTimes(1);
    Expect.that(getSelectorSpy).hasBeenCalledTimes(1);
    Expect.that(setupSpy).hasBeenCalledTimes(1);
  }

  /**
   * Ensures execute runs as expected
   */
  @IsTest
  static void execute() {
    TW_Executor executor = new TW_AfterInsertExecutor(CTX_STUB);

    SObject triggerRec = new Account(Name = 'Triggered Account');
    SObject oldRec = new Account(Name = 'Old Account');

    MethodSpy getOldRecSpy = CTX_MOCK.spyOn('getOld');
    getOldRecSpy.returns(oldRec);

    MethodSpy primaryMethodSpy = ACTION_MOCK.spyOn('afterInsert');

    Test.startTest();
    executor.execute(ACTION_STUB, triggerRec);
    Test.stopTest();

    Expect.that(getOldRecSpy).hasBeenCalledTimes(1);
    Expect.that(getOldRecSpy).hasBeenCalledWith(triggerRec);
    Expect.that(primaryMethodSpy).hasBeenCalledTimes(1);
    Expect.that(primaryMethodSpy).hasBeenCalledWith(oldRec, triggerRec);
  }
}
