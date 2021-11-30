import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:clean_architecture_tdd_course/core/error/failures.dart';
import 'package:clean_architecture_tdd_course/core/usecases/usecase.dart';
import 'package:clean_architecture_tdd_course/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta/meta.dart';

import '../../../../core/util/input_converter.dart';
import '../../domain/usecases/get_concrete_number_trivia.dart';
import '../../domain/usecases/get_random_number_trivia.dart';

part 'number_trivia_bloc.freezed.dart';

const String SERVER_FAILURE_MESSAGE = 'Server Failure';
const String CACHE_FAILURE_MESSAGE = 'Cache Failure';
const String INVALID_INPUT_FAILURE_MESSAGE =
    'Invalid Input - The number must be a positive integer or zero.';

@freezed
class NumberTriviaEvent with _$NumberTriviaEvent {
  const factory NumberTriviaEvent.getTriviaForConcreteNumber(String numberString) =
      _GetTriviaForConcreteNumber;

  const factory NumberTriviaEvent.getTriviaForRandomNumber() = _GetTriviaForRandomNumber;
}

@freezed
class NumberTriviaState with _$NumberTriviaState {
  const factory NumberTriviaState.empty() = _Empty;

  const factory NumberTriviaState.loading() = _Loading;

  const factory NumberTriviaState.loaded(NumberTrivia trivia) = _Loaded;

  const factory NumberTriviaState.error(String message) = _Error;
}

class NumberTriviaBloc extends Bloc<NumberTriviaEvent, NumberTriviaState> {
  late Emitter<NumberTriviaState> _emit;

  final GetConcreteNumberTrivia getConcreteNumberTrivia;
  final GetRandomNumberTrivia getRandomNumberTrivia;
  final InputConverter inputConverter;

  NumberTriviaBloc({
    required GetConcreteNumberTrivia concrete,
    required GetRandomNumberTrivia random,
    required this.inputConverter,
  })  : getConcreteNumberTrivia = concrete,
        getRandomNumberTrivia = random,
        super(const NumberTriviaState.empty()) {
    on<NumberTriviaEvent>(_eventTransformer);
  }

  Future<void> _eventTransformer(NumberTriviaEvent event, Emitter<NumberTriviaState> emit) {
    _emit = emit;
    return event.when(
      getTriviaForRandomNumber: () => _handleGetTriviaForRandomNumber(),
      getTriviaForConcreteNumber: (numberString) => _handleGetTriviaForConcreteNumber(numberString),
    );
  }

  Future<void> _handleGetTriviaForConcreteNumber(String numberString) async {
    final inputEither = inputConverter.stringToUnsignedInteger(numberString);

    inputEither.fold(
      (failure) => _emit(const NumberTriviaState.error(INVALID_INPUT_FAILURE_MESSAGE)),
      (integer) async {
        _emit(const NumberTriviaState.loading());
        final failureOrTrivia = await getConcreteNumberTrivia(Params(number: integer));
        _eitherLoadedOrErrorState(failureOrTrivia);
      },
    );
  }

  Future<void> _handleGetTriviaForRandomNumber() async {
    _emit(const NumberTriviaState.loading());
    final failureOrTrivia = await getRandomNumberTrivia(NoParams());
    _eitherLoadedOrErrorState(failureOrTrivia);
  }

  void _eitherLoadedOrErrorState(Either<Failure, NumberTrivia> failureOrTrivia) {
    failureOrTrivia.fold(
      (failure) => _emit(NumberTriviaState.error(_mapFailureToMessage(failure))),
      (trivia) => _emit(NumberTriviaState.loaded(trivia)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return SERVER_FAILURE_MESSAGE;
      case CacheFailure:
        return CACHE_FAILURE_MESSAGE;
      default:
        return 'Unexpected error';
    }
  }
}
