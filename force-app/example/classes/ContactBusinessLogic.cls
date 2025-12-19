public with sharing class ContactBusinessLogic {
  public static String fullName(Contact c) {
    return c.FirstName + ' ' + c.LastName;
  }
}
