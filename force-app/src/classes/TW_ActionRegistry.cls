/**
 * @description Contains functionality relating to action registry management.
 */
public class TW_ActionRegistry {
  private static Map<Schema.SObjectType, List<System.Type>> activeActionsBySObj;

  /**
   * @description Returns a list of active actions for the given SObject type.
   * @param sObjType The SObject type to get active actions for.
   */
  public List<System.Type> activeActions(Schema.SObjectType sObjType) {
    if (activeActionsBySObj == null) {
      activeActionsBySObj = new Map<Schema.SObjectType, List<System.Type>>();
      for (TW_Action__mdt tw : TW_Action__mdt.getAll().values()) {
        if (tw.Active__c) {
          SObjectType twSObjType = ((SObject) Type.forName(tw.SObject_Name__c).newInstance()).getSObjectType();
          if (!activeActionsBySObj.containsKey(twSObjType)) {
            activeActionsBySObj.put(twSObjType, new List<System.Type>());
          }
          activeActionsBySObj.get(twSObjType).add(System.Type.forName(tw.DeveloperName));
        }
      }
    }

    return activeActionsBySObj.get(sObjType);
  }

  /**
   * @description Manually registers an action. This will prevent actual metadata types from registering.
   * This should only be used in a test context.
   * @param sObjType The SObject type to register the action for.
   * @param actionType The action type to register.
   */
  @TestVisible
  private static void register(Schema.SObjectType sObjType, System.Type actionType) {
    if (activeActionsBySObj == null) {
      activeActionsBySObj = new Map<Schema.SObjectType, List<System.Type>>();
    }
    if (!activeActionsBySObj.containsKey(sObjType)) {
      activeActionsBySObj.put(sObjType, new List<System.Type>());
    }
    if (!activeActionsBySObj.get(sObjType).contains(actionType)) {
      activeActionsBySObj.get(sObjType).add(actionType);
    }
  }

  /**
   * @description Clears the action registry and prevents future calls from executing actions.
   * This should only be used in a test context.
   */
  @TestVisible
  private static void clear() {
    activeActionsBySObj = new Map<Schema.SObjectType, List<System.Type>>();
  }
}
