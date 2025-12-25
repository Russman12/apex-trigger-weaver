/**
 * @description Provides test coverage for TW_ExecutorFactory
 */
@IsTest
public class TW_ExecutorFactoryTest {
  private static final Mock CTX_MOCK = Mock.forType(TW_Context.class);
  private static final TW_Context CTX_STUB = (TW_Context) CTX_MOCK.stub;

  private static final MethodSpy getOperationSpy = CTX_MOCK.spyOn('getOperation');

  /**
   * Ensures correct TW_Executor is returned for each trigger operation
   */
  @IsTest
  static void make() {
    Map<TriggerOperation, System.Type> expectedTypes = new Map<TriggerOperation, System.Type>{
      TriggerOperation.BEFORE_INSERT => TW_BeforeInsertExecutor.class,
      TriggerOperation.AFTER_INSERT => TW_AfterInsertExecutor.class,
      TriggerOperation.BEFORE_UPDATE => TW_BeforeUpdateExecutor.class,
      TriggerOperation.AFTER_UPDATE => TW_AfterUpdateExecutor.class,
      TriggerOperation.BEFORE_DELETE => TW_BeforeDeleteExecutor.class,
      TriggerOperation.AFTER_DELETE => TW_AfterDeleteExecutor.class,
      TriggerOperation.AFTER_UNDELETE => TW_AfterUndeleteExecutor.class
    };

    Test.startTest();
    for (TriggerOperation op : expectedTypes.keySet()) {
      verifyType(op, expectedTypes.get(op));
    }
    Test.stopTest();
  }

  private static void verifyType(TriggerOperation op, System.Type expectedType) {
    getOperationSpy.returnsOnce(op);

    TW_ExecutorFactory factory = new TW_ExecutorFactory(CTX_STUB);
    TW_Executor executor = factory.make();

    System.Assert.isInstanceOfType(executor, expectedType, 'Unexpected executor returned');
  }
}
