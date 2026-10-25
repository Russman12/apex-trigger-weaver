trigger Account on Account(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  new TW_Handler(Account.getSObjectType()).addPlugin(TW_Plugin_DML.class).addPlugin(TW_Plugin_Logging.class).execute();
}
