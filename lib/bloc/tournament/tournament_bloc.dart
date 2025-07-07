import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/tournament_service.dart';
import '../../services/firebase_service.dart';
import 'tournament_event.dart';
import 'tournament_state.dart';

class TournamentBloc extends Bloc<TournamentEvent, TournamentState> {
  final TournamentService _tournamentService;

  TournamentBloc() 
    : _tournamentService = TournamentService(FirebaseService()),
      super(TournamentInitial()) {
    
    on<LoadTournaments>(_onLoadTournaments);
    on<LoadTournamentsByAdmin>(_onLoadTournamentsByAdmin);
    on<LoadOpenTournaments>(_onLoadOpenTournaments);
    on<LoadPlayerTournaments>(_onLoadPlayerTournaments);
    on<CreateTournament>(_onCreateTournament);
    on<RegisterForTournament>(_onRegisterForTournament);
    on<UnregisterFromTournament>(_onUnregisterFromTournament);
    on<GenerateTournamentMatches>(_onGenerateTournamentMatches);
    on<StartTournament>(_onStartTournament);
    on<CompleteTournament>(_onCompleteTournament);
    on<CancelTournament>(_onCancelTournament);
    on<UpdateTournament>(_onUpdateTournament);
    on<LoadTournamentDetails>(_onLoadTournamentDetails);
  }

  Future<void> _onLoadTournaments(
    LoadTournaments event,
    Emitter<TournamentState> emit,
  ) async {
    try {
      emit(TournamentLoading());
      final tournaments = await _tournamentService.getAllTournaments();
      emit(TournamentLoaded(tournaments));
    } catch (e) {
      emit(TournamentError('Failed to load tournaments: ${e.toString()}'));
    }
  }

  Future<void> _onLoadTournamentsByAdmin(
    LoadTournamentsByAdmin event,
    Emitter<TournamentState> emit,
  ) async {
    try {
      emit(TournamentLoading());
      final tournaments = await _tournamentService.getTournamentsByAdmin(event.adminUserId);
      emit(TournamentLoaded(tournaments));
    } catch (e) {
      emit(TournamentError('Failed to load admin tournaments: ${e.toString()}'));
    }
  }

