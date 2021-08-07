import 'package:flutter_test/flutter_test.dart';
import 'package:s3i_flutter/s3i_flutter.dart';

void mainQueryTest() {
  test('Create minimal path', () {
    const String base = 'https://dir.s3i.vswf.dev/api/2/search/things';
    final String result = assembleQuery(base);
    expect(result, base);
  });

  test('Create with fields: empty', () {
    const String base = 'https://dir.s3i.vswf.dev/api/2/search/things';
    final String result =
        assembleQuery(base, fieldQuery: FieldQuery(<String>[]));
    expect(result, '$base?');
  });

  test('Create with fields: multiple', () {
    const String base = 'https://dir.s3i.vswf.dev/api/2/search/things';
    final String result = assembleQuery(base,
        fieldQuery: FieldQuery(<String>[
          'thingId',
          '_revision',
          'attributes(thingStructure/links)'
        ]));
    const String expected =
        '$base?fields=thingId,_revision,attributes(thingStructure/links)';
    expect(result, expected);
  });

  test('Create with namespaces: empty', () {
    const String base = 'https://dir.s3i.vswf.dev/api/2/search/things';
    final String result =
        assembleQuery(base, namespaceQuery: NamespaceQuery(<String>[]));
    expect(result, '$base?');
  });

  test('Create with namespaces: multiple', () {
    const String base = 'https://dir.s3i.vswf.dev/api/2/search/things';
    final String result = assembleQuery(base,
        namespaceQuery: NamespaceQuery(
            <String>['com.example.namespace1', 'com.example.namespace2']));
    const String expected =
        '$base?namespaces=com.example.namespace1,com.example.namespace2';
    expect(result, expected);
  });

  test('Create with options: empty', () {
    const String base = 'https://dir.s3i.vswf.dev/api/2/search/things';
    final String result = assembleQuery(base, optionQuery: OptionQuery());
    expect(result, '$base?');
  });

  test('Create with options: SortConf', () {
    const String base = 'https://dir.s3i.vswf.dev/api/2/search/things';
    final String result = assembleQuery(base,
        optionQuery: OptionQuery(sortOptions: <SortConfig>[
          SortConfig(SortOption.ascending, 'thingId'),
          SortConfig(SortOption.descending, 'attributes/name')
        ]));
    const String expected = '$base?option=sort(+thingId,-attributes/name)';
    expect(result, expected);
  });

  test('Create with options: Size', () {
    const String base = 'https://dir.s3i.vswf.dev/api/2/search/things';
    final String result =
        assembleQuery(base, optionQuery: OptionQuery(pageSize: 10));
    const String expected = '$base?option=size(10)';
    expect(result, expected);
  });

  test('Create with options: Cursor', () {
    const String base = 'https://dir.s3i.vswf.dev/api/2/search/things';
    final String result =
        assembleQuery(base, optionQuery: OptionQuery(cursor: 'LOREMIPSUM'));
    const String expected = '$base?option=cursor(LOREMIPSUM)';
    expect(result, expected);
  });

  test('Create with options: all combined', () {
    const String base = 'https://dir.s3i.vswf.dev/api/2/search/things';
    final String result = assembleQuery(base,
        optionQuery: OptionQuery(sortOptions: <SortConfig>[
          SortConfig(SortOption.ascending, 'thingId'),
          SortConfig(SortOption.descending, 'attributes/name')
        ], pageSize: 10, cursor: 'LOREMIPSUM'));
    const String expected = '$base?option=sort(+thingId,-attributes/name),'
        'size(10),cursor(LOREMIPSUM)';
    expect(result, expected);
  });

  test('Create with RQL: base single filter', () {
    const String base = 'https://dir.s3i.vswf.dev/api/2/search/things';
    final String result = assembleQuery(base,
        rqlFilter: EQ('attributes/location', Val.string('kitchen')));
    expect(result, '$base?filter=eq(attributes/location,"kitchen")');
  });

  test('Create with RQL: 2 x filter', () {
    const String base = 'https://dir.s3i.vswf.dev/api/2/search/things';
    final String result = assembleQuery(base,
        rqlFilter: OR(EQ('attributes/location', Val.string('kitchen')),
            LE('attributes/counter', Val.int(20))));
    expect(
        result,
        '$base?filter=or(eq(attributes/location,"kitchen"),'
        'le(attributes/counter,20))');
  });

  // TODO(poq): test RQL pattern

  test('Create complex path', () {
    const String base = 'https://dir.s3i.vswf.dev/api/2/search/things';
    final String result = assembleQuery(base,
        optionQuery: OptionQuery(sortOptions: <SortConfig>[
          SortConfig(SortOption.ascending, 'thingId'),
          SortConfig(SortOption.descending, 'attributes/name')
        ], pageSize: 10, cursor: 'LOREMIPSUM'),
        namespaceQuery: NamespaceQuery(
            <String>['com.example.namespace1', 'com.example.namespace2']),
        fieldQuery: FieldQuery(<String>[
          'thingId',
          '_revision',
          'attributes(thingStructure/links)'
        ]));
    const String expected = '$base?namespaces=com.example.namespace1,'
        'com.example.namespace2&fields=thingId,_revision,'
        'attributes(thingStructure/links)'
        '&option=sort(+thingId,-attributes/name),size(10),cursor(LOREMIPSUM)';
    expect(result, expected);
  });
}

void main() {
  mainQueryTest();
}
