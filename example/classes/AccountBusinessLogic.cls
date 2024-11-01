public with sharing class AccountBusinessLogic {
  public static String getName(Account a) {
    return a.Name + ' foo';
  }
  public static String contactNames(Account a) {
    String[] contactNames = new List<String>();
    for (Contact c : a.Contacts) {
      contactNames.add(c.Name);
    }
    return String.join(contactNames, ', ');
  }
}