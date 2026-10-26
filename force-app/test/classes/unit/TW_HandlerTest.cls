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
      TW_Handler handler = new TW_Handler();
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_Handler.InvalidContextException.class, 'unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures the SObject type comes from the new records, or the old records when there are none
   */
  @IsTest
  static void sObjectTypeOf() {
    List<SObject> accounts = new List<SObject>{ new Account(Name = 'acc1') };
    List<SObject> contacts = new List<SObject>{ new Contact(LastName = 'con1') };

    Test.startTest();
    Schema.SObjectType fromNew = TW_Handler.sObjectTypeOf(accounts, contacts);
    Schema.SObjectType fromOld = TW_Handler.sObjectTypeOf(null, contacts);
    Test.stopTest();

    System.Assert.areEqual(Account.SObjectType, fromNew, 'type not taken from the new records');
    System.Assert.areEqual(Contact.SObjectType, fromOld, 'type not taken from the old records');
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
    TW_Handler handler = new TW_Handler(Account.SObjectType);
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
    TW_Handler handler = new TW_Handler(Account.SObjectType);
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
    TW_Handler handler = new TW_Handler(Account.SObjectType);
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
    TW_Handler handler = new TW_Handler(Account.SObjectType);
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
    TW_Handler handler = new TW_Handler(Account.SObjectType);
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;

    Test.startTest();
    handler.execute();
    Test.stopTest();
  }

  /**
   * Ensures registerPlugins creates an instance of each registry plugin in order under its type
   */
  @IsTest
  static void registerPlugins() {
    Test.startTest();
    TW_Handler handler = handlerWithPlugins(new List<System.Type>{ RecordingPlugin.class, OtherPlugin.class });
    Test.stopTest();

    System.Assert.areEqual(2, handler.plugins.size(), 'registry plugins not registered');
    System.Assert.isInstanceOfType(handler.plugins[0], RecordingPlugin.class, 'plugins not registered in order');
    System.Assert.isInstanceOfType(handler.plugins[1], OtherPlugin.class, 'plugins not registered in order');
    System.Assert.areEqual(
      handler.plugins[0],
      handler.pluginsByType.get(RecordingPlugin.class),
      'plugin not registered under its type'
    );
    System.Assert.areEqual(handler.plugins[1], handler.pluginsByType.get(OtherPlugin.class), 'plugin not registered under its type');
  }

  /**
   * Ensures registerPlugins registers nothing when no registry exists
   */
  @IsTest
  static void registerPluginsNoRegistry() {
    TW_Handler.pluginRegistry = null;
    TW_Handler.pluginRegistryLoaded = true;
    TW_Handler handler = new TW_Handler(Account.SObjectType);

    Test.startTest();
    handler.registerPlugins();
    Test.stopTest();

    System.Assert.isTrue(handler.plugins.isEmpty(), 'unexpected plugins registered');
  }

  /**
   * Ensures registerPlugins registers nothing when the registry returns null
   */
  @IsTest
  static void registerPluginsNullPlugins() {
    Test.startTest();
    TW_Handler handler = handlerWithPlugins(null);
    Test.stopTest();

    System.Assert.isTrue(handler.plugins.isEmpty(), 'unexpected plugins registered');
  }

  /**
   * Ensures registerPlugins throws when the registry lists a type that does not implement TW_Plugin.Plugin
   */
  @IsTest
  static void registerPluginsNotPlugin() {
    Test.startTest();
    try {
      handlerWithPlugins(new List<System.Type>{ MyAction1.class });
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_Handler.InvalidPluginException.class, 'unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures registerPlugins throws when the registry lists a type more than once
   */
  @IsTest
  static void registerPluginsDuplicate() {
    Test.startTest();
    try {
      handlerWithPlugins(new List<System.Type>{ RecordingPlugin.class, RecordingPlugin.class });
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_Handler.InvalidPluginException.class, 'unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures loadPluginRegistry creates the registry class by name and caches it
   */
  @IsTest
  static void loadPluginRegistry() {
    TW_Handler.pluginRegistryName = TestRegistry.class.getName();

    Test.startTest();
    TW_Plugin.Registry registry = TW_Handler.loadPluginRegistry();
    TW_Handler.pluginRegistryName = 'TW_DoesNotExist';
    TW_Plugin.Registry cached = TW_Handler.loadPluginRegistry();
    Test.stopTest();

    System.Assert.isInstanceOfType(registry, TestRegistry.class, 'unexpected registry loaded');
    System.Assert.areEqual(registry, cached, 'registry not cached');
  }

  /**
   * Ensures loadPluginRegistry returns null when no registry class exists
   */
  @IsTest
  static void loadPluginRegistryMissing() {
    TW_Handler.pluginRegistryName = 'TW_DoesNotExist';

    Test.startTest();
    TW_Plugin.Registry registry = TW_Handler.loadPluginRegistry();
    Test.stopTest();

    System.Assert.isNull(registry, 'unexpected registry loaded');
    System.Assert.isTrue(TW_Handler.pluginRegistryLoaded, 'missing registry not cached');
  }

  /**
   * Ensures loadPluginRegistry throws when the registry class does not implement TW_Plugin.Registry
   */
  @IsTest
  static void loadPluginRegistryInvalid() {
    TW_Handler.pluginRegistryName = NotARegistry.class.getName();

    Test.startTest();
    try {
      TW_Handler.loadPluginRegistry();
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_Handler.InvalidPluginException.class, 'unexpected exception thrown');
    }
    Test.stopTest();
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
    TW_Handler handler = handlerWithPlugins(new List<System.Type>{ RecordingPlugin.class });
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;
    RecordingPlugin plugin = (RecordingPlugin) handler.plugins[0];

    Test.startTest();
    handler.execute();
    Test.stopTest();

    System.Assert.areEqual(
      new List<String>{ 'onInit', 'onStart:2', 'onActionSetup:1', 'beforeExecute', 'afterExecute', 'onFinish' },
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
    TW_Handler handler = handlerWithPlugins(new List<System.Type>{ RecordingPlugin.class });
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;
    RecordingPlugin plugin = (RecordingPlugin) handler.plugins[0];

    Test.startTest();
    try {
      handler.execute();
      System.Assert.fail('expected exception not thrown');
    } catch (MyException e) {
      System.Assert.areEqual(expected, e, 'unexpected exception thrown');
    }
    Test.stopTest();

    System.Assert.areEqual(
      new List<String>{ 'onInit', 'onStart:1', 'onActionSetup:1', 'beforeExecute', 'onError:boom', 'onFinish' },
      plugin.calls,
      'hooks not invoked as expected'
    );
  }

  /**
   * Ensures execute only invokes the hooks a plugin implements
   */
  @IsTest
  static void executePartialPluginHooks() {
    List<System.Type> actions = new List<System.Type>{ MyAction1.class };
    List<SObject> filteredRecs = new List<SObject>{ new Account(Name = 'acc1') };

    EXEC_FACTORY_MOCK.spyOn('make').returns(EXEC_STUB);
    ACTION_REG_MOCK.spyOn('activeActions').returns(actions);
    EXEC_MOCK.spyOn('filteredRecords').returns(filteredRecs);
    EXEC_MOCK.spyOn('execute');

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler handler = handlerWithPlugins(new List<System.Type>{ OtherPlugin.class, AfterExecutePlugin.class });
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;
    AfterExecutePlugin plugin = (AfterExecutePlugin) handler.plugins[1];

    Test.startTest();
    handler.execute();
    Test.stopTest();

    System.Assert.areEqual(new List<String>{ 'afterExecute' }, plugin.calls, 'hooks not invoked as expected');
  }

  /**
   * Ensures only the OnInit hooks are invoked when there are no actions
   */
  @IsTest
  static void executePluginNoActions() {
    ACTION_REG_MOCK.spyOn('activeActions').returns(new List<System.Type>{});

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler handler = handlerWithPlugins(new List<System.Type>{ RecordingPlugin.class });
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;
    RecordingPlugin plugin = (RecordingPlugin) handler.plugins[0];

    Test.startTest();
    handler.execute();
    Test.stopTest();

    System.Assert.areEqual(new List<String>{ 'onInit' }, plugin.calls, 'only onInit should be invoked');
  }

  /**
   * Ensures OnInit hooks run before the actions are resolved, so a bypass added there applies to
   * the same execution, and receive the execution's context
   */
  @IsTest
  static void executeOnInitBeforeActions() {
    List<SObject> filteredRecs = new List<SObject>{ new Account(Name = 'acc1') };

    EXEC_FACTORY_MOCK.spyOn('make').returns(EXEC_STUB);
    ACTION_REG_MOCK.spyOn('activeActions').returns(new List<System.Type>{ MyAction1.class, MyAction2.class });
    EXEC_MOCK.spyOn('filteredRecords').returns(filteredRecs);
    MethodSpy execSpy = EXEC_MOCK.spyOn('execute');

    TW_Handler.actionRegistry = ACTION_REG_STUB;
    TW_Handler handler = handlerWithPlugins(new List<System.Type>{ BypassingInitPlugin.class, RecordingPlugin.class });
    handler.ctx = CTX_STUB;
    handler.executorFactory = EXEC_FACTORY_STUB;
    BypassingInitPlugin initPlugin = (BypassingInitPlugin) handler.plugins[0];
    RecordingPlugin plugin = (RecordingPlugin) handler.plugins[1];

    Test.startTest();
    handler.execute();
    Test.stopTest();

    System.Assert.areEqual(CTX_STUB, initPlugin.initCtx, 'onInit not given the execution context');
    System.Assert.areEqual(
      new List<String>{ 'onInit', 'onStart:1' },
      new List<String>{ plugin.calls[0], plugin.calls[1] },
      'onInit not run first'
    );
    Expect.that(execSpy).hasBeenCalledTimes(1);
  }

  /**
   * Ensures isBypassed reports whether an action is bypassed
   */
  @IsTest
  static void isBypassed() {
    TW_Handler.addBypass(MyAction1.class);

    Test.startTest();
    Boolean bypassed = TW_Handler.isBypassed(MyAction1.class);
    Boolean notBypassed = TW_Handler.isBypassed(MyAction2.class);
    Test.stopTest();

    System.Assert.isTrue(bypassed, 'bypassed action not reported');
    System.Assert.isFalse(notBypassed, 'action reported as bypassed');
  }

  private static TW_Handler handlerWithPlugins(List<System.Type> pluginTypes) {
    TW_Handler.pluginRegistry = new TestRegistry(pluginTypes);
    TW_Handler.pluginRegistryLoaded = true;
    TW_Handler handler = new TW_Handler(Account.SObjectType);
    handler.registerPlugins();
    return handler;
  }

  private class MyAction1 extends TW_Action {
  }

  private class MyAction2 extends TW_Action {
  }

  // Bypasses MyAction1 when the execution starts
  private class BypassingInitPlugin implements TW_Plugin.OnInit {
    public TW_Context initCtx;

    public void onInit(TW_Context ctx) {
      initCtx = ctx;
      TW_Handler.addBypass(MyAction1.class);
    }
  }

  private class RecordingPlugin implements TW_Plugin.OnInit, TW_Plugin.OnStart, TW_Plugin.OnActionSetup, TW_Plugin.BeforeExecute, TW_Plugin.AfterExecute, TW_Plugin.OnError, TW_Plugin.OnFinish {
    public List<String> calls = new List<String>();

    public void onInit(TW_Context ctx) {
      calls.add('onInit');
    }
    public void onStart(TW_Context ctx, List<TW_Action> actions) {
      calls.add('onStart:' + actions.size());
    }
    public void onActionSetup(TW_Context ctx, TW_Action action, List<SObject> records) {
      calls.add('onActionSetup:' + records.size());
    }
    public void beforeExecute(TW_Context ctx) {
      calls.add('beforeExecute');
    }
    public void afterExecute(TW_Context ctx) {
      calls.add('afterExecute');
    }
    public void onError(TW_Context ctx, Exception e) {
      calls.add('onError:' + e.getMessage());
    }
    public void onFinish(TW_Context ctx) {
      calls.add('onFinish');
    }
  }

  private class AfterExecutePlugin implements TW_Plugin.AfterExecute {
    public List<String> calls = new List<String>();

    public void afterExecute(TW_Context ctx) {
      calls.add('afterExecute');
    }
  }

  private class OtherPlugin implements TW_Plugin.Plugin {
  }

  public class NotARegistry {
  }

  public class TestRegistry implements TW_Plugin.Registry {
    private final List<System.Type> pluginTypes;

    public TestRegistry() {
      this(new List<System.Type>());
    }

    public TestRegistry(List<System.Type> pluginTypes) {
      this.pluginTypes = pluginTypes;
    }

    public List<System.Type> plugins() {
      return pluginTypes;
    }
  }

  private class MyException extends Exception {
  }
}
