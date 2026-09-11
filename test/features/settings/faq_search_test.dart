import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/features/settings/domain/faq_entry.dart';

void main() {
  group('folding drops Vietnamese marks and case', () {
    // One pair per vowel family the table claims to cover, plus đ. Written as
    // literals rather than generated from `_folded`, which would assert the
    // table against itself.
    const pairs = {
      'Dữ liệu': 'du lieu',
      'Trần Văn Minh': 'tran van minh',
      'ăn uống': 'an uong',
      'nhập': 'nhap',
      'điện': 'dien',
      'mỗi': 'moi',
      'thứ tự': 'thu tu',
      'tỷ lệ': 'ty le',
      'ĐỒNG': 'dong',
    };

    for (final pair in pairs.entries) {
      test('"${pair.key}" folds to "${pair.value}"', () {
        expect(foldForSearch(pair.key), pair.value);
      });
    }

    test('unmarked text is only lowercased and trimmed', () {
      expect(foldForSearch('  Demo Mode  '), 'demo mode');
    });
  });

  group('searching the entries', () {
    test('there are five', () {
      expect(faqEntries, hasLength(5));
    });

    test('an unmarked query finds a marked entry', () {
      // The case the folding table exists for. `dữ liệu` does not appear in
      // the shipped English copy, so the entry is supplied here — the function
      // is what is under test, not the content.
      const vietnamese = [
        FaqEntry(question: 'Dữ liệu của tôi ở đâu?', answer: 'Trên máy này.'),
      ];
      expect(searchFaq('du lieu', entries: vietnamese), hasLength(1));
      expect(searchFaq('DU LIEU', entries: vietnamese), hasLength(1));
      expect(searchFaq('Dữ Liệu', entries: vietnamese), hasLength(1));
    });

    test('a query matches the answer as well as the question', () {
      expect(
        searchFaq('generated').single.question,
        'What is demo mode?',
      );
    });

    test('case does not matter', () {
      expect(searchFaq('DEMO'), searchFaq('demo'));
      expect(searchFaq('demo'), isNotEmpty);
    });

    test('a query matching nothing returns nothing', () {
      expect(searchFaq('xyzzy'), isEmpty);
    });

    test('an empty or whitespace query returns everything', () {
      expect(searchFaq(''), faqEntries);
      expect(searchFaq('   '), faqEntries);
    });

    test('every answer is prose, and every question asks something', () {
      for (final entry in faqEntries) {
        expect(entry.question, endsWith('?'));
        expect(
          entry.answer.length,
          greaterThan(40),
          reason: 'an answer that short is a label, not an answer',
        );
      }
    });

    test('two entries are never the same question', () {
      expect(
        faqEntries.map((e) => e.question).toSet(),
        hasLength(faqEntries.length),
      );
    });
  });
}
