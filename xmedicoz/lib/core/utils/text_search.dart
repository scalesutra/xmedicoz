/// Shared case-insensitive substring matching used by medicine searches.
abstract final class TextSearch {
  static String normalize(String text) => text.trim().toLowerCase();

  static bool matches(String text, String normalizedQuery) =>
      text.toLowerCase().contains(normalizedQuery);
}
