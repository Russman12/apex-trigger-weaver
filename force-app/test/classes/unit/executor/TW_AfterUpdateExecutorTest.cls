/**
 * @description Provides test coverage for TW_AfterUpdateExecutor
 */
@IsTest
public class TW_AfterUpdateExecutorTest {
  private static final Mock CTX_MOCK = Mock.forType(TW_Context.class);
  private static final TW_Context CTX_STUB = (TW_Context) CTX_MOCK.stub;
  private static final Mock ACTION_MOCK = Mock.forType(TW_Action.class);
  private static final TW_Action ACTION_STUB = (TW_Action) ACTION_MOCK.stub;
  private static final Mock QUERY_MOCK = Mock.forType(TW_Query.class);
  private static final TW_Query QUERY_STUB = (TW_Query) QUERY_MOCK.stub;
  private static final Mock SELECTOR_MOCK = Mock.forType(TW_QuerySelector.class);
  private static final TW_QuerySelector SELECTOR_STUB = (TW_QuerySelector) SELECTOR_MOCK.stub;

  private static final TW_Executor executor = new TW_AfterUpdateExecutor(CTX_STUB);

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

    MethodSpy filterSpy = ACTION_MOCK.spyOn('afterUpdateFilter');
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
  }

  /**
   * Ensures setup executes as expected
   */
  @IsTest
  static void setup() {
    MethodSpy getQuerySpy = CTX_MOCK.spyOn('getQuery');
    getQuerySpy.returns(QUERY_STUB);

    MethodSpy getSelectorSpy = QUERY_MOCK.spyOn('getSelector');
    getSelectorSpy.returns(SELECTOR_STUB);

    MethodSpy setupSpy = ACTION_MOCK.spyOn('afterUpdateSetup');

    Test.startTest();
    executor.setup(ACTION_STUB);
    Test.stopTest();

    Expect.that(getQuerySpy).hasBeenCalledTimes(1);
    Expect.that(getSelectorSpy).hasBeenCalledTimes(1);
    Expect.that(setupSpy).hasBeenCalledTimes(1);
  }

  /**
   * Ensures runQuery executes as expected
   */
  @IsTest
  static void runQuery() {
    List<SObject> queryRes = new List<SObject>{ new Account(Id = '001000000000001', Name = 'queried acc') };
    List<SObject> newRecs = new List<SObject>{ new Account(Id = '001000000000001', Name = 'new acc') };

    MethodSpy getQuerySpy = CTX_MOCK.spyOn('getQuery');
    getQuerySpy.returns(QUERY_STUB);

    MethodSpy getSelectorSpy = QUERY_MOCK.spyOn('getSelector');
    getSelectorSpy.returns(SELECTOR_STUB);

    MethodSpy isSetSpy = SELECTOR_MOCK.spyOn('isSet');
    isSetSpy.returns(true);

    MethodSpy queryRunSpy = QUERY_MOCK.spyOn('run');
    queryRunSpy.returns(queryRes);

    MethodSpy getNewSpy = CTX_MOCK.spyOn('getNew');
    getNewSpy.returns(newRecs);

    Test.startTest();
    executor.runQuery();
    Test.stopTest();

    Expect.that(getQuerySpy).hasBeenCalledTimes(1);
    Expect.that(getSelectorSpy).hasBeenCalledTimes(1);
    Expect.that(isSetSpy).hasBeenCalledTimes(1);
    Expect.that(queryRunSpy).hasBeenCalledTimes(1);
    Expect.that(queryRunSpy).hasBeenCalledWith(newRecs);
    Expect.that(getNewSpy).hasBeenCalledTimes(1);
    System.Assert.areEqual(new Map<Id, SObject>(queryRes), CTX_STUB.queriedRecords, 'unexpected results assigned');
  }

  /**
   * Ensures runQuery does not execute query if selection is unset
   */
  @IsTest
  static void runQueryUnset() {
    MethodSpy getQuerySpy = CTX_MOCK.spyOn('getQuery');
    getQuerySpy.returns(QUERY_STUB);

    MethodSpy getSelectorSpy = QUERY_MOCK.spyOn('getSelector');
    getSelectorSpy.returns(SELECTOR_STUB);

    MethodSpy isSetSpy = SELECTOR_MOCK.spyOn('isSet');
    isSetSpy.returns(false);

    Test.startTest();
    executor.runQuery();
    Test.stopTest();

    Expect.that(getQuerySpy).hasBeenCalledTimes(1);
    Expect.that(getSelectorSpy).hasBeenCalledTimes(1);
    Expect.that(isSetSpy).hasBeenCalledTimes(1);
    System.Assert.areEqual(null, CTX_STUB.queriedRecords, 'unexpected results assigned');
  }

  /**
   * Ensures execute runs as expected
   */
  @IsTest
  static void execute() {
    SObject triggerRec = new Account(Name = 'Triggered Account');
    SObject oldRec = new Account(Name = 'Old Account');
    SObject queriedRec = new Account(Name = 'Queried Account');

    MethodSpy getOldRecSpy = CTX_MOCK.spyOn('getOld');
    getOldRecSpy.returns(oldRec);

    MethodSpy getQueriedRecSpy = CTX_MOCK.spyOn('getQueriedRecord');
    getQueriedRecSpy.returns(queriedRec);

    MethodSpy primaryMethodSpy = ACTION_MOCK.spyOn('afterUpdate');

    Test.startTest();
    executor.execute(ACTION_STUB, triggerRec);
    Test.stopTest();

    Expect.that(getOldRecSpy).hasBeenCalledTimes(1);
    Expect.that(getOldRecSpy).hasBeenCalledWith(triggerRec);
    Expect.that(getQueriedRecSpy).hasBeenCalledTimes(1);
    Expect.that(getQueriedRecSpy).hasBeenCalledWith(triggerRec);
    Expect.that(primaryMethodSpy).hasBeenCalledTimes(1);
    Expect.that(primaryMethodSpy).hasBeenCalledWith(oldRec, triggerRec, queriedRec);
  }
}
