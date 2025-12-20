/**
 * Contains business logic relating to the account object
 */
public with sharing class AccountBusinessLogic {
  /**
   * Returns a comma separated list of all child contact names
   * @param a account
   * @return comma separated list of contact names
   */
  public static String contactNames(Account a) {
    String[] contactNames = new List<String>();
    for (Contact c : a.Contacts) {
      contactNames.add(c.Name);
    }
    return String.join(contactNames, ', ');
  }
}
