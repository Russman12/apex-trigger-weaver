/**
 * Provides unit test coverage for TW_DefaultQuery
 */
@IsTest
public class TW_DefaultQueryTest {
  static {
    TW_ActionRegistry.clear();
  }

  private static final Mock SELECTOR_MOCK = Mock.forType(TW_DefaultQuerySelector.class);
  private static final TW_DefaultQuerySelector SELECTOR_STUB = (TW_DefaultQuerySelector) SELECTOR_MOCK.stub;

  /**
   * Ensures getSelector returns expected selector instance
   */
  @IsTest
  static void getSelector() {
    TW_DefaultQuery q = new TW_DefaultQuery(Account.getSObjectType());
    q.selector = SELECTOR_STUB;

    Test.startTest();
    TW_QuerySelector selector = q.getSelector();
    Test.stopTest();

    System.Assert.areEqual(SELECTOR_STUB, selector, 'selector not set as expected');
  }

  /**
   * Ensures run executes query as expected
   */
  @IsTest
  static void run() {
    //insert records
    List<Account> accs = new List<Account>{ new Account(Name = 'test1'), new Account(Name = 'test2'), new Account(Name = 'test3') };
    insert accs;

    MethodSpy toClauseStringSpy = SELECTOR_MOCK.spyOn('toClauseString');
    toClauseStringSpy.returns('SELECT Id, Name');

    TW_DefaultQuery q = new TW_DefaultQuery(Account.getSObjectType());
    q.selector = SELECTOR_STUB;

    Test.startTest();
    List<SObject> recs = q.run(new List<Account>{ accs[0], accs[1] });
    Test.stopTest();

    Expect.that(toClauseStringSpy).hasBeenCalledTimes(1);
    System.Assert.areEqual(new List<Account>{ accs[0], accs[1] }, recs, 'selector not set as expected');
  }
}
