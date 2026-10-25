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

    MethodSpy execSpy = EXEC_MOCK.spyOn('execute');

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
    Expect.that(execSpy).hasBeenCalledTimes(4);
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

    MethodSpy execSpy = EXEC_MOCK.spyOn('execute');

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

    MethodSpy execSpy = EXEC_MOCK.spyOn('execute');

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler handler = new TW_Handler();
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;

    Test.startTest();
    handler.execute();
    Test.stopTest();

    Expect.that(execFilteredRecSpy).hasBeenCalledTimes(2);
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

  /**
   * Ensures newExtensions returns no extensions by default
   */
  @IsTest
  static void newExtensions() {
    TW_Handler handler = new TW_Handler();

    Test.startTest();
    List<System.Type> exts = handler.newExtensions();
    Test.stopTest();

    System.Assert.isTrue(exts.isEmpty(), 'unexpected default extensions returned');
  }

  /**
   * Ensures addExtension creates and registers a new instance of the extension type
   */
  @IsTest
  static void addExtensionType() {
    TW_Handler handler = new TW_Handler();

    Test.startTest();
    TW_Handler result = handler.addExtension(RecordingExtension.class);
    Test.stopTest();

    System.Assert.areEqual(handler, result, 'handler not returned');
    System.Assert.areEqual(1, handler.extensions.size(), 'extension not registered');
    System.Assert.isInstanceOfType(handler.extensions[0], RecordingExtension.class, 'unexpected extension registered');
    System.Assert.areEqual(
      handler.extensions[0],
      handler.extensionsByType.get(RecordingExtension.class),
      'extension not registered under its type'
    );
  }

  /**
   * Ensures addExtension registers instances in order under their types and returns the handler
   */
  @IsTest
  static void addExtensionInstance() {
    TW_Handler handler = new TW_Handler();
    TW_Extension ext1 = new RecordingExtension();
    TW_Extension ext2 = new OtherExtension();

    Test.startTest();
    TW_Handler result = handler.addExtension(RecordingExtension.class, ext1).addExtension(OtherExtension.class, ext2);
    Test.stopTest();

    System.Assert.areEqual(handler, result, 'handler not returned');
    System.Assert.areEqual(new List<TW_Extension>{ ext1, ext2 }, handler.extensions, 'extensions not registered in order');
    System.Assert.areEqual(ext1, handler.extensionsByType.get(RecordingExtension.class), 'extension not registered under its type');
    System.Assert.areEqual(ext2, handler.extensionsByType.get(OtherExtension.class), 'extension not registered under its type');
  }

  /**
   * Ensures addExtension throws when the type is already registered
   */
  @IsTest
  static void addExtensionDuplicate() {
    TW_Handler handler = new TW_Handler();
    handler.addExtension(RecordingExtension.class);

    Test.startTest();
    try {
      handler.addExtension(RecordingExtension.class);
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_Handler.InvalidExtensionException.class, 'unexpected exception thrown');
    }
    Test.stopTest();

    System.Assert.areEqual(1, handler.extensions.size(), 'duplicate extension registered');
  }

  /**
   * Ensures execute makes registered extensions available through the context
   */
  @IsTest
  static void executeSetsContextExtensions() {
    EXEC_FACTORY_MOCK.spyOn('make').returns(EXEC_STUB);
    ACTION_REG_MOCK.spyOn('activeActions').returns(new List<System.Type>{ MyAction1.class });
    EXEC_MOCK.spyOn('filteredRecords').returns(new List<SObject>());
    MethodSpy setExtensionsSpy = CTX_MOCK.spyOn('setExtensions');

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler handler = new TW_Handler();
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;
    handler.addExtension(RecordingExtension.class);

    Test.startTest();
    handler.execute();
    Test.stopTest();

    Expect.that(setExtensionsSpy).hasBeenCalledWith(handler.extensionsByType);
  }

  /**
   * Ensures execute invokes extension hooks in lifecycle order
   */
  @IsTest
  static void executeExtensionHooks() {
    List<System.Type> actions = new List<System.Type>{ MyAction1.class, MyAction2.class };
    List<SObject> filteredRecs = new List<SObject>{ new Account(Name = 'acc1') };

    EXEC_FACTORY_MOCK.spyOn('make').returns(EXEC_STUB);
    ACTION_REG_MOCK.spyOn('activeActions').returns(actions);
    MethodSpy execFilteredRecSpy = EXEC_MOCK.spyOn('filteredRecords');
    execFilteredRecSpy.returns(filteredRecs);
    execFilteredRecSpy.returnsOnce(new List<SObject>());
    EXEC_MOCK.spyOn('execute');

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler handler = new TW_Handler();
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;
    RecordingExtension ext = new RecordingExtension();
    handler.addExtension(RecordingExtension.class, ext);

    Test.startTest();
    handler.execute();
    Test.stopTest();

    System.Assert.areEqual(
      new List<String>{ 'onStart:2', 'onActionSetup:1', 'beforeExecute', 'afterExecute', 'onFinish' },
      ext.calls,
      'hooks not invoked as expected'
    );
  }

  /**
   * Ensures execute notifies extensions of errors and rethrows
   */
  @IsTest
  static void executeExtensionError() {
    List<System.Type> actions = new List<System.Type>{ MyAction1.class };
    List<SObject> filteredRecs = new List<SObject>{ new Account(Name = 'acc1') };
    MyException expected = new MyException('boom');

    EXEC_FACTORY_MOCK.spyOn('make').returns(EXEC_STUB);
    ACTION_REG_MOCK.spyOn('activeActions').returns(actions);
    EXEC_MOCK.spyOn('filteredRecords').returns(filteredRecs);
    EXEC_MOCK.spyOn('execute').throwsException(expected);

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler handler = new TW_Handler();
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;
    RecordingExtension ext = new RecordingExtension();
    handler.addExtension(RecordingExtension.class, ext);

    Test.startTest();
    try {
      handler.execute();
      System.Assert.fail('expected exception not thrown');
    } catch (MyException e) {
      System.Assert.areEqual(expected, e, 'unexpected exception thrown');
    }
    Test.stopTest();

    System.Assert.areEqual(
      new List<String>{ 'onStart:1', 'onActionSetup:1', 'beforeExecute', 'onError:boom', 'onFinish' },
      ext.calls,
      'hooks not invoked as expected'
    );
  }

  /**
   * Ensures extension hooks are not invoked when there are no actions
   */
  @IsTest
  static void executeExtensionNoActions() {
    ACTION_REG_MOCK.spyOn('activeActions').returns(new List<System.Type>{});

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler handler = new TW_Handler();
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;
    RecordingExtension ext = new RecordingExtension();
    handler.addExtension(RecordingExtension.class, ext);

    Test.startTest();
    handler.execute();
    Test.stopTest();

    System.Assert.isTrue(ext.calls.isEmpty(), 'hooks should not be invoked');
  }

  private class MyAction1 extends TW_Action {
  }

  private class MyAction2 extends TW_Action {
  }

  private class RecordingExtension extends TW_Extension {
    public List<String> calls = new List<String>();

    public override void onStart(TW_Context ctx, List<TW_Action> actions) {
      calls.add('onStart:' + actions.size());
    }
    public override void onActionSetup(TW_Context ctx, TW_Action action, List<SObject> records) {
      calls.add('onActionSetup:' + records.size());
    }
    public override void beforeExecute(TW_Context ctx) {
      calls.add('beforeExecute');
    }
    public override void afterExecute(TW_Context ctx) {
      calls.add('afterExecute');
    }
    public override void onError(TW_Context ctx, Exception e) {
      calls.add('onError:' + e.getMessage());
    }
    public override void onFinish(TW_Context ctx) {
      calls.add('onFinish');
    }
  }

  private class OtherExtension extends TW_Extension {
  }

  private class MyException extends Exception {
  }
}
