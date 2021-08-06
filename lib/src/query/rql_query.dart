import 'package:s3i_flutter/src/query/query_param.dart';

// TODO(poq): create separate lib for RQL queries?
// TODO(poq): add RQL sorting

/// Base class for all RQL query classes.
///
/// The [RQL project page](https://github.com/persvr/rql) describes RQL:
/// > RQL can be thought as basically a set of nestable named operators which
/// > each have a set of arguments. RQL is designed to have an extremely simple,
/// > but extensible grammar that can be written in a URL friendly query string.
///
/// For more information take a look at the [Ditto documentation](https://www.eclipse.org/ditto/basic-rql.html).
/// A RQL expression has similarities to a tree:
/// Example from https://www.eclipse.org/ditto/basic-rql.html:
///
/// `and(eq(foo, "ditto"), lt(bar, 10))`
/// ```
///           and
///        /        \
///     eq            lt
///    /   \        /    \
///  foo  "ditto"  bar   10
/// ```
abstract class RQLQuery extends QueryParam {}

/// Represents a query with the logical operators: `AND` & `OR`.
///
/// You need at least two queries to compare, but it could be added up with
/// an endless chain of queries, see [additionalQueries].  See
/// [_LogicalOperatorType] for all comparison methods.
/// `NOT` is a logical operator too, but only uses one query arg, so see [NOT]
/// to negate a query.
///
/// For more information about logical operators in RQL refer to the
/// [Ditto docs](https://www.eclipse.org/ditto/basic-rql.html#logical-operators).
class LogicalQuery extends RQLQuery {
  /// Creates a new [LogicalQuery] with the given [type] and the both
  /// comparison queries [a] and [b].
  ///
  /// Use [additionalQueries] to add more queries.
  LogicalQuery(this.a, this.type, this.b,
      {this.additionalQueries = const <RQLQuery>[]});

  /// The first comparison element.
  RQLQuery a;

  /// The second comparison element.
  RQLQuery b;

  /// The type of this logical operator, see [_LogicalOperatorType].
  ///
  /// This is used in [generateString] to make it usable without overriding.
  _LogicalOperatorType type;

  /// The additional queries which are compared by the operator.
  List<RQLQuery> additionalQueries;

  @override
  String generateString() {
    String arguments = '${a.generateString()},${b.generateString()}';
    for (final RQLQuery q in additionalQueries) {
      arguments += ',${q.generateString()}';
    }
    switch (type) {
      case _LogicalOperatorType.and:
        return 'and($arguments)';
      case _LogicalOperatorType.or:
        return 'or($arguments)';
    }
  }
}

/// Represents a query with `relational operators`.
///
/// Relational queries compare a value at a specific position in the model
/// (given by [jsonPointer]) to an actual value ([value]). See
/// [_RelationalOperatorType] for all comparison methods.
/// `EXISTS` and `IN` are relational operators too, but have different args,
/// so see [EXISTS] and [IN] for details.
///
/// For more information about relational operators in RQL refer to the
/// [Ditto docs](https://www.eclipse.org/ditto/basic-rql.html#relational-operators).
class RelationalQuery extends RQLQuery {
  /// Creates a new [RelationalQuery] of [type] with the given [jsonPointer]
  /// and the comparison [value].
  RelationalQuery(this.jsonPointer, this.type, this.value);

  /// The JSON Pointer to the value in the model.
  ///
  /// See [RFC-6901](https://datatracker.ietf.org/doc/html/rfc6901) for the
  ///  JSON Pointer notation.
  String jsonPointer;

  /// The value to which the value at [jsonPointer] is compared to.
  Val value;

  /// The method of comparison between the values.
  _RelationalOperatorType type;

  @override
  String generateString() {
    final String val = value.generateString();
    switch (type) {
      case _RelationalOperatorType.eq:
        return 'eq($jsonPointer,$val)';
      case _RelationalOperatorType.ne:
        return 'ne($jsonPointer,$val)';
      case _RelationalOperatorType.gt:
        return 'gt($jsonPointer,$val)';
      case _RelationalOperatorType.ge:
        return 'ge($jsonPointer,$val)';
      case _RelationalOperatorType.lt:
        return 'lt($jsonPointer,$val)';
      case _RelationalOperatorType.le:
        return 'le($jsonPointer,$val)';
      case _RelationalOperatorType.like:
        return 'like($jsonPointer,$val)';
    }
  }
}

/// The comparison methods of a [LogicalQuery].
enum _LogicalOperatorType { and, or }

/// The comparison methods of a [RelationalQuery].
enum _RelationalOperatorType { eq, ne, gt, ge, lt, le, like }

/// Represents a `Query value` in RQL.
///
/// Currently Ditto supports `double`, `integer`, `string` (url-encoded),
/// `boolean` and `null`.
///
/// NOTE: this class doesn't support url encoding, so you have to do it when
/// you're creating the request.
///
/// See the [Ditto docs](https://www.eclipse.org/ditto/basic-rql.html#query-value)
/// for more.
class Val extends RQLQuery {
  /// Creates a [Val] with a given `String`.
  Val.string(String val) {
    _stringVal = val;
  }

  /// Creates a [Val] with `boolean` = true.
  Val.bTrue() {
    _boolVal = true;
  }

  /// Creates a [Val] with `boolean` = false.
  Val.bFalse() {
    _boolVal = false;
  }

  /// Creates a [Val] with a given `integer`.
  Val.int(int val) {
    _intVal = val;
  }

  /// Creates a [Val] with a given `double`.
  Val.double(double val) {
    _doubleVal = val;
  }

