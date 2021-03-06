import 'package:flutter_test/flutter_test.dart';
import 'package:s3i_flutter/s3i_flutter.dart';

void mainTokenTest() {
  test('Load valid access token', () {
    const String tokenS =
        'eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJPbzRfUTE0UGxjeVJfX'
        '1A5MXAtYXRaWURYa29GVV9ORk5qLWtLdDVHdXNJIn0.eyJleHAiOjE2MTU4MDg1NDQsIml'
        'hdCI6MTYxNTgwMTM0NCwianRpIjoiMjBmMWFiOGMtYTM5Zi00ZjkxLWIyMWEtNDE4MjUwZ'
        'jAwNDJkIiwiaXNzIjoiaHR0cHM6Ly9pZHAuczNpLnZzd2YuZGV2L2F1dGgvcmVhbG1zL0t'
        'XSCIsImF1ZCI6WyJyYWJiaXRtcSIsInJlYWxtLW1hbmFnZW1lbnQiLCJhY2'
        'NvdW50Il0sInN1YiI6IjYwNmQ4YjM4LTRjM2YtNDZiZC05NDgyLTg2NzQ4ZTEwOGYzMiIs'
        'InR5cCI6IkJlYXJlciIsImF6cCI6ImFwcF9yZWdpc3RlciIsInNlc3Npb25fc3RhdGUiOi'
        'I5NWU5MzE4MS1kZWIwLTRmNTItOWJlZi0wZWE5OTZlOTQ3NTQiLCJhY3IiOiIxIiwicmV'
        'hbG1fYWNjZXNzIjp7InJvbGVzIjpbIm9mZmxpbmVfYWN'
        'jZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJyZWFsb'
        'S1tYW5hZ2VtZW50'
        'Ijp7InJvbGVzIjpbInZpZXctaWRlbnRpdHktcHJvdmlkZXJzIiwidmlldy1yZWFsbSIsI'
        'm1hbmFnZS1pZGVud'
        'Gl0eS1wcm92aWRlcnMiLCJpbXBlcnNvbmF0aW9uIiwicmVhbG0tYWRtaW4iLCJjcmVhdG'
        'UtY2xpZW50Iiwib'
        'WFuYWdlLXVzZXJzIiwicXVlcnktcmVhbG1zIiwidmlldy1hdXRob3JpemF0aW9uIiwicX'
        'VlcnktY2xpZW50c'
        'yIsInF1ZXJ5LXVzZXJzIiwibWFuYWdlLWV2ZW50cyIsIm1hbmFnZS1yZWFsbSIsInZpZ'
        'XctZXZlbnRzIiwid'
        'mlldy11c2VycyIsInZpZXctY2xpZW50cyIsIm1hbmFnZS1hdXRob3JpemF0aW9uIiwib'
        'WFuYWdlLWNsaWVud'
        'HMiLCJxdWVyeS1ncm91cHMiXX0sImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY'
        '291bnQiLCJtYW5hZ'
        '2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sInNjb3BlIjoiZ3JvdXAgc'
        'mFiYml0bXEuY29uZ'
        'mlndXJlOiovKi8qIHJhYmJpdG1xLnRhZzphZG1pbmlzdHJhdG9yIHJhYmJpdG1xLndy'
        'aXRlOiovKi8qIHByb'
        '2ZpbGUgcmFiYml0bXEucmVhZDoqLyovKiBlbWFpbCIsImVtYWlsX3ZlcmlmaWVkIjpmY'
        'WxzZSwiZ3JvdXBzI'
        'jpbXSwicHJlZmVycmVkX3VzZXJuYW1lIjoia3doLXRlYW0ifQ.CMAIUA2jvaeo7ehwO5'
        'PvVVUKHdcCHmf335'
        'v_hywrmCv3WtevBkBrqyy2l24BJ0DwQiQTLMSDOO-L0iMorLliEzJ6f9hV3l2EK_ZEA0'
        'R7n_sP5f6EF0h--v'
        'M2Pwzx3-kD9J58d3Z16lVCoNRC9bcBE1iWJMuoIV5feeVb3oyXipSzgzX_GgX8LxTys'
        'repF3suk_GpF-Kfg'
        'VGcu-NkeeuJiqZ_em_me53lh-gSqQ8WM_X-LB5Pfd-Hd-Gg6hw-zHxGoiBybFqVj5h9'
        'ZOB6esXglj5_9dK8e'
        'Vday_e-hoak7qJIHpMe31WB8g_kMJaf2haS61RaKF5ilKyfYULWUEzZbQ';
    final JsonWebToken token = AccessToken(tokenS);
    expect(token.decodedPayload['sub'], '606d8b38-4c3f-46bd-9482-86748e108f32');
  });

  test('Load invalid access token', () {
    const String tokenS =
        'eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJPbzRfUTE0UGxjeVJfX'
        '1A5MXAtYXRaWURYa'
        '29GVV9ORk5qLWtLdDVHdXNJIn0.eyJleHAiOjE2MTU4MDg1NDQsImlhdCI6MTYxNTgwMT'
        'M0NCwianRpIjoiM'
        'jBmMWFiOGMtYTM5Zi00ZjkxLWIyMWEtNDE4MjUwZjAwNDJkIiwiaXNzIjoiaHR0cHM6Ly'
        '9pZHAuczNpLnZzd'
        '2YuZGV2L2F1dGgvcmVhbG1zL0tXSCIsImF1ZCI6WyJyYWJiaXRtcSIsInJlYWxtLW1hbm'
        'FnZW1lbnQiLCJhY2'
        'NvdW50Il0sInN1YiI6IjYwNmQ4YjM4LTRjM2YtNDZiZC05NDgyLTg2NzQ4ZTEwOGYzMiI'
        'sInR5cCI6IkJlYX'
        'JlciIsImF6cCI6ImFwcF9yZWdpc3RlciIsInNlc3Npb25fc3RhdGUiOiI5NWU5MzE4MS1'
        'kZWIwLTRmNTItOW'
        'JlZi0wZWE5OTZlOTQ3NTQiLCJhY3IiOiIxIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjp'
        'bIm9mZmxpbmVfYWN'
        'jZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJyZWFsb'
        'S1tYW5hZ2VtZW50'
        'Ijp7InJvbGVzIjpbInZpZXctaWRlbnRpdHktcHJvdmlkZXJzIiwidmlldy1yZWFsbSIsI'
        'm1hbmFnZS1pZGVud'
        'Gl0eS1wcm92aWRlcnMiLCJpbXBlcnNvbmF0aW9uIiwicmVhbG0tYWRtaW4iLCJjcmVhdG'
        'UtY2xpZW50Iiwib'
        'WFuYWdlLXVzZXJzIiwicXVlcnktcmVhbG1zIiwidmlldy1hdXRob3JpemF0aW9uIiwicX'
        'VlcnktY2xpZW50c'
        'yIsInF1ZXJ5LXVzZXJzIiwibWFuYWdlLWV2ZW50cyIsIm1hbmFnZS1yZWFsbSIsInZpZX'
        'ctZXZlbnRzIiwid'
        'mlldy11c2VycyIsInZpZXctY2xpZW50cyIsIm1hbFnZS1hdXRob3JpemF0aW9uIiwibW'
        'FuYWdlLWNsaWVud'
        'HMiLCJxdWVyeS1ncm91cHMiXX0sImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY2'
        '91bnQiLCJtYW5hZ'
        '2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sInNjb3BlIjoiZ3JvdXAgcm'
        'FiYml0bXEuY29uZ'
        'mlndXJlOiovKi8qIHJhYmJpdG1xLnRhZzphZG1pbmlzdHJhdG9yIHJhYmJpdG1xLndyaX'
        'RlOiovKi8qIHByb'
        '2ZpbGUgcmFiYml0bXEucmVhZDoqLyovKiBlbWFpbCIsImVtYWlsX3ZlcmlmaWVkIjpmYW'
        'xzZSwiZ3JvdXBzI'
        'jpbXSwicHJlZmVycmVkX3VzZXJuYW1lIjoia3doLXRlYW0ifQ.CMAIUA2jvaeo7ehwO5Pv'
        'VVUKHdcCHmf335'
        'v_hywrmCv3WtevBkBrqyy2l24BJ0DwQiQTLMSDOO-L0iMorLliEzJ6f9hV3l2EK_ZEA0R'
        '7n_sP5f6EF0h--v'
        'M2Pwzx3-kD9J58d3Z16lVCoNRC9bcBE1iWJMuoIV5feeVb3oyXipSzgzX_GgX8LxTysre'
        'pF3suk_GpF-Kfg'
        'VGcu-NkeeuJiqZ_em_me53lh-gSqQ8WM_X-LB5Pfd-Hd-Gg6hw-zHxGoiBybFqVj5h9ZO'
        'B6esXglj5_9dK8e'
        'Vday_e-hoak7qJIHpMe31WB8g_kMJaf2haS61RaKF5ilKyfYULWUEzZbQ';
    expect(() => AccessToken(tokenS),
        throwsA(predicate((Object? e) => e is FormatException)));
  });

  test('Load valid refresh token', () {
    const String tokenS =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImEzZjU2OGFhLTIyOWQtNDJlYi'
        '1iZmIwLThkNzdjOGMzMWQzNSJ9.eyJleHAiOjE2MjgxMjM4NzQsImlhdCI6MTYyODEyMz'
        'A3NCwianRpIjoiNmE2ODFmZDktMDQ3ZC00Y2YwLTk0ZWUtNTk4ZWZmNTkzNjg3IiwiaXN'
        'zIjoiaHR0cHM6Ly9pZHAuczNpLnZzd2YuZGV2L2F1dGgvcmVhbG1zL0tXSCIsImF1ZCI6I'
        'mh0dHBzOi8vaWRwLnMzaS52c3dmLmRldi9hdXRoL3JlYWxtcy9LV0giLCJzdWIiOiIyN2F'
        'lYzU3MS0yNDIxLTQ3YjQtYjEwOS0yMDViZTBjZTc2N2EiLCJ0eXAiOiJSZWZyZXNoIiwi'
        'YXpwIjoiczNpLWZsdXR0ZXItdGVzdCIsInNlc3Npb25fc3RhdGUiOiJlNmM0NTUyMS00NT'
        'czLTRkN2EtYWUwYy1hMTUzMDUwNDU1MzciLCJzY29wZSI6InByb2ZpbGUgZW1haWwifQ.K'
        'XkivQqLm0yTXB-272gExYkejMNARiwPH8WBvGyv0Lg';
    final JsonWebToken token = RefreshToken(tokenS);
    expect(token.decodedPayload['sub'], '27aec571-2421-47b4-b109-205be0ce767a');
  });

  test('Load valid offline token', () {
    const String tokenS =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImEzZjU2OGFhLTIyOWQtNDJlY'
        'i1iZmIwLThkNzdjOGMzMWQzNSJ9.eyJpYXQiOjE2MTgyMzQxMTksImp0aSI6IjkwNDIyYT'
        'I1LWJjNjItNDQ1Zi04YjVmLTIyYWU3ODQ5NDJjMSIsImlzcyI6Imh0dHBzOi8vaWRwLnMz'
        'aS52c3dmLmRldi9hdXRoL3JlYWxtcy9LV0giLCJhdWQiOiJodHRwczovL2lkcC5zM2kudn'
        'N'
        '3Zi5kZXYvYXV0aC9yZWFsbXMvS1dIIiwic3ViIjoiMjdhZWM1NzEtMjQyMS00N2I0LWIxM'
        'DktMjA1YmUwY2U3NjdhIiwidHlwIjoiT2ZmbGluZSIsImF6cCI6InMzaS1mbHV0dGVyLWV'
        '4YW1wbGUtY2xpZW50Iiwic2Vzc2lvbl9zdGF0ZSI6IjBmODRjYTdhLWYyM2UtNDRlNC1h'
        'MDZlLTkyODkyYWFjZmRjNCIsInNjb3BlIjoib3BlbmlkIGdyb3VwIG9mZmxpbmVfYWNjZ'
        'XNzIGVtYWlsIn0.DfXogzztZbik701EWg0d9VDUCdY2KA3EyCbuomnBQy4';
    final JsonWebToken token = RefreshToken(tokenS);
    expect(token.decodedPayload['sub'], '27aec571-2421-47b4-b109-205be0ce767a');
  });
}

void main() {
  mainTokenTest();
}
