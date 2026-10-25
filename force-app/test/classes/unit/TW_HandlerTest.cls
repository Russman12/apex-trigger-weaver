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
   * Ensures newPlugins returns no plugins by default
   */
  @IsTest
  static void newPlugins() {
    TW_Handler handler = new TW_Handler();

    Test.startTest();
    List<System.Type> plugins = handler.newPlugins();
    Test.stopTest();

    System.Assert.isTrue(plugins.isEmpty(), 'unexpected default plugins returned');
  }

  /**
   * Ensures addPlugin creates and registers a new instance of the plugin type
   */
  @IsTest
  static void addPluginType() {
    TW_Handler handler = new TW_Handler();

    Test.startTest();
    TW_Handler result = handler.addPlugin(RecordingPlugin.class);
    Test.stopTest();

    System.Assert.areEqual(handler, result, 'handler not returned');
    System.Assert.areEqual(1, handler.plugins.size(), 'plugin not registered');
    System.Assert.isInstanceOfType(handler.plugins[0], RecordingPlugin.class, 'unexpected plugin registered');
    System.Assert.areEqual(
      handler.plugins[0],
      handler.pluginsByType.get(RecordingPlugin.class),
      'plugin not registered under its type'
    );
  }

  /**
   * Ensures addPlugin registers instances in order under their types and returns the handler
   */
  @IsTest
  static void addPluginInstance() {
    TW_Handler handler = new TW_Handler();
    TW_Plugin plugin1 = new RecordingPlugin();
    TW_Plugin plugin2 = new OtherPlugin();

    Test.startTest();
    TW_Handler result = handler.addPlugin(RecordingPlugin.class, plugin1).addPlugin(OtherPlugin.class, plugin2);
    Test.stopTest();

    System.Assert.areEqual(handler, result, 'handler not returned');
    System.Assert.areEqual(new List<TW_Plugin>{ plugin1, plugin2 }, handler.plugins, 'plugins not registered in order');
    System.Assert.areEqual(plugin1, handler.pluginsByType.get(RecordingPlugin.class), 'plugin not registered under its type');
    System.Assert.areEqual(plugin2, handler.pluginsByType.get(OtherPlugin.class), 'plugin not registered under its type');
  }

  /**
   * Ensures addPlugin throws when the type is already registered
   */
  @IsTest
  static void addPluginDuplicate() {
    TW_Handler handler = new TW_Handler();
    handler.addPlugin(RecordingPlugin.class);

    Test.startTest();
    try {
      handler.addPlugin(RecordingPlugin.class);
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_Handler.InvalidPluginException.class, 'unexpected exception thrown');
    }
    Test.stopTest();

    System.Assert.areEqual(1, handler.plugins.size(), 'duplicate plugin registered');
  }

  /**
   * Ensures execute makes registered plugins available through the context
   */
  @IsTest
  static void executeSetsContextPlugins() {
    EXEC_FACTORY_MOCK.spyOn('make').returns(EXEC_STUB);
    ACTION_REG_MOCK.spyOn('activeActions').returns(new List<System.Type>{ MyAction1.class });
    EXEC_MOCK.spyOn('filteredRecords').returns(new List<SObject>());
    MethodSpy setPluginsSpy = CTX_MOCK.spyOn('setPlugins');

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler handler = new TW_Handler();
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;
    handler.addPlugin(RecordingPlugin.class);

    Test.startTest();
    handler.execute();
    Test.stopTest();

    Expect.that(setPluginsSpy).hasBeenCalledWith(handler.pluginsByType);
  }

  /**
   * Ensures execute invokes plugin hooks in lifecycle order
   */
  @IsTest
  static void executePluginHooks() {
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
    RecordingPlugin plugin = new RecordingPlugin();
    handler.addPlugin(RecordingPlugin.class, plugin);

    Test.startTest();
    handler.execute();
    Test.stopTest();

    System.Assert.areEqual(
      new List<String>{ 'onStart:2', 'onActionSetup:1', 'beforeExecute', 'afterExecute', 'onFinish' },
      plugin.calls,
      'hooks not invoked as expected'
    );
  }

  /**
   * Ensures execute notifies plugins of errors and rethrows
   */
  @IsTest
  static void executePluginError() {
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
    RecordingPlugin plugin = new RecordingPlugin();
    handler.addPlugin(RecordingPlugin.class, plugin);

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
      plugin.calls,
      'hooks not invoked as expected'
    );
  }

  /**
   * Ensures plugin hooks are not invoked when there are no actions
   */
  @IsTest
  static void executePluginNoActions() {
    ACTION_REG_MOCK.spyOn('activeActions').returns(new List<System.Type>{});

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler handler = new TW_Handler();
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;
    RecordingPlugin plugin = new RecordingPlugin();
    handler.addPlugin(RecordingPlugin.class, plugin);

    Test.startTest();
    handler.execute();
    Test.stopTest();

    System.Assert.isTrue(plugin.calls.isEmpty(), 'hooks should not be invoked');
  }

  private class MyAction1 extends TW_Action {
  }

  private class MyAction2 extends TW_Action {
  }

  private class RecordingPlugin extends TW_Plugin {
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

  private class OtherPlugin extends TW_Plugin {
  }

  private class MyException extends Exception {
  }
}
