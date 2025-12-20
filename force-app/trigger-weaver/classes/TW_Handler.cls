public virtual class TW_Handler {
  private static final Set<System.TriggerOperation> QUERY_CONTEXTS = new Set<System.TriggerOperation>{
    System.TriggerOperation.AFTER_INSERT,
    System.TriggerOperation.BEFORE_UPDATE,
    System.TriggerOperation.AFTER_UPDATE,
    System.TriggerOperation.BEFORE_DELETE,
    System.TriggerOperation.AFTER_DELETE,
    System.TriggerOperation.AFTER_UNDELETE
  };

  private static final String BIND_NAME = 'recordIds';
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
  public static void addBypass(System.Type function) {
    bypasses.add(function);
  }

  /**
   * Removes method with given name from bypasses.
   * @param functionName add function to bypasses
   */
  public static void removeBypass(System.Type function) {
    bypasses.remove(function);
  }

  /**
   * Removes all bypasses
   */
  public static void clearBypasses() {
    bypasses.clear();
  }

  public static TW_Handler make(Schema.SObjectType sObjType) {
    return new TW_Handler(sObjType);
  }

  private List<TW_Function> twFunctions = new List<TW_Function>();
  private final TW_Queryable query;
  private final TW_DMLQueueable dmlQueue;
  private final SObjectType sObjType;
  private final TW_Context ctx;
  private final Map<String, Object> queryBinds;
  private final Map<Id, SObject> queriedRecordsMap;
  private final TW_QuerySelectionable selection;

  private TW_Handler(Schema.SObjectType sObjType) {
    this.sObjType = sObjType;
    Schema.SObjectField idField = sObjType.getDescribe().fields.getMap().get('Id');

    this.query = this.newQueryable();
    query.fromSObject(sObjType);

    this.selection = query.getSelection();
    this.dmlQueue = this.newQueueable();
    this.queriedRecordsMap = new Map<Id, SObject>();

    this.ctx = new TW_Context(idField, queriedRecordsMap, this.newQueueable());
    this.queryBinds = new Map<String, Object>();
  }

  protected virtual TW_Queryable newQueryable() {
    return new TW_Query();
  }

  protected virtual TW_DMLQueueable newQueueable() {
    return new TW_DMLQueue();
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
      function.executePreProcess(this.selection);
    }

    if (this.selection.isSet() && this.ctx.isQueryContext() && this.ctx.filteredRecords().size() > 0) {
      this.queryBinds.put(BIND_NAME, this.ctx.filteredRecords());
      List<SObject> queryResults = this.query.run(this.queryBinds);
      this.queriedRecordsMap.putAll(new Map<Id, SObject>(queryResults));
    }

    for (TW_Function function : twFunctions) {
      if (bypasses.contains(function.getType())) {
        continue;
      }
      function.execute();
    }

    this.ctx.getDMLQueue().flush();
  }
}