  Future<void> _onLoadOpenTournaments(
    LoadOpenTournaments event,
    Emitter<TournamentState> emit,
  ) async {
    try {
      emit(TournamentLoading());
      final tournaments = await _tournamentService.getOpenTournaments(event.playerId);
      emit(TournamentLoaded(tournaments));
    } catch (e) {
      emit(TournamentError('Failed to load open tournaments: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPlayerTournaments(
    LoadPlayerTournaments event,
    Emitter<TournamentState> emit,
  ) async {
    try {
      emit(TournamentLoading());
      final tournaments = await _tournamentService.getPlayerTournaments(event.playerId);
      emit(TournamentLoaded(tournaments));
    } catch (e) {
      emit(TournamentError('Failed to load player tournaments: ${e.toString()}'));
    }
  }

  Future<void> _onCreateTournament(
    CreateTournament event,
    Emitter<TournamentState> emit,
  ) async {
    try {
      emit(TournamentOperationInProgress('Creating tournament...'));
      
      final tournament = await _tournamentService.createTournament(
        name: event.name,
        description: event.description,
        locationId: event.locationId,
        date: event.date,
        timeSlots: event.timeSlots,
        numberOfCourts: event.numberOfCourts,
        adminUserId: event.adminUserId,
        minRating: event.minRating,
        maxRating: event.maxRating,
      );

      if (tournament != null) {
        emit(TournamentCreated(tournament));
      } else {
        emit(TournamentError('Failed to create tournament'));
      }
    } catch (e) {
      emit(TournamentError('Failed to create tournament: ${e.toString()}'));
    }
  }

  Future<void> _onRegisterForTournament(
    RegisterForTournament event,
    Emitter<TournamentState> emit,
  ) async {
    try {
      emit(TournamentOperationInProgress('Registering for tournament...'));
      
      final success = await _tournamentService.registerPlayer(
        event.tournamentId,
        event.playerId,
      );

      if (success) {
        emit(TournamentRegistrationSuccess('Successfully registered for tournament'));
      } else {
        emit(TournamentError('Failed to register for tournament'));
      }
    } catch (e) {
      emit(TournamentError('Failed to register for tournament: ${e.toString()}'));
    }
  }

  Future<void> _onUnregisterFromTournament(
    UnregisterFromTournament event,
    Emitter<TournamentState> emit,
  ) async {
    try {
      emit(TournamentOperationInProgress('Unregistering from tournament...'));
      
      final success = await _tournamentService.unregisterPlayer(
        event.tournamentId,
        event.playerId,
      );

      if (success) {
        emit(TournamentUnregistrationSuccess('Successfully unregistered from tournament'));
      } else {
        emit(TournamentError('Failed to unregister from tournament'));
      }
    } catch (e) {
      emit(TournamentError('Failed to unregister from tournament: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateTournamentMatches(
    GenerateTournamentMatches event,
    Emitter<TournamentState> emit,
  ) async {
    try {
      emit(TournamentOperationInProgress('Generating tournament matches...'));
      
      final success = await _tournamentService.generateTournamentMatches(
        event.tournamentId,
        event.adminUserId,
      );

      if (success) {
        final tournament = await _tournamentService.getTournament(event.tournamentId);
        if (tournament != null) {
          emit(TournamentMatchesGenerated(tournament));
        } else {
          emit(TournamentError('Tournament matches generated but failed to reload tournament'));
        }
      } else {
        emit(TournamentError('Failed to generate tournament matches'));
      }
    } catch (e) {
      emit(TournamentError('Failed to generate tournament matches: ${e.toString()}'));
    }
  }

  Future<void> _onStartTournament(
    StartTournament event,
    Emitter<TournamentState> emit,
  ) async {
    try {
      emit(TournamentOperationInProgress('Starting tournament...'));
      
      final success = await _tournamentService.startTournament(
        event.tournamentId,
        event.adminUserId,
      );

      if (success) {
        final tournament = await _tournamentService.getTournament(event.tournamentId);
        if (tournament != null) {
          emit(TournamentStarted(tournament));
        } else {
          emit(TournamentError('Tournament started but failed to reload tournament'));
        }
      } else {
        emit(TournamentError('Failed to start tournament'));
      }
    } catch (e) {
      emit(TournamentError('Failed to start tournament: ${e.toString()}'));
    }
  }

  Future<void> _onCompleteTournament(
    CompleteTournament event,
    Emitter<TournamentState> emit,
  ) async {
    try {
      emit(TournamentOperationInProgress('Completing tournament...'));
      
      final success = await _tournamentService.completeTournament(
        event.tournamentId,
        event.adminUserId,
      );

      if (success) {
        final tournament = await _tournamentService.getTournament(event.tournamentId);
        if (tournament != null) {
          emit(TournamentCompleted(tournament));
        } else {
          emit(TournamentError('Tournament completed but failed to reload tournament'));
        }
      } else {
        emit(TournamentError('Failed to complete tournament'));
      }
    } catch (e) {
      emit(TournamentError('Failed to complete tournament: ${e.toString()}'));
    }
  }

  Future<void> _onCancelTournament(
    CancelTournament event,
    Emitter<TournamentState> emit,
  ) async {
    try {
      emit(TournamentOperationInProgress('Cancelling tournament...'));
      
      final success = await _tournamentService.cancelTournament(
        event.tournamentId,
        event.adminUserId,
      );

      if (success) {
        final tournament = await _tournamentService.getTournament(event.tournamentId);
        if (tournament != null) {
          emit(TournamentCancelled(tournament));
        } else {
          emit(TournamentError('Tournament cancelled but failed to reload tournament'));
        }
      } else {
        emit(TournamentError('Failed to cancel tournament'));
      }
    } catch (e) {
      emit(TournamentError('Failed to cancel tournament: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateTournament(
    UpdateTournament event,
    Emitter<TournamentState> emit,
  ) async {
    try {
      emit(TournamentOperationInProgress('Updating tournament...'));
      
      final success = await _tournamentService.updateTournament(
        event.tournament,
        event.adminUserId,
      );

      if (success) {
        emit(TournamentUpdated(event.tournament));
      } else {
        emit(TournamentError('Failed to update tournament'));
      }
    } catch (e) {
      emit(TournamentError('Failed to update tournament: ${e.toString()}'));
    }
  }

  Future<void> _onLoadTournamentDetails(
    LoadTournamentDetails event,
    Emitter<TournamentState> emit,
  ) async {
    try {
      emit(TournamentLoading());
      
      final tournament = await _tournamentService.getTournament(event.tournamentId);
      
      if (tournament != null) {
        emit(TournamentDetailsLoaded(tournament));
      } else {
        emit(TournamentError('Tournament not found'));
      }
    } catch (e) {
      emit(TournamentError('Failed to load tournament details: ${e.toString()}'));
    }
  }
}