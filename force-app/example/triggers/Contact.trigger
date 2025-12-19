trigger Contact on Contact(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TW_Handler.make(Contact.getSObjectType()).autoRegister().execute();
}
