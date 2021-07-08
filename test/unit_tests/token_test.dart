import 'package:flutter_test/flutter_test.dart';
import 'package:s3i_flutter/s3i_flutter.dart';

void mainTokenTest() {
  test('Load valid token', () {
    String tokenS =
        "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJPbzRfUTE0UGxjeVJfX1A5MXAtYXRaWURYa"
        "29GVV9ORk5qLWtLdDVHdXNJIn0.eyJleHAiOjE2MTU4MDg1NDQsImlhdCI6MTYxNTgwMTM0NCwianRpIjoiM"
        "jBmMWFiOGMtYTM5Zi00ZjkxLWIyMWEtNDE4MjUwZjAwNDJkIiwiaXNzIjoiaHR0cHM6Ly9pZHAuczNpLnZzd"
        "2YuZGV2L2F1dGgvcmVhbG1zL0tXSCIsImF1ZCI6WyJyYWJiaXRtcSIsInJlYWxtLW1hbmFnZW1lbnQiLCJhY2"
        "NvdW50Il0sInN1YiI6IjYwNmQ4YjM4LTRjM2YtNDZiZC05NDgyLTg2NzQ4ZTEwOGYzMiIsInR5cCI6IkJlYX"
        "JlciIsImF6cCI6ImFwcF9yZWdpc3RlciIsInNlc3Npb25fc3RhdGUiOiI5NWU5MzE4MS1kZWIwLTRmNTItOW"
        "JlZi0wZWE5OTZlOTQ3NTQiLCJhY3IiOiIxIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbIm9mZmxpbmVfYWN"
        "jZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJyZWFsbS1tYW5hZ2VtZW50"
        "Ijp7InJvbGVzIjpbInZpZXctaWRlbnRpdHktcHJvdmlkZXJzIiwidmlldy1yZWFsbSIsIm1hbmFnZS1pZGVud"
        "Gl0eS1wcm92aWRlcnMiLCJpbXBlcnNvbmF0aW9uIiwicmVhbG0tYWRtaW4iLCJjcmVhdGUtY2xpZW50Iiwib"
        "WFuYWdlLXVzZXJzIiwicXVlcnktcmVhbG1zIiwidmlldy1hdXRob3JpemF0aW9uIiwicXVlcnktY2xpZW50c"
        "yIsInF1ZXJ5LXVzZXJzIiwibWFuYWdlLWV2ZW50cyIsIm1hbmFnZS1yZWFsbSIsInZpZXctZXZlbnRzIiwid"
        "mlldy11c2VycyIsInZpZXctY2xpZW50cyIsIm1hbmFnZS1hdXRob3JpemF0aW9uIiwibWFuYWdlLWNsaWVud"
        "HMiLCJxdWVyeS1ncm91cHMiXX0sImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJtYW5hZ"
        "2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sInNjb3BlIjoiZ3JvdXAgcmFiYml0bXEuY29uZ"
        "mlndXJlOiovKi8qIHJhYmJpdG1xLnRhZzphZG1pbmlzdHJhdG9yIHJhYmJpdG1xLndyaXRlOiovKi8qIHByb"
        "2ZpbGUgcmFiYml0bXEucmVhZDoqLyovKiBlbWFpbCIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiZ3JvdXBzI"
        "jpbXSwicHJlZmVycmVkX3VzZXJuYW1lIjoia3doLXRlYW0ifQ.CMAIUA2jvaeo7ehwO5PvVVUKHdcCHmf335"
        "v_hywrmCv3WtevBkBrqyy2l24BJ0DwQiQTLMSDOO-L0iMorLliEzJ6f9hV3l2EK_ZEA0R7n_sP5f6EF0h--v"
        "M2Pwzx3-kD9J58d3Z16lVCoNRC9bcBE1iWJMuoIV5feeVb3oyXipSzgzX_GgX8LxTysrepF3suk_GpF-Kfg"
        "VGcu-NkeeuJiqZ_em_me53lh-gSqQ8WM_X-LB5Pfd-Hd-Gg6hw-zHxGoiBybFqVj5h9ZOB6esXglj5_9dK8e"
        "Vday_e-hoak7qJIHpMe31WB8g_kMJaf2haS61RaKF5ilKyfYULWUEzZbQ";
    Token token = AccessToken(tokenS);
    expect(token.decodedToken["sub"], "606d8b38-4c3f-46bd-9482-86748e108f32");
  });

  test('Load invalid token', () {
    String tokenS =
        "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJPbzRfUTE0UGxjeVJfX1A5MXAtYXRaWURYa"
        "29GVV9ORk5qLWtLdDVHdXNJIn0.eyJleHAiOjE2MTU4MDg1NDQsImlhdCI6MTYxNTgwMTM0NCwianRpIjoiM"
        "jBmMWFiOGMtYTM5Zi00ZjkxLWIyMWEtNDE4MjUwZjAwNDJkIiwiaXNzIjoiaHR0cHM6Ly9pZHAuczNpLnZzd"
        "2YuZGV2L2F1dGgvcmVhbG1zL0tXSCIsImF1ZCI6WyJyYWJiaXRtcSIsInJlYWxtLW1hbmFnZW1lbnQiLCJhY2"
        "NvdW50Il0sInN1YiI6IjYwNmQ4YjM4LTRjM2YtNDZiZC05NDgyLTg2NzQ4ZTEwOGYzMiIsInR5cCI6IkJlYX"
        "JlciIsImF6cCI6ImFwcF9yZWdpc3RlciIsInNlc3Npb25fc3RhdGUiOiI5NWU5MzE4MS1kZWIwLTRmNTItOW"
        "JlZi0wZWE5OTZlOTQ3NTQiLCJhY3IiOiIxIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbIm9mZmxpbmVfYWN"
        "jZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJyZWFsbS1tYW5hZ2VtZW50"
        "Ijp7InJvbGVzIjpbInZpZXctaWRlbnRpdHktcHJvdmlkZXJzIiwidmlldy1yZWFsbSIsIm1hbmFnZS1pZGVud"
        "Gl0eS1wcm92aWRlcnMiLCJpbXBlcnNvbmF0aW9uIiwicmVhbG0tYWRtaW4iLCJjcmVhdGUtY2xpZW50Iiwib"
        "WFuYWdlLXVzZXJzIiwicXVlcnktcmVhbG1zIiwidmlldy1hdXRob3JpemF0aW9uIiwicXVlcnktY2xpZW50c"
        "yIsInF1ZXJ5LXVzZXJzIiwibWFuYWdlLWV2ZW50cyIsIm1hbmFnZS1yZWFsbSIsInZpZXctZXZlbnRzIiwid"
        "mlldy11c2VycyIsInZpZXctY2xpZW50cyIsIm1hbFnZS1hdXRob3JpemF0aW9uIiwibWFuYWdlLWNsaWVud"
        "HMiLCJxdWVyeS1ncm91cHMiXX0sImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJtYW5hZ"
        "2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sInNjb3BlIjoiZ3JvdXAgcmFiYml0bXEuY29uZ"
        "mlndXJlOiovKi8qIHJhYmJpdG1xLnRhZzphZG1pbmlzdHJhdG9yIHJhYmJpdG1xLndyaXRlOiovKi8qIHByb"
        "2ZpbGUgcmFiYml0bXEucmVhZDoqLyovKiBlbWFpbCIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiZ3JvdXBzI"
        "jpbXSwicHJlZmVycmVkX3VzZXJuYW1lIjoia3doLXRlYW0ifQ.CMAIUA2jvaeo7ehwO5PvVVUKHdcCHmf335"
        "v_hywrmCv3WtevBkBrqyy2l24BJ0DwQiQTLMSDOO-L0iMorLliEzJ6f9hV3l2EK_ZEA0R7n_sP5f6EF0h--v"
        "M2Pwzx3-kD9J58d3Z16lVCoNRC9bcBE1iWJMuoIV5feeVb3oyXipSzgzX_GgX8LxTysrepF3suk_GpF-Kfg"
        "VGcu-NkeeuJiqZ_em_me53lh-gSqQ8WM_X-LB5Pfd-Hd-Gg6hw-zHxGoiBybFqVj5h9ZOB6esXglj5_9dK8e"
        "Vday_e-hoak7qJIHpMe31WB8g_kMJaf2haS61RaKF5ilKyfYULWUEzZbQ";
    expect(() => AccessToken(tokenS),
        throwsA(predicate((e) => e is FormatException)));
  });
}

void main() {
  mainTokenTest();
}
