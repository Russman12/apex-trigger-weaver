/**
 * Buisness logic specific to contact object
 */
public with sharing class ContactBusinessLogic {
  /**
   * Returns full name of the contact
   * @param c contact
   * @return full name of the contact
   */
  public static String fullName(Contact c) {
    return c.FirstName + ' ' + c.LastName;
  }
}
