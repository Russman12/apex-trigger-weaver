trigger Contact on Contact(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  new TW_Handler(Contact.getSObjectType()).addPlugin(TW_Plugin_DML.class).addPlugin(TW_Plugin_Logging.class).execute();
}
