public class TW_Handler {
  //TODO: handle DML operations
  private static final Set<System.TriggerOperation> QUERY_CONTEXTS = new Set<System.TriggerOperation>{
    System.TriggerOperation.AFTER_INSERT,
    System.TriggerOperation.BEFORE_UPDATE,
    System.TriggerOperation.AFTER_UPDATE,
    System.TriggerOperation.BEFORE_DELETE,
    System.TriggerOperation.AFTER_DELETE,
    System.TriggerOperation.AFTER_UNDELETE
  };

  private static final String BIND_NAME = 'records';
  private static final Set<Type> bypasses = new Set<Type>();
  private static Map<Schema.SObjectType, List<Trigger_Weaver__mdt>> activeTWSBySObj;
  private static List<Trigger_Weaver__mdt> getActiveTWSForSObj(Schema.SObjectType sObjType) {
    if (activeTWSBySObj == null) {
      activeTWSBySObj = new Map<Schema.SObjectType, List<Trigger_Weaver__mdt>>();
      for (Trigger_Weaver__mdt tw : Trigger_Weaver__mdt.getAll().values()) {
        if (tw.Active__c) {
          SObjectType twSObjType = ((SObject) Type.forName(tw.SObject_Name__c).newInstance()).getSObjectType();
          if (!activeTWSBySObj.containsKey(twSObjType)) {
            activeTWSBySObj.put(twSObjType, new List<Trigger_Weaver__mdt>());
          }
          activeTWSBySObj.get(twSObjType).add(tw);
        }
      }
    }

    return activeTWSBySObj.get(sObjType);
  }

  /**
   * Adds method with given name to bypasses.
   * @param functionName add function to bypasses
   */
  public static void addBypass(Type function) {
    bypasses.add(function);
  }

  /**
   * Removes method with given name from bypasses.
   * @param functionName add function to bypasses
   */
  public static void removeBypass(Type function) {
    bypasses.remove(function);
  }

  /**
   * Removes all bypasses
   */
  public static void clearBypasses() {
    bypasses.clear();
  }

  private List<TW_Function> twFunctions = new List<TW_Function>();
  private final ASB soql;
  private final SObjectType sObjType;
  private final TW_Context ctx;
  private final Map<String, Object> queryBinds;
  private final Map<Id, SObject> queriedRecordsMap;
  private final ASB_Select selection;

  public static TW_Handler make(Schema.SObjectType sObjType) {
    return new TW_Handler(sObjType);
  }

  private TW_Handler(Schema.SObjectType sObjType) {
    this.sObjType = sObjType;
    Schema.SObjectField idField = sObjType.getDescribe().fields.getMap().get('Id');

    this.selection = ASB_Select.make().field(idField);
    this.soql = ASB.sObject(sObjType).filter(ASB_Where.field(idField).isIn().bind(BIND_NAME)).selection(this.selection);
    this.queriedRecordsMap = new Map<Id, SObject>();

    this.ctx = new TW_Context(idField, queriedRecordsMap);
    this.queryBinds = new Map<String, Object>();
  }

  public TW_Handler register(TW_Function function) {
    twFunctions.add(function);

    return this;
  }

  public TW_Handler autoRegister() {
    List<Trigger_Weaver__mdt> tws = getActiveTWSForSObj(this.sObjType);
    if (tws == null) {
      return this;
    }

    for (Trigger_Weaver__mdt tw : tws) {
      register((TW_Function) System.Type.forName(tw.DeveloperName).newInstance());
    }

    return this;
  }

  public void execute() {
    for (TW_Function function : this.twFunctions) {
      if (bypasses.contains(function.getType())) {
        continue;
      }

      function.setContext(this.ctx);
      function.executePreProcess();

      ASB_Select funcSelect = this.ctx.getQuerySelection(function.getType());
      if (funcSelect != null) {
        this.selection.combine(funcSelect);
      }
    }
    if (!this.ctx.getQuerySelections().isEmpty() && this.ctx.isQueryContext() && this.ctx.filteredRecords().size() > 0) {
      this.queryBinds.put(BIND_NAME, this.ctx.filteredRecords());
      this.queriedRecordsMap.putAll(new Map<Id, SObject>(this.soql.query(this.queryBinds)));
    }

    for (TW_Function function : twFunctions) {
      if (bypasses.contains(function.getType())) {
        continue;
      }
      function.execute();
    }

    List<SObject> updates = new List<SObject>();
    for (TW_Function function : twFunctions) {
      updates.addAll(function.getUpdates());
    }

    updates.sort();
    update updates;
  }
}
