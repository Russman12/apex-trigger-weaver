/**
 * @description Provides unit test coverage for TW_OrderKeys
 */
@IsTest
public class TW_OrderKeysTest {
  /**
   * Ensures between returns the middle key when there are no bounds
   */
  @IsTest
  static void betweenNoBounds() {
    System.Assert.areEqual('V', TW_OrderKeys.between(null, null), 'unexpected key');
  }

  /**
   * Ensures between returns a key that sorts between its bounds
   */
  @IsTest
  static void betweenBounds() {
    assertBetween('a', 'b', TW_OrderKeys.between('a', 'b'));
    assertBetween('1', '3', TW_OrderKeys.between('1', '3'));
    assertBetween('z', null, TW_OrderKeys.between('z', null));
    assertBetween(null, '1', TW_OrderKeys.between(null, '1'));
    assertBetween('a0', 'a1', TW_OrderKeys.between('a0', 'a1'));
  }

  /**
   * Ensures between copies characters from bounds outside the key alphabet
   */
  @IsTest
  static void betweenOtherCharacters() {
    assertBetween('-', '.', TW_OrderKeys.between('-', '.'));
    assertBetween('a b', 'a~', TW_OrderKeys.between('a b', 'a~'));
  }

  /**
   * Ensures between never returns a key ending in 0
   */
  @IsTest
  static void betweenNoTrailingZero() {
    String key = TW_OrderKeys.between(null, '1');
    assertBetween(null, '1', key);
    System.Assert.isFalse(key.endsWith('0'), 'key ends in 0: ' + key);
    assertBetween(null, key, TW_OrderKeys.between(null, key));
  }

  /**
   * Ensures between returns null when no key fits between the bounds
   */
  @IsTest
  static void betweenNoRoom() {
    System.Assert.isNull(TW_OrderKeys.between('1', '10'), 'no key sorts between 1 and 10');
    System.Assert.isNull(TW_OrderKeys.between(null, '0'), 'no key sorts before 0');
    System.Assert.isNull(TW_OrderKeys.between('b', 'a'), 'bounds are reversed');
    System.Assert.isNull(TW_OrderKeys.between('a', 'a'), 'bounds are equal');
    System.Assert.isNull(TW_OrderKeys.between('z'.repeat(TW_OrderKeys.MAX_LENGTH), null), 'key would be too long');
  }

  /**
   * Ensures repeated insertions at random positions always produce ascending keys
   */
  @IsTest
  static void betweenRepeated() {
    List<String> keys = new List<String>();
    for (Integer i = 0; i < 300; i++) {
      Integer position = (Integer) Math.floor(Math.random() * (keys.size() + 1));
      String lower = position == 0 ? null : keys[position - 1];
      String upper = position == keys.size() ? null : keys[position];
      String key = TW_OrderKeys.between(lower, upper);
      assertBetween(lower, upper, key);
      System.Assert.isFalse(key.endsWith('0'), 'key ends in 0: ' + key);
      // add(index, element) fails on an index equal to the list size, including on an empty list
      if (position == keys.size()) {
        keys.add(key);
      } else {
        keys.add(position, key);
      }
    }
  }

  /**
   * Ensures spaced returns the requested number of ascending keys
   */
  @IsTest
  static void spaced() {
    for (Integer count : new List<Integer>{ 0, 1, 5, 61, 62, 200 }) {
      List<String> keys = TW_OrderKeys.spaced(count);
      System.Assert.areEqual(count, keys.size(), 'unexpected key count');
      assertAscending(keys);
    }
  }

  /**
   * Ensures reorder keeps keys that are already ascending
   */
  @IsTest
  static void reorderUnchanged() {
    List<String> keys = new List<String>{ '1', '2', '3' };
    System.Assert.areEqual(keys, TW_OrderKeys.reorder(keys), 'ascending keys changed');
  }

  /**
   * Ensures reorder replaces only the key of a moved item
   */
  @IsTest
  static void reorderMove() {
    List<String> keys = TW_OrderKeys.reorder(new List<String>{ '2', '1', '3' });
    assertAscending(keys);
    System.Assert.areEqual(2, countUnchanged(new List<String>{ '2', '1', '3' }, keys), 'more than one key changed');
  }

  /**
   * Ensures reorder replaces blank and duplicate keys
   */
  @IsTest
  static void reorderBlankAndDuplicate() {
    List<String> current = new List<String>{ '1', null, '2', '2', ' ' };
    List<String> keys = TW_OrderKeys.reorder(current);
    assertAscending(keys);
    System.Assert.areEqual(2, countUnchanged(current, keys), 'unexpected number of keys changed');
  }

  /**
   * Ensures reorder gives every item a new key when a replacement cannot fit
   */
  @IsTest
  static void reorderRespaced() {
    List<String> keys = TW_OrderKeys.reorder(new List<String>{ '1', null, '10' });
    assertAscending(keys);
    System.Assert.areEqual(TW_OrderKeys.spaced(3), keys, 'keys not respaced');
  }

  private static void assertBetween(String lower, String upper, String key) {
    System.Assert.isNotNull(key, 'no key between ' + lower + ' and ' + upper);
    if (lower != null) {
      System.Assert.isTrue(lower.compareTo(key) < 0, key + ' does not sort after ' + lower);
    }
    if (upper != null) {
      System.Assert.isTrue(key.compareTo(upper) < 0, key + ' does not sort before ' + upper);
    }
  }

  private static void assertAscending(List<String> keys) {
    for (Integer i = 1; i < keys.size(); i++) {
      System.Assert.isTrue(keys[i - 1].compareTo(keys[i]) < 0, 'keys not ascending: ' + keys);
    }
  }

  private static Integer countUnchanged(List<String> before, List<String> after) {
    Integer unchanged = 0;
    for (Integer i = 0; i < before.size(); i++) {
      if (before[i] != null && before[i].equals(after[i])) {
        unchanged++;
      }
    }
    return unchanged;
  }
}
