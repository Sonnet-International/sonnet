import 'package:sonnet_linter/src/forks/casing.dart';
import 'package:test/test.dart';

void main() {
  group('camelize', () {
    test('does not change single words', () {
      expect('foo'.camelize, 'foo');
      expect('Foo'.camelize, 'foo');
      expect('FOO'.camelize, 'foo');
      expect('fooBar'.camelize, 'fooBar');
    });

    test('converts snake_case to camelCase', () {
      expect('foo_bar'.camelize, 'fooBar');
      expect('foo_bar_baz'.camelize, 'fooBarBaz');
    });

    test('converts kebab-case to camelCase', () {
      expect('foo-bar'.camelize, 'fooBar');
      expect('foo-bar-baz'.camelize, 'fooBarBaz');
    });

    test('converts PascalCase to camelCase', () {
      expect('FooBar'.camelize, 'fooBar');
      expect('FooBarBaz'.camelize, 'fooBarBaz');
    });

    test('converts mixed case to camelCase', () {
      expect('fooBar_baz'.camelize, 'fooBarBaz');
      expect('fooBar_Baz'.camelize, 'fooBarBaz');
      expect('foo_BarBaz'.camelize, 'fooBarBaz');
      expect('FooBar_baz'.camelize, 'fooBarBaz');
      expect('FooBar_Baz'.camelize, 'fooBarBaz');
      expect('Foo_BarBaz'.camelize, 'fooBarBaz');
    });

    test('converts sentences to camelCase', () {
      expect('foo bar'.camelize, 'fooBar');
      expect('foo bar baz'.camelize, 'fooBarBaz');
      expect('foo bar'.camelize, 'fooBar');
    });

    test('lowercases all-caps words', () {
      expect('FOO bar'.camelize, 'fooBar');
      expect('foo bar BAZ'.camelize, 'fooBarBaz');
      expect('foo BAR'.camelize, 'fooBar');
      expect('FOO BAR BAZ'.camelize, 'fooBarBaz');
    });

    test('truncates longs sentences to camelCase', () {
      expect(
        '''There was an old lady who lived in a shoe. She had so many children she did not know what to do.'''.camelize,
        '''thereWasAnOldLadyWhoLivedInAShoeSheHadSoManyChildrenSheDidNotKnowWhatToDo''',
      );
    });

    test('converts the first number of a string to word', () {
      expect('1 foo'.camelize, 'oneFoo');
    });

    test('stops at 3 numbers to convert to word', () {
      expect('123 foo'.camelize, 'oneHundredAndTwentyThreeFoo');
      expect('1,234 foo'.camelize, 'oneTwoThree4Foo');
    });

    test('trims white space and newlines', () {
      expect('foo\nbar'.camelize, 'fooBar');
      expect('  foo\n\tbar\n\t  '.camelize, 'fooBar');
      expect(r'  foo\n\tbar\n\t  '.camelize, 'fooBar');
    });
  });
}

// "We're sorry you're experiencing issues!\\n\\nYour logs (optional) will greatly help us in determining the issue.\\n\\nNo sensitive data is collected.",
