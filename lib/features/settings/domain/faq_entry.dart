import 'package:equatable/equatable.dart';

/// One question and its answer on `08.11`.
class FaqEntry extends Equatable {
  /// Creates an entry.
  const FaqEntry({required this.question, required this.answer});

  /// What the user is asking.
  final String question;

  /// The answer, which states this app's actual behaviour.
  final String answer;

  /// Whether [query] matches this entry, ignoring case and diacritics.
  bool matches(String query) {
    final needle = foldForSearch(query);
    if (needle.isEmpty) return true;
    return foldForSearch(question).contains(needle) ||
        foldForSearch(answer).contains(needle);
  }

  @override
  List<Object?> get props => [question, answer];
}

/// The five entries `08.11` shows.
///
/// **Written, not transcribed.** Annotation `102:1297` says the answers
/// *"restate the product's actual behaviour — no cloud, local storage, manual
/// balances — so the FAQ cannot drift from the design"*, which makes the
/// product the source of truth for the content. The authored strings in
/// `102:1229` and its siblings could not be read: the Figma connection had
/// flipped to a View seat by the time this screen was built, and a View seat
/// cannot reach the file. Recorded as a deviation in
/// `docs/design-system/figma-map.md` rather than presented as a transcription.
///
/// Every answer below is a fact about this app: the database is local
/// (`lib/data/database`), there is no network code anywhere in `lib/`, demo
/// mode swaps to a second generated ledger (`lib/app/demo`), and
/// `SpendCategory` is a fixed enum.
const List<FaqEntry> faqEntries = [
  FaqEntry(
    question: 'Where is my data stored?',
    answer:
        'On this device, in a database only Moneta can read. Nothing is '
        'uploaded, and there is no server to upload it to.',
  ),
  FaqEntry(
    question: 'Can Moneta connect to my bank?',
    answer:
        'No. Every balance and every transaction is entered by hand. That is '
        'the trade for keeping your records off the internet.',
  ),
  FaqEntry(
    question: 'Does Moneta sync between my devices?',
    answer:
        'No. Your data lives on one device, so moving to a new phone means '
        'starting a new ledger.',
  ),
  FaqEntry(
    question: 'What is demo mode?',
    answer:
        'A second ledger full of generated transactions, so you can look '
        'around without entering anything. Your own records are untouched and '
        'come back the moment you switch it off.',
  ),
  FaqEntry(
    question: 'Can I add my own categories?',
    answer:
        'Not yet. Moneta ships a fixed set, and each category keeps the same '
        'colour in every chart so a glance at one tells you the same thing as '
        'a glance at another.',
  ),
];

/// [entries] matching [query].
///
/// An empty or whitespace query matches everything, so clearing the field
/// restores the list rather than emptying it.
List<FaqEntry> searchFaq(
  String query, {
  List<FaqEntry> entries = faqEntries,
}) => [
  for (final entry in entries)
    if (entry.matches(query)) entry,
];

/// [text] lowercased with Vietnamese diacritics removed, for searching.
///
/// An explicit table rather than Unicode normalisation: `dart:core` has no NFD
/// decomposition, and adding a package to fold five FAQ entries is not a trade
/// worth making. The table covers the vowels Vietnamese marks and `đ`, which
/// is the whole of what this app's own copy contains.
String foldForSearch(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final character = String.fromCharCode(rune);
    buffer.write(_folded[character] ?? character);
  }
  return buffer.toString().trim();
}

/// Each marked character mapped to its unmarked letter.
const Map<String, String> _folded = {
  'à': 'a',
  'á': 'a',
  'ả': 'a',
  'ã': 'a',
  'ạ': 'a',
  'ă': 'a',
  'ằ': 'a',
  'ắ': 'a',
  'ẳ': 'a',
  'ẵ': 'a',
  'ặ': 'a',
  'â': 'a',
  'ầ': 'a',
  'ấ': 'a',
  'ẩ': 'a',
  'ẫ': 'a',
  'ậ': 'a',
  'è': 'e',
  'é': 'e',
  'ẻ': 'e',
  'ẽ': 'e',
  'ẹ': 'e',
  'ê': 'e',
  'ề': 'e',
  'ế': 'e',
  'ể': 'e',
  'ễ': 'e',
  'ệ': 'e',
  'ì': 'i',
  'í': 'i',
  'ỉ': 'i',
  'ĩ': 'i',
  'ị': 'i',
  'ò': 'o',
  'ó': 'o',
  'ỏ': 'o',
  'õ': 'o',
  'ọ': 'o',
  'ô': 'o',
  'ồ': 'o',
  'ố': 'o',
  'ổ': 'o',
  'ỗ': 'o',
  'ộ': 'o',
  'ơ': 'o',
  'ờ': 'o',
  'ớ': 'o',
  'ở': 'o',
  'ỡ': 'o',
  'ợ': 'o',
  'ù': 'u',
  'ú': 'u',
  'ủ': 'u',
  'ũ': 'u',
  'ụ': 'u',
  'ư': 'u',
  'ừ': 'u',
  'ứ': 'u',
  'ử': 'u',
  'ữ': 'u',
  'ự': 'u',
  'ỳ': 'y',
  'ý': 'y',
  'ỷ': 'y',
  'ỹ': 'y',
  'ỵ': 'y',
  'đ': 'd',
};
