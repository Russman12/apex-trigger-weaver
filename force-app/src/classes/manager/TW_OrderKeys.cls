/**
 * @description Generates TW_Action__mdt Order__c values. Keys sort by String.compareTo, the same
 * comparison TW_ActionRegistry uses, and are built from the characters 0-9, A-Z and a-z, which are in
 * ascending Unicode order. A key can always be generated after any key, and usually between any two
 * keys, so moving an action normally changes only that action's key.
 */
public inherited sharing class TW_OrderKeys {
  @TestVisible
  private static final String DIGITS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  @TestVisible
  private static final Integer MAX_LENGTH = 255;
  private static final Integer NO_LOWER_BOUND = -1;
  private static final Integer NO_UPPER_BOUND = 65536;

  /**
   * @description Returns the shortest key that sorts after lower and before upper. Copies characters
   * from the bounds where needed, so bounds containing other characters are supported. The key never
   * ends in 0, which keeps room for a later key before it.
   * @param lower The key to sort after, or null for no lower bound.
   * @param upper The key to sort before, or null for no upper bound.
   * @return The key, or null if no key fits between the bounds within MAX_LENGTH characters.
   */
  public static String between(String lower, String upper) {
    if (lower != null && upper != null && lower.compareTo(upper) >= 0) {
      return null;
    }

    // While bound to a side, the key so far equals that side's prefix
    Boolean boundToLower = lower != null;
    Boolean boundToUpper = upper != null;
    List<Integer> key = new List<Integer>();
    while (key.size() < MAX_LENGTH) {
      Integer i = key.size();
      if (boundToUpper && i >= upper.length()) {
        return null;
      }
      Integer lo = boundToLower && i < lower.length() ? lower.charAt(i) : NO_LOWER_BOUND;
      Integer hi = boundToUpper ? upper.charAt(i) : NO_UPPER_BOUND;

      List<Integer> candidates = new List<Integer>();
      for (Integer c : DIGITS.getChars()) {
        if (c > lo && c < hi) {
          candidates.add(c);
        }
      }

      if (!candidates.isEmpty()) {
        Integer c = candidates[candidates.size() / 2];
        key.add(c);
        if (c != DIGITS.charAt(0)) {
          return String.fromCharArray(key);
        }
        // Ending in 0 would leave no key between this one and its lower neighbour
        boundToLower = false;
        boundToUpper = false;
      } else if (lo == hi) {
        key.add(lo);
      } else if (lo != NO_LOWER_BOUND) {
        key.add(lo);
        boundToUpper = false;
      } else {
        key.add(hi);
        boundToLower = false;
      }
    }
    return null;
  }

  /**
   * @description Returns count evenly spaced keys in ascending order.
   * @param count The number of keys to generate.
   * @return The keys.
   */
  public static List<String> spaced(Integer count) {
    Integer width = 1;
    Long range = DIGITS.length();
    while (range <= count) {
      width++;
      range *= DIGITS.length();
    }

    List<String> keys = new List<String>();
    for (Integer i = 1; i <= count; i++) {
      // Write the position as a fixed-width base-62 number, then drop trailing zeros, which keeps
      // the keys in the same order
      Long position = range * i / (count + 1);
      List<Integer> reversed = new List<Integer>();
      for (Integer w = 0; w < width; w++) {
        reversed.add(DIGITS.charAt((Integer) Math.mod(position, DIGITS.length())));
        position /= DIGITS.length();
      }
      // reversed holds the least significant digit first
      List<Integer> key = new List<Integer>();
      for (Integer d = reversed.size() - 1; d >= 0; d--) {
        key.add(reversed[d]);
      }
      while (key[key.size() - 1] == DIGITS.charAt(0)) {
        key.remove(key.size() - 1);
      }
      keys.add(String.fromCharArray(key));
    }
    return keys;
  }

  /**
   * @description Returns keys for items in the given order, keeping as many of their current keys as
   * possible. The current keys that already ascend are kept and the rest are replaced with keys
   * between their neighbours. If a replacement cannot fit, every item gets a new evenly spaced key.
   * @param currentKeys Each item's current key in the desired order. Blank keys are always replaced.
   * @return The new keys, strictly ascending, one per item.
   */
  public static List<String> reorder(List<String> currentKeys) {
    Integer count = currentKeys.size();
    Set<Integer> kept = longestAscending(currentKeys);

    List<String> keys = new List<String>();
    for (Integer i = 0; i < count; i++) {
      if (kept.contains(i)) {
        keys.add(currentKeys[i]);
        continue;
      }
      String lower = i == 0 ? null : keys[i - 1];
      String upper = null;
      for (Integer j = i + 1; j < count; j++) {
        if (kept.contains(j)) {
          upper = currentKeys[j];
          break;
        }
      }
      String key = between(lower, upper);
      if (key == null) {
        return spaced(count);
      }
      keys.add(key);
    }
    return keys;
  }

  // Indexes of the longest strictly ascending run of non-blank keys, keeping order
  private static Set<Integer> longestAscending(List<String> keys) {
    Integer count = keys.size();
    List<Integer> lengths = new List<Integer>();
    List<Integer> previous = new List<Integer>();
    Integer best = -1;
    for (Integer i = 0; i < count; i++) {
      lengths.add(0);
      previous.add(-1);
      if (String.isBlank(keys[i])) {
        continue;
      }
      lengths[i] = 1;
      for (Integer j = 0; j < i; j++) {
        if (lengths[j] > 0 && keys[j].compareTo(keys[i]) < 0 && lengths[j] + 1 > lengths[i]) {
          lengths[i] = lengths[j] + 1;
          previous[i] = j;
        }
      }
      if (best == -1 || lengths[i] > lengths[best]) {
        best = i;
      }
    }

    Set<Integer> kept = new Set<Integer>();
    for (Integer i = best; i != -1; i = previous[i]) {
      kept.add(i);
    }
    return kept;
  }
}
