// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:picklematch/main.dart';
import 'bloc/auth_bloc_test.mocks.dart';

void main() {
  testWidgets('MyApp can be instantiated with ApiService', (WidgetTester tester) async {
    // Create a mock ApiService
    final mockApiService = MockApiService();

    // Stub the initialize method and any other methods that might be called
    when(mockApiService.initialize()).thenAnswer((_) async => {});

    // Build our app and trigger a frame.
    // We expect this to not throw an error
    expect(() => MyApp(apiService: mockApiService), returnsNormally);
  });
}