  /// Creates a [Val] with a given `boolean`.
  Val.nul();

  String? _stringVal;
  bool? _boolVal;
  int? _intVal;
  double? _doubleVal;

  @override
  String generateString() {
    if (_stringVal != null) {
      return '"$_stringVal"';
    }
    if (_boolVal != null) {
      return _boolVal.toString();
    }
    if (_intVal != null) {
      return _intVal.toString();
    }
    if (_doubleVal != null) {
      return _doubleVal.toString();
    }
    return 'null';
  }
}

/// A [LogicalQuery]: Ensures that all given queries match.
///
/// **Example**
/// Filter things which are located in the "living"-room and are active:
/// ```
/// AND(EQ('location', Val.string('living')), EQ('active', Val.bTrue()));
/// -> and(eq(location,"living-room"),eq(attributes/active,true))
/// ```
class AND extends LogicalQuery {
  /// Creates an [AND] operator with the given queries [a], [b] and the
  /// optional [additionalQueries].
  AND(RQLQuery a, RQLQuery b,
      {List<RQLQuery> additionalQueries = const <RQLQuery>[]})
      : super(a, _LogicalOperatorType.and, b,
            additionalQueries: additionalQueries);
}

// TODO(poq): add examples to the operators

/// A [LogicalQuery]: Ensures that at least one of the given queries match.
class OR extends LogicalQuery {
  /// Creates an [OR] operator with the given queries [a], [b] and the
  /// optional [additionalQueries].
  OR(RQLQuery a, RQLQuery b,
      {List<RQLQuery> additionalQueries = const <RQLQuery>[]})
      : super(a, _LogicalOperatorType.or, b,
            additionalQueries: additionalQueries);
}

/// A Logical Query operator: Negates the given query.
class NOT extends RQLQuery {
  /// Creates an [NOT] operator with the [query] to negate.
  NOT(this.query);

  /// The query which should be negated.
  RQLQuery query;

  @override
  String generateString() {
    return 'not(${query.generateString()})';
  }
}

/// A [RelationalQuery]: Filter property values equal to [value].
class EQ extends RelationalQuery {
  /// Creates an [EQ] (equals; ==) operator.
  EQ(String jsonPointer, Val value)
      : super(jsonPointer, _RelationalOperatorType.eq, value);
}

/// A [RelationalQuery]: Filter property values not equal to [value].
class NE extends RelationalQuery {
  /// Creates a [NE] (not equals; !=) operator.
  NE(String jsonPointer, Val value)
      : super(jsonPointer, _RelationalOperatorType.ne, value);
}

/// A [RelationalQuery]: Filter property values greater than [value].
class GT extends RelationalQuery {
  /// Creates a [GT] (greater than; >) operator.
  GT(String jsonPointer, Val value)
      : super(jsonPointer, _RelationalOperatorType.gt, value);
}

/// A [RelationalQuery]: Filter property values greater than or equal
/// to [value].
class GE extends RelationalQuery {
  /// Creates a [GE] (greater or equals; >=) operator.
  GE(String jsonPointer, Val value)
      : super(jsonPointer, _RelationalOperatorType.ge, value);
}

/// A [RelationalQuery]: Filter property values less than [value].
class LT extends RelationalQuery {
  /// Creates a [LT] (less; <) operator.
  LT(String jsonPointer, Val value)
      : super(jsonPointer, _RelationalOperatorType.lt, value);
}

/// A [RelationalQuery]: Filter property values less than or equal to [value].
class LE extends RelationalQuery {
  /// Creates a [LE] (less or equals; <=) operator;
  LE(String jsonPointer, Val value)
      : super(jsonPointer, _RelationalOperatorType.le, value);
}

/// A [RelationalQuery]: Filter property values which are like (similar)
/// to [value].
///
/// From the [Ditto docs]():
/// > The like operator provides some regular expression capabilities for
/// > pattern matching Strings.
/// >
/// > The following expressions are supported:
/// >
/// > *ends_with => match at the end of a specific String.
/// >
/// > starts_with* => match at the beginning of a specific String.
/// >
/// > *contains* => match if contains a specific String.
/// >
/// > Th?ng => match for a wildcard character.
class LIKE extends RelationalQuery {
  /// Creates a [LIKE] (similar) operator.
  LIKE(String jsonPointer, Val value)
      : super(jsonPointer, _RelationalOperatorType.like, value);
}

/// A Relational Query operator: Filter property values which contains at least
/// one of the listed [values].
class IN extends RQLQuery {
  /// Creates an [IN] (contains; ∈) operator.
  IN(this.jsonPointer, this.values);

  /// The JSON Pointer to the value in the model.
  ///
  /// See [RFC-6901](https://datatracker.ietf.org/doc/html/rfc6901) for the
  ///  JSON Pointer notation.
  String jsonPointer;

  /// The list of values to which the value at [jsonPointer] is compared to.
  List<Val> values;

  @override
  String generateString() {
    String arguments = '$jsonPointer,';
    for (final Val v in values) {
      arguments += ',${v.generateString()}';
    }
    return 'in($arguments)';
  }
}

/// A Relational Query operator: Filter property values ([jsonPointer])
/// which exist.
class EXISTS extends RQLQuery {
  /// Creates a [EXISTS] operator.
  EXISTS(this.jsonPointer);

  /// The JSON Pointer to the value in the model.
  ///
  /// See [RFC-6901](https://datatracker.ietf.org/doc/html/rfc6901) for the
  ///  JSON Pointer notation.
  String jsonPointer;

  @override
  String generateString() {
    return 'exists($jsonPointer)';
  }
}
