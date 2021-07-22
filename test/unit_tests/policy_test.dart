import 'package:flutter_test/flutter_test.dart';
import 'package:s3i_flutter/s3i_flutter.dart';

void mainPolicyTest() {
  final Map<String, dynamic> policyJson = {
    "policyId": "s3i:5812a618-b0ec-46e6-bee5-36745656913e",
    "entries": {
      "owner": {
        "subjects": {
          "nginx:8c143429-4b27-430f-9c53-409477ae4079": {
            "type": "nginx basic auth user X"
          },
          "nginx:ditto": {"type": "nginx basic auth user"}
        },
        "resources": {
          "policy:/": {
            "grant": ["READ", "WRITE"],
            "revoke": []
          },
          "thing:/": {
            "grant": ["READ", "WRITE"],
            "revoke": []
          },
          "message:/": {
            "grant": ["READ", "WRITE"],
            "revoke": ["EXECUTE"]
          }
        }
      },
      "observer": {
        "subjects": {
          "nginx:/iWald": {"type": "iWald user group"},
          "nginx:49332cdc-3a60-420f-8d39-e60d1fabc3a6": {
            "type": "XXX - Der Forstberater",
            "expiry": "2021-09-07T14:50:00.000Z"
          },
          "nginx:42723e9d-4db4-4f1b-b7cb-28bc62b38cbc": {
            "type": "Forstliche Dienstleistungen XXX"
          },
          "nginx:c38a47b6-7d0e-4c9f-8769-47fc9613730c": {
            "type": "description X"
          }
        },
        "resources": {
          "thing:/": {
            "grant": ["READ"],
            "revoke": []
          }
        }
      }
    }
  };

  test('Load default policy + manipulate observer', () {
    PolicyEntry p = PolicyEntry.fromJson(policyJson);
    expect(p.getAllObservers().length, 4);
    p.insertObserver(PolicySubject("nginx:test_observer"));
    expect(p.getAllObservers().length, 5);
    p.removeObserver("nginx:/iWald");
    expect(p.getAllObservers().length, 4);
  });

  test('Decode/Encode valid default policy', () {
    PolicyEntry p = PolicyEntry.fromJson(policyJson);
    var newJsonMap = p.toJson();
    expect(newJsonMap, policyJson);
  });

  test('Check expiry timestamp in default policy', () {
    PolicyEntry p = PolicyEntry.fromJson(policyJson);
    PolicySubject policySubject =
        p.getAllObservers()["nginx:49332cdc-3a60-420f-8d39-e60d1fabc3a6"]!;
    expect(
        policySubject.expiringTimestamp
            ?.isAtSameMomentAs(DateTime.parse("2021-09-07T15:50+01:00")),
        true);
  });
}

void main() {
  mainPolicyTest();
}
