import 'package:s3i_flutter/src/query/query_param.dart';

enum RelationalOperatorType {
  eq,
  ne,
  gt,
  ge,
  lt,
  le,
  like
} //"exists" and "in" are relational operators too, but have different args so subclassing is not so nice

enum LogicalOperatorType {
  and,
  or
} //"not" is a logical operator too, but only uses one query arg (so subclassing is not so nice)

abstract class RQLQuery extends QueryParam {}

class LogicalQuery extends RQLQuery {
  RQLQuery a;
  RQLQuery b;
  LogicalOperatorType type;
  List<RQLQuery> additionalQueries;

  LogicalQuery(this.a, this.type, this.b, {this.additionalQueries = const []});

  @override
  String generateString() {
    String arguments = a.generateString() + "," + b.generateString();
    for (RQLQuery q in additionalQueries) {
      arguments += "," + q.generateString();
    }
    switch (type) {
      case LogicalOperatorType.and:
        return "and($arguments)";
      case LogicalOperatorType.or:
        return "or($arguments)";
    }
  }
}

class RelationalQuery extends RQLQuery {
  String jsonPointer;
  Val value;
  RelationalOperatorType type;

  RelationalQuery(this.jsonPointer, this.type, this.value);

  @override
  String generateString() {
    String val = value.generateString();
    switch (type) {
      case RelationalOperatorType.eq:
        return 'eq($jsonPointer,$val)';
      case RelationalOperatorType.ne:
        return 'ne($jsonPointer,$val)';
      case RelationalOperatorType.gt:
        return 'gt($jsonPointer,$val)';
      case RelationalOperatorType.ge:
        return 'ge($jsonPointer,$val)';
      case RelationalOperatorType.lt:
        return 'lt($jsonPointer,$val)';
      case RelationalOperatorType.le:
        return 'le($jsonPointer,$val)';
      case RelationalOperatorType.like:
        return 'like($jsonPointer,$val)';
    }
  }
}

class Val extends RQLQuery {
  String? _stringVal;
  bool? _boolVal;
  int? _intVal;
  double? _doubleVal;

  Val.string(String val) {
    this._stringVal = val;
  }

  Val.bool(bool val) {
    this._boolVal = val;
  }

  Val.int(int val) {
    this._intVal = val;
  }

  Val.double(double val) {
    this._doubleVal = val;
  }

  @override
  String generateString() {
    //TODO: idea for nicer way to expose the null check to the static analyser?
    String? localS = _stringVal;
    if (localS != null) {
      return '"$localS"';
    }
    bool? localB = _boolVal;
    if (_boolVal != null) {
      return localB.toString();
    }
    int? localI = _intVal;
    if (localI != null) {
      return localI.toString();
    }
    double? localD = _doubleVal;
    if (localD != null) {
      return localD.toString();
    }
    return "null";
  }
}

class AND extends LogicalQuery {
  AND(RQLQuery a, RQLQuery b, {additionalQueries = const <RQLQuery>[]})
      : super(a, LogicalOperatorType.and, b,
            additionalQueries: additionalQueries);
}

class OR extends LogicalQuery {
  OR(RQLQuery a, RQLQuery b, {additionalQueries = const <RQLQuery>[]})
      : super(a, LogicalOperatorType.or, b,
            additionalQueries: additionalQueries);
}

class NOT extends RQLQuery {
  RQLQuery query;

  NOT(this.query);

  @override
  String generateString() {
    String q = query.generateString();
    return "not($q)";
  }
}

class EQ extends RelationalQuery {
  EQ(String jsonPointer, Val value)
      : super(jsonPointer, RelationalOperatorType.eq, value);
}

class NE extends RelationalQuery {
  NE(String jsonPointer, Val value)
      : super(jsonPointer, RelationalOperatorType.ne, value);
}

class GT extends RelationalQuery {
  GT(String jsonPointer, Val value)
      : super(jsonPointer, RelationalOperatorType.gt, value);
}

class GE extends RelationalQuery {
  GE(String jsonPointer, Val value)
      : super(jsonPointer, RelationalOperatorType.ge, value);
}

class LT extends RelationalQuery {
  LT(String jsonPointer, Val value)
      : super(jsonPointer, RelationalOperatorType.lt, value);
}

class LE extends RelationalQuery {
  LE(String jsonPointer, Val value)
      : super(jsonPointer, RelationalOperatorType.le, value);
}

class IN extends RQLQuery {
  String jsonPointer;
  Val value;
  List<Val> additionalValues;

  IN(this.jsonPointer, this.value, {this.additionalValues = const []});

  @override
  String generateString() {
    String arguments = jsonPointer + "," + value.generateString();
    for (Val v in additionalValues) {
      arguments += "," + v.generateString();
    }
    return "in($arguments)";
  }
}

class LIKE extends RelationalQuery {
  LIKE(String jsonPointer, Val value)
      : super(jsonPointer, RelationalOperatorType.like, value);
}

class EXISTS extends RQLQuery {
  String jsonPointer;

  EXISTS(this.jsonPointer);

  @override
  String generateString() {
    return "exists($jsonPointer)";
  }
}
