import 'package:flutter_test/flutter_test.dart';
import 'package:s3i_flutter/s3i_flutter.dart';

void mainPolicyTest() {
  final Map<String, dynamic> policyJson = <String, dynamic>{
    'policyId': 's3i:5812a618-b0ec-46e6-bee5-36745656913e',
    'entries': <String, dynamic>{
      'owner': <String, dynamic>{
        'subjects': <String, dynamic>{
          'nginx:8c143429-4b27-430f-9c53-409477ae4079': <String, dynamic>{
            'type': 'nginx basic auth user X'
          },
          'nginx:ditto': <String, dynamic>{'type': 'nginx basic auth user'}
        },
        'resources': <String, dynamic>{
          'policy:/': <String, dynamic>{
            'grant': <String>['READ', 'WRITE'],
            'revoke': <String>[]
          },
          'thing:/': <String, dynamic>{
            'grant': <String>['READ', 'WRITE'],
            'revoke': <String>[]
          },
          'message:/': <String, dynamic>{
            'grant': <String>['READ', 'WRITE'],
            'revoke': <String>['EXECUTE']
          }
        }
      },
      'observer': <String, dynamic>{
        'subjects': <String, dynamic>{
          'nginx:/iWald': <String, dynamic>{'type': 'iWald user group'},
          'nginx:49332cdc-3a60-420f-8d39-e60d1fabc3a6': <String, dynamic>{
            'type': 'XXX - Der Forstberater',
            'expiry': '2021-09-07T14:50:00.000Z'
          },
          'nginx:42723e9d-4db4-4f1b-b7cb-28bc62b38cbc': <String, dynamic>{
            'type': 'Forstliche Dienstleistungen XXX'
          },
          'nginx:c38a47b6-7d0e-4c9f-8769-47fc9613730c': <String, dynamic>{
            'type': 'description X'
          }
        },
        'resources': <String, dynamic>{
          'thing:/': <String, dynamic>{
            'grant': <String>['READ'],
            'revoke': <String>[]
          }
        }
      }
    }
  };

  test('Load default policy + manipulate observer', () {
    final PolicyEntry p = PolicyEntry.fromJson(policyJson);
    expect(p.getAllObservers().length, 4);
    p.insertObserver(PolicySubject('nginx:test_observer'));
    expect(p.getAllObservers().length, 5);
    p.removeObserver('nginx:/iWald');
    expect(p.getAllObservers().length, 4);
  });

  test('Decode/Encode valid default policy', () {
    final PolicyEntry p = PolicyEntry.fromJson(policyJson);
    final Map<String, dynamic> newJsonMap = p.toJson();
    expect(newJsonMap, policyJson);
  });

  test('Check expiry timestamp in default policy', () {
    final PolicyEntry p = PolicyEntry.fromJson(policyJson);
    final PolicySubject policySubject =
        p.getAllObservers()['nginx:49332cdc-3a60-420f-8d39-e60d1fabc3a6']!;
    expect(
        policySubject.expiringTimestamp
            ?.isAtSameMomentAs(DateTime.parse('2021-09-07T15:50+01:00')),
        true);
  });
}

void main() {
  mainPolicyTest();
}
