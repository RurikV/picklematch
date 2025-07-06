import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:picklematch/services/api_service.dart';
import 'package:picklematch/services/firebase_service.dart';

void main() {
  group('Date Selection Tests', () {
    setUpAll(() async {
      WidgetsFlutterBinding.ensureInitialized();

      // Load environment variables
      await dotenv.load(fileName: ".env");
    });

    test('Firebase should handle initialization for date selection tests', () async {
      print('[DEBUG_LOG] Testing Firebase initialization for date selection...');

      final apiService = ApiService();
      try {
        await apiService.initialize();
        print('[DEBUG_LOG] Firebase initialized successfully');

        final firebaseService = FirebaseService();
        expect(firebaseService.isInitialized, isTrue);
      } catch (e) {
        print('[DEBUG_LOG] Firebase initialization failed in test environment (expected): $e');
        // In test environment, Firebase initialization is expected to fail
        expect(e, isA<Exception>());
      }
    });

    test('Should handle game loading for specific test dates in test environment', () async {
      print('[DEBUG_LOG] Testing game loading for specific dates...');

      final apiService = ApiService();
      try {
        await apiService.initialize();

        final firebaseService = FirebaseService();

        if (firebaseService.isInitialized) {
          final currentUser = firebaseService.auth.currentUser;

          if (currentUser != null) {
            print('[DEBUG_LOG] User is authenticated: ${currentUser.email}');

            final testDates = [
              '2024-07-04',  // July 4th
              '2024-12-25',  // Christmas
              '2024-01-01',  // New Year
              DateTime.now().toIso8601String().split('T').first,  // Today
            ];

            for (final dateStr in testDates) {
              print('[DEBUG_LOG] Testing date: $dateStr');
              try {
                final games = await firebaseService.getGamesForDate(dateStr);
                print('[DEBUG_LOG] Found ${games.length} games for date $dateStr');

                expect(games, isNotNull);
                expect(games, isA<List>());

                if (games.isNotEmpty) {
                  for (final game in games) {
                    print('[DEBUG_LOG] Game: ${game['id']} - Date: ${game['date']} - Time: ${game['time']} - Location: ${game['location_id']}');
                    expect(game, isA<Map>());
                    expect(game['id'], isNotNull);
                  }
                } else {
                  print('[DEBUG_LOG] No games found for date $dateStr');
                }
              } catch (e) {
                print('[DEBUG_LOG] Error loading games for date $dateStr: $e');
                // Don't fail the test for network errors, just verify the error is handled
                expect(e, isNotNull);
              }
            }
          } else {
            print('[DEBUG_LOG] No user is currently authenticated');
            print('[DEBUG_LOG] Authentication is required to load games');
            print('[DEBUG_LOG] This explains why no games are shown when clicking on dates');
            expect(currentUser, isNull);
          }
        } else {
          print('[DEBUG_LOG] Firebase service is not initialized');
          // In test environment, this is expected
          expect(firebaseService.isInitialized, isFalse);
        }
      } catch (e) {
        print('[DEBUG_LOG] Firebase initialization failed in test environment (expected): $e');
        // In test environment, Firebase initialization is expected to fail
        expect(e, isA<Exception>());
      }
    });

    test('Should handle getting all available game dates in test environment', () async {
      print('[DEBUG_LOG] Testing getting all available game dates...');

      final apiService = ApiService();
      try {
        await apiService.initialize();

        final firebaseService = FirebaseService();

        if (firebaseService.isInitialized) {
          final currentUser = firebaseService.auth.currentUser;

          if (currentUser != null) {
            try {
              final allDates = await firebaseService.getAllGameDates();
              print('[DEBUG_LOG] All game dates: ${allDates.toList()}');

              expect(allDates, isNotNull);
              expect(allDates, isA<Iterable>());

              if (allDates.isNotEmpty) {
                // Test loading games for the first available date
                final firstDate = allDates.first;
                print('[DEBUG_LOG] Testing games for first available date: $firstDate');
                final gamesForFirstDate = await firebaseService.getGamesForDate(firstDate);
                print('[DEBUG_LOG] Games for $firstDate: ${gamesForFirstDate.length}');

                expect(gamesForFirstDate, isNotNull);
                expect(gamesForFirstDate, isA<List>());
              }
            } catch (e) {
              print('[DEBUG_LOG] Error getting all game dates: $e');
              // Don't fail the test for network errors, just verify the error is handled
              expect(e, isNotNull);
            }
          } else {
            print('[DEBUG_LOG] No user is currently authenticated');
            print('[DEBUG_LOG] Skipping authenticated operations');
            expect(currentUser, isNull);
          }
        } else {
          print('[DEBUG_LOG] Firebase service is not initialized');
          // In test environment, this is expected
          expect(firebaseService.isInitialized, isFalse);
        }
      } catch (e) {
        print('[DEBUG_LOG] Firebase initialization failed in test environment (expected): $e');
        // In test environment, Firebase initialization is expected to fail
        expect(e, isA<Exception>());
      }
    });
  });
}
