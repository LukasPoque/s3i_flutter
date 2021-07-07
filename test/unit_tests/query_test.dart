import 'package:flutter_test/flutter_test.dart';
import 'package:s3i_flutter/s3i_flutter.dart';

void mainQueryTest() {
  test('Create minimal path', () {
    String base = "https://dir.s3i.vswf.dev/api/2/search/things";
    String result = QueryAssembler.generatePath(base);
    expect(result, base);
  });

  test('Create with fields: empty', () {
    String base = "https://dir.s3i.vswf.dev/api/2/search/things";
    String result =
        QueryAssembler.generatePath(base, fieldQuery: FieldQuery([]));
    expect(result, base + "?");
  });

  test('Create with fields: multiple', () {
    String base = "https://dir.s3i.vswf.dev/api/2/search/things";
    String result = QueryAssembler.generatePath(base,
        fieldQuery: FieldQuery(
            ["thingId", "_revision", "attributes(thingStructure/links)"]));
    String expected =
        base + "?fields=thingId,_revision,attributes(thingStructure/links)";
    expect(result, expected);
  });

  test('Create with namespaces: empty', () {
    String base = "https://dir.s3i.vswf.dev/api/2/search/things";
    String result =
        QueryAssembler.generatePath(base, namespaceQuery: NamespaceQuery([]));
    expect(result, base + "?");
  });

  test('Create with namespaces: multiple', () {
    String base = "https://dir.s3i.vswf.dev/api/2/search/things";
    String result = QueryAssembler.generatePath(base,
        namespaceQuery: NamespaceQuery(
            ["com.example.namespace1", "com.example.namespace2"]));
    String expected =
        base + "?namespaces=com.example.namespace1,com.example.namespace2";
    expect(result, expected);
  });

  test('Create with options: empty', () {
    String base = "https://dir.s3i.vswf.dev/api/2/search/things";
    String result =
        QueryAssembler.generatePath(base, optionQuery: OptionQuery());
    expect(result, base + "?");
  });

  test('Create with options: SortConf', () {
    String base = "https://dir.s3i.vswf.dev/api/2/search/things";
    String result = QueryAssembler.generatePath(base,
        optionQuery: OptionQuery(sortO: [
          SortConfig(SortOption.ascending, "thingId"),
          SortConfig(SortOption.descending, "attributes/name")
        ]));
    String expected = base + "?option=sort(+thingId,-attributes/name)";
    expect(result, expected);
  });

  test('Create with options: Size', () {
    String base = "https://dir.s3i.vswf.dev/api/2/search/things";
    String result = QueryAssembler.generatePath(base,
        optionQuery: OptionQuery(requestSize: 10));
    String expected = base + "?option=size(10)";
    expect(result, expected);
  });

  test('Create with options: Cursor', () {
    String base = "https://dir.s3i.vswf.dev/api/2/search/things";
    String result = QueryAssembler.generatePath(base,
        optionQuery: OptionQuery(cursor: "LOREMIPSUM"));
    String expected = base + "?option=cursor(LOREMIPSUM)";
    expect(result, expected);
  });

  test('Create with options: all combined', () {
    String base = "https://dir.s3i.vswf.dev/api/2/search/things";
    String result = QueryAssembler.generatePath(base,
        optionQuery: OptionQuery(sortO: [
          SortConfig(SortOption.ascending, "thingId"),
          SortConfig(SortOption.descending, "attributes/name")
        ], requestSize: 10, cursor: "LOREMIPSUM"));
    String expected = base +
        "?option=sort(+thingId,-attributes/name),size(10),cursor(LOREMIPSUM)";
    expect(result, expected);
  });

  test('Create with RQL: base single filter', () {
    String base = "https://dir.s3i.vswf.dev/api/2/search/things";
    String result = QueryAssembler.generatePath(base,
        rqlFilter: EQ("attributes/location", Val.string("kitchen")));
    expect(result, base + '?filter=eq(attributes/location,"kitchen")');
  });

  test('Create with RQL: 2 x filter', () {
    String base = "https://dir.s3i.vswf.dev/api/2/search/things";
    String result = QueryAssembler.generatePath(base,
        rqlFilter: OR(EQ("attributes/location", Val.string("kitchen")),
            LE("attributes/counter", Val.int(20))));
    expect(
        result,
        base +
            '?filter=or(eq(attributes/location,"kitchen"),le(attributes/counter,20))');
  });

  //TODO: test RQL pattern

  test('Create complex path', () {
    String base = "https://dir.s3i.vswf.dev/api/2/search/things";
    String result = QueryAssembler.generatePath(base,
        optionQuery: OptionQuery(sortO: [
          SortConfig(SortOption.ascending, "thingId"),
          SortConfig(SortOption.descending, "attributes/name")
        ], requestSize: 10, cursor: "LOREMIPSUM"),
        namespaceQuery: NamespaceQuery(
            ["com.example.namespace1", "com.example.namespace2"]),
        fieldQuery: FieldQuery(
            ["thingId", "_revision", "attributes(thingStructure/links)"]));
    String expected = base +
        "?namespaces=com.example.namespace1,com.example.namespace2"
            "&fields=thingId,_revision,attributes(thingStructure/links)"
            "&option=sort(+thingId,-attributes/name),size(10),cursor(LOREMIPSUM)";
    expect(result, expected);
  });
}

void main() {
  mainQueryTest();
}
