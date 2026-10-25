/**
 * Example plugin registry. TW_Handler loads the class named TW_PluginRegistry and runs the plugins
 * it returns for every SObject using the framework, in the order listed.
 */
public with sharing class TW_PluginRegistry implements TW_Plugin.Registry {
  /**
   * Bulk DML and execution logging for every trigger
   */
  public List<System.Type> plugins() {
    return new List<System.Type>{ TW_Plugin_DML.class, TW_Plugin_Logging.class };
  }
}
