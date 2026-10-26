/**
 * Example plugin that skips actions for users with a custom permission, configured in the org's own
 * Trigger_Bypass__mdt records. Each record names a custom permission, an action class and,
 * optionally, an SObject. A blank SObject matches every SObject. When an execution starts, the
 * plugin bypasses the matching actions with TW_Handler.addBypass, before the handler resolves them.
 *
 * A bypass lasts for the rest of the transaction, so when the next execution starts, the plugin
 * removes the bypasses it added, then adds the ones for that execution's SObject. It leaves alone
 * any bypass that was already set when it ran.
 *
 * Runs for every SObject using the framework once listed in TW_PluginRegistry. To assign a bypass,
 * add the custom permission to a permission set and assign the permission set.
 */
public with sharing class TW_Plugin_Bypass implements TW_Plugin.OnInit {
  private static final String EVERY_SOBJECT = '*';

  @TestVisible
  private static List<Trigger_Bypass__mdt> bypassRecords;
  // The running user's bypassed actions by lowercase SObject name, or EVERY_SOBJECT. A user's
  // permissions don't change within a transaction, so they're worked out once
  private static Map<String, Set<System.Type>> userBypasses;
  // The bypasses this plugin added, which it removes when the next execution starts
  private static final Set<System.Type> ADDED = new Set<System.Type>();

  /**
   * Bypass the user's actions for this execution's SObject
   */
  public void onInit(TW_Context ctx) {
    for (System.Type actionType : ADDED) {
      TW_Handler.removeBypass(actionType);
    }
    ADDED.clear();

    Map<String, Set<System.Type>> bypasses = userBypasses();
    for (String key : new List<String>{ String.valueOf(ctx.getSObjectType()).toLowerCase(), EVERY_SOBJECT }) {
      for (System.Type actionType : bypasses.containsKey(key) ? bypasses.get(key) : new Set<System.Type>()) {
        if (!TW_Handler.isBypassed(actionType)) {
          TW_Handler.addBypass(actionType);
          ADDED.add(actionType);
        }
      }
    }
  }

  private static Map<String, Set<System.Type>> userBypasses() {
    if (userBypasses == null) {
      userBypasses = new Map<String, Set<System.Type>>();
      // Each permission is checked once, however many records name it
      Map<String, Boolean> hasPermission = new Map<String, Boolean>();
      for (Trigger_Bypass__mdt r : bypassRecords != null ? bypassRecords : Trigger_Bypass__mdt.getAll().values()) {
        String permission = r.Permission__c?.trim();
        System.Type actionType = String.isBlank(r.Apex_Class__c) ? null : System.Type.forName(r.Apex_Class__c.trim());
        if (String.isBlank(permission) || actionType == null) {
          continue;
        }
        if (!hasPermission.containsKey(permission)) {
          hasPermission.put(permission, FeatureManagement.checkPermission(permission));
        }
        if (hasPermission.get(permission)) {
          String key = String.isBlank(r.SObject_Name__c) ? EVERY_SOBJECT : r.SObject_Name__c.trim().toLowerCase();
          if (!userBypasses.containsKey(key)) {
            userBypasses.put(key, new Set<System.Type>());
          }
          userBypasses.get(key).add(actionType);
        }
      }
    }
    return userBypasses;
  }
}
