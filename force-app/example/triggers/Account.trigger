trigger Account on Account(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  new TW_Handler(Account.getSObjectType()).addExtension(DMLTWExtension.class).addExtension(LoggingTWExtension.class).execute();
}
