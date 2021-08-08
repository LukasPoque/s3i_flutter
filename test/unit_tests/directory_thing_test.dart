import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:s3i_flutter/s3i_flutter.dart';

void mainThingTests() {
  test('Load minimal thing', () {
    const String json = '''
    {
      "thingId": "s3i:00641896-cb2d-4aeb-9680-91c1bdf76064",
      "policyId": "s3i:00641896-cb2d-4aeb-9680-91c1bdf76064"
    }''';
    final Thing thing =
        Thing.fromJson(jsonDecode(json) as Map<String, dynamic>);
    expect(thing.id, 's3i:00641896-cb2d-4aeb-9680-91c1bdf76064');
  });

  test('Load invalid Json', () {
    const String json = '''
    {
      "thingId": "s3i:00641896-cb2d-4aeb-9680-91c1bdf76064",
      "policyId": "s3i:00641896-cb2d-4aeb-9680-91c1bdf76064",
      "attributes": {
        "ownedBy": "69a22c45-4bf0-41f9-be43-851804f5c966"
        "allEndpoints": [
          "https://ditto.s3i.vswf.dev/api/2/things/s3i:00641896-cb2d-4aeb-9680-91c1bdf76064"
        ]
      }
    }''';
    expect(() => Thing.fromJson(jsonDecode(json) as Map<String, dynamic>),
        throwsA(predicate((Object? e) => e is FormatException)));
  });

  test('Load minimal + attributes thing', () {
    const String json = '''
    {
      "thingId": "s3i:00641896-cb2d-4aeb-9680-91c1bdf76064",
      "policyId": "s3i:00641896-cb2d-4aeb-9680-91c1bdf76064",
      "attributes": {
      }
    }''';
    final Thing thing =
        Thing.fromJson(jsonDecode(json) as Map<String, dynamic>);
    expect(thing.id, 's3i:00641896-cb2d-4aeb-9680-91c1bdf76064');
  });

  test('Load mismatching thing_type thing', () {
    const String json = '''
    {
      "thingId": "s3i:00641896-cb2d-4aeb-9680-91c1bdf76064",
      "policyId": "s3i:00641896-cb2d-4aeb-9680-91c1bdf76064",
      "attributes": {
        "type": "wrong_string"
      }
    }''';
    expect(() => Thing.fromJson(jsonDecode(json) as Map<String, dynamic>),
        throwsA(predicate((Object? e) => e is InvalidJsonSchemaException)));
  });

  test('Load thing_type wrong element thing', () {
    const String json = '''
    {
      "thingId": "s3i:00641896-cb2d-4aeb-9680-91c1bdf76064",
      "policyId": "s3i:00641896-cb2d-4aeb-9680-91c1bdf76064",
      "attributes": {
        "type": ["a","b"]
      }
    }''';
    expect(() => Thing.fromJson(jsonDecode(json) as Map<String, dynamic>),
        throwsA(predicate((Object? e) => e is InvalidJsonSchemaException)));
  });

  test('Load defaultEndpoint wrong element thing', () {
    const String json = '''
    {
      "thingId": "s3i:00641896-cb2d-4aeb-9680-91c1bdf76064",
      "policyId": "s3i:00641896-cb2d-4aeb-9680-91c1bdf76064",
      "attributes": {
        "allEndpoints": "abc"
      }
    }''';
    expect(() => Thing.fromJson(jsonDecode(json) as Map<String, dynamic>),
        throwsA(predicate((Object? e) => e is InvalidJsonSchemaException)));
  });

  test('Load complex thing 1 - Error value', () {
    const String json = '''
    {
    "thingId": "s3i:d96f6fbe-a0f4-41ad-b1ec-bbbe1cd6f0c3",
    "policyId": "s3i:d96f6fbe-a0f4-41ad-b1ec-bbbe1cd6f0c3",
    "attributes": {
        "ownedBy": "6e31ae57-88e5-4b05-90a5-40b6ee403d58",
        "represents": "6e31ae57-88e5-4b05-90a5-40b6ee403d58",
        "name": "Test-User K. Meier",
        "type": "component",
        "dataModel": "fml40",
        "thingStructure": {
            "class": "ml40::Thing",
            "links": [
                {
                    "association": "roles",
                    "target": {
                        "class": "fml40::ForestConsultant"
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "ml40::PersonalName",
                        "values": [
                            {
                                "attribute": "firstname",
                                "value": "K"
                            },
                            {
                                "attribute": "lastname",
                                "value": "Meier"
                            }
                        ]
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "ml40::CompanyName",
                        "values": [
                            {
                                "attribute": "name",
                                "value": "Super Duper Inc."
                            }
                        ]
                    }
                }
            ]
        }
    }
    }''';
    expect(() => Thing.fromJson(jsonDecode(json) as Map<String, dynamic>),
        throwsA(predicate((Object? e) => e is InvalidJsonSchemaException)));
  });

  test('Complex thing 2', () {
    const String json = '''
    {
    "thingId": "s3i:847dc67e-9dad-4415-8e58-819b724a1a8f",
    "policyId": "s3i:847dc67e-9dad-4415-8e58-819b724a1a8f",
    "attributes": {
        "name": "Mini Tractor",
        "type": "component",
        "dataModel": "fml40",
        "allEndpoints": [
            "s3ibs://s3i:847dc67e-9dad-4415-8e58-819b724a1a8f"
        ],
        "location": {
            "latitude": 6.078015,
            "longitude": 50.777592
        },
        "ownedBy": "606d8b38-4c3f-46bd-9482-86748e108f32",
        "thingStructure": {
            "class": "ml40::Thing",
            "links": [
                {
                    "association": "roles",
                    "target": {
                        "class": "fml40::MiniTractor"
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "ml40::OperatingHours"
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "ml40::LastServiceCheck"
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "ml40::Weight"
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "ml40::Dimensions"
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "ml40::OrientationRPY"
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "ml40::Location"
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "fml40::AcceptsMoveCommands"
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "fml40::AcceptsWinchCommands"
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "fml40::AcceptsShieldCommands"
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "fml40::AcceptsFellingSupportJobs"
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "fml40::AcceptsForwardingJobs"
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "ml40::JobList"
                    }
                },
                {
                    "association": "features",
                    "target": {
                        "class": "ml40::Composite",
                        "links": [
                            {
                                "association": "targets",
                                "target": {
                                    "class": "ml40::Thing",
                                    "links": [
                                        {
                                            "association": "roles",
                                            "target": {
                                                "class": "fml40::Winch"
                                            }
                                        },
                                        {
                                            "association": "features",
                                            "target": {
                                                "class": "ml40::ExpansionLength"
                                            }
                                        }
                                    ]
                                }
                            },
                            {
                                "association": "targets",
                                "target": {
                                    "class": "ml40::Thing",
                                    "links": [
                                        {
                                            "association": "roles",
                                            "target": {
                                                "class": "ml40::Engine"
                                            }
                                        },
                                        {
                                            "association": "features",
                                            "target": {
                                                "class": "ml40::RotationalSpeed"
                                            }
                                        }
                                    ]
                                }
                            },
                            {
                                "association": "targets",
                                "target": {
                                    "class": "ml40::Thing",
                                    "links": [
                                        {
                                            "association": "roles",
                                            "target": {
                                                "class": "ml40::Engine"
                                            }
                                        },
                                        {
                                            "association": "features",
                                            "target": {
                                                "class": "ml40::RotationalSpeed"
                                            }
                                        }
                                    ]
                                }
                            },
                            {
                                "association": "targets",
                                "target": {
                                    "class": "ml40::Thing",
                                    "links": [
                                        {
                                            "association": "roles",
                                            "target": {
                                                "class": "fml40::StackingShield"
                                            }
                                        },
                                        {
                                            "association": "features",
                                            "target": {
                                                "class": "ml40::Lift"
                                            }
                                        }
                                    ]
                                }
                            }
                        ]
                    }
                }
            ]
        }
    }
    }''';
    final Thing thing =
        Thing.fromJson(jsonDecode(json) as Map<String, dynamic>);
    expect(thing.id, 's3i:847dc67e-9dad-4415-8e58-819b724a1a8f');
    final String newJson = jsonEncode(thing.toJson());
    expect(newJson.replaceAll(RegExp(' {1,}'), ''),
        json.replaceAll(RegExp(' {1,}'), '').replaceAll('\n', ''));
  });
}

void main() {
  mainThingTests();
}
