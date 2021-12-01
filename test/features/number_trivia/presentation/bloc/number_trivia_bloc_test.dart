import 'package:clean_architecture_tdd_course/core/error/failures.dart';
import 'package:clean_architecture_tdd_course/core/usecases/usecase.dart';
import 'package:clean_architecture_tdd_course/core/util/input_converter.dart';
import 'package:clean_architecture_tdd_course/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:clean_architecture_tdd_course/features/number_trivia/domain/usecases/get_concrete_number_trivia.dart';
import 'package:clean_architecture_tdd_course/features/number_trivia/domain/usecases/get_random_number_trivia.dart';
import 'package:clean_architecture_tdd_course/features/number_trivia/presentation/bloc/number_trivia_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'number_trivia_bloc_test.mocks.dart';

@GenerateMocks([
  InputConverter
], customMocks: [
  MockSpec<GetConcreteNumberTrivia>(
    as: #MockGetConcreteNumberTrivia,
    returnNullOnMissingStub: true,
  ),
  MockSpec<GetRandomNumberTrivia>(
    as: #MockGetRandomNumberTrivia,
    returnNullOnMissingStub: true,
  ),
])
void main() {
  late NumberTriviaBloc bloc;
  late MockGetConcreteNumberTrivia mockGetConcreteNumberTrivia;
  late MockGetRandomNumberTrivia mockGetRandomNumberTrivia;
  late MockInputConverter mockInputConverter;

  setUp(() {
    mockGetConcreteNumberTrivia = MockGetConcreteNumberTrivia();
    mockGetRandomNumberTrivia = MockGetRandomNumberTrivia();
    mockInputConverter = MockInputConverter();

    bloc = NumberTriviaBloc(
      concrete: mockGetConcreteNumberTrivia,
      random: mockGetRandomNumberTrivia,
      inputConverter: mockInputConverter,
    );
  });

  test('initialState should be Empty', () {
    // assert
    expect(bloc.state, equals(const NumberTriviaState.empty()));
  });

  group('GetTriviaForConcreteNumber', () {
    const tNumberString = '1';
    const tNumberParsed = 1;
    const tNumberTrivia = NumberTrivia(number: 1, text: 'test trivia');

    void setUpMockInputConverterSuccess() => when(mockInputConverter.stringToUnsignedInteger(any))
        .thenReturn(const Right(tNumberParsed));

    test(
      'should call the InputConverter to validate and convert the string to an unsigned integer',
      () async {
        // arrange
        setUpMockInputConverterSuccess();
        // act
        bloc.add(const NumberTriviaEvent.getTriviaForConcreteNumber(tNumberString));
        await untilCalled(mockInputConverter.stringToUnsignedInteger(any));
        // assert
        verify(mockInputConverter.stringToUnsignedInteger(tNumberString));
      },
    );

    test(
      'should emit [Error] when the input is invalid',
      () async {
        // arrange
        when(mockInputConverter.stringToUnsignedInteger(any))
            .thenReturn(Left(InvalidInputFailure()));
        // assert later
        final expected = [
          const NumberTriviaState.empty(),
          const NumberTriviaState.error(INVALID_INPUT_FAILURE_MESSAGE),
        ];
        expectLater(bloc, emitsInOrder(expected));
        // act
        bloc.add(const NumberTriviaEvent.getTriviaForConcreteNumber(tNumberString));
      },
    );

    test(
      'should get data from the concrete use case',
      () async {
        // arrange
        setUpMockInputConverterSuccess();
        when(mockGetConcreteNumberTrivia(any)).thenAnswer((_) async => const Right(tNumberTrivia));
        // act
        bloc.add(const NumberTriviaEvent.getTriviaForConcreteNumber(tNumberString));
        await untilCalled(mockGetConcreteNumberTrivia(any));
        // assert
        verify(mockGetConcreteNumberTrivia(const Params(number: tNumberParsed)));
      },
    );

    test(
      'should emit [Loading, Loaded] when data is gotten successfully',
      () async {
        // arrange
        setUpMockInputConverterSuccess();
        when(mockGetConcreteNumberTrivia(any)).thenAnswer((_) async => const Right(tNumberTrivia));
        // assert later
        final expected = [
          const NumberTriviaState.empty(),
          const NumberTriviaState.loading(),
          const NumberTriviaState.loaded(tNumberTrivia),
        ];
        expectLater(bloc, emitsInOrder(expected));
        // act
        bloc.add(const NumberTriviaEvent.getTriviaForConcreteNumber(tNumberString));
      },
    );

    test(
      'should emit [Loading, Error] when getting data fails',
      () async {
        // arrange
        setUpMockInputConverterSuccess();
        when(mockGetConcreteNumberTrivia(any)).thenAnswer((_) async => Left(ServerFailure()));
        // assert later
        final expected = [
          const NumberTriviaState.empty(),
          const NumberTriviaState.loading(),
          const NumberTriviaState.error(SERVER_FAILURE_MESSAGE),
        ];
        expectLater(bloc, emitsInOrder(expected));
        // act
        bloc.add(const NumberTriviaEvent.getTriviaForConcreteNumber(tNumberString));
      },
    );

    test(
      'should emit [Loading, Error] with a proper message for the error when getting data fails',
      () async {
        // arrange
        setUpMockInputConverterSuccess();
        when(mockGetConcreteNumberTrivia(any)).thenAnswer((_) async => Left(CacheFailure()));
        // assert later
        final expected = [
          const NumberTriviaState.empty(),
          const NumberTriviaState.loading(),
          const NumberTriviaState.error(CACHE_FAILURE_MESSAGE),
        ];
        expectLater(bloc, emitsInOrder(expected));
        // act
        bloc.add(const NumberTriviaEvent.getTriviaForConcreteNumber(tNumberString));
      },
    );
  });

  group('GetTriviaForRandomNumber', () {
    const tNumberTrivia = NumberTrivia(number: 1, text: 'test trivia');

    test(
      'should get data from the random use case',
      () async {
        // arrange
        when(mockGetRandomNumberTrivia(NoParams()))
            .thenAnswer((_) async => const Right(tNumberTrivia));
        // act
        bloc.add(const NumberTriviaEvent.getTriviaForRandomNumber());
        await untilCalled(mockGetRandomNumberTrivia(NoParams()));
        // assert
        verify(mockGetRandomNumberTrivia(NoParams()));
      },
    );

    test(
      'should emit [Loading, Loaded] when data is gotten successfully',
      () async {
        // arrange
        when(mockGetRandomNumberTrivia(NoParams()))
            .thenAnswer((_) async => const Right(tNumberTrivia));
        // assert later
        final expected = [
          const NumberTriviaState.empty(),
          const NumberTriviaState.loading(),
          const NumberTriviaState.loaded(tNumberTrivia),
        ];
        expectLater(bloc, emitsInOrder(expected));
        // act
        bloc.add(const NumberTriviaEvent.getTriviaForRandomNumber());
      },
    );

    test(
      'should emit [Loading, Error] when getting data fails',
      () async {
        // arrange
        when(mockGetRandomNumberTrivia(NoParams())).thenAnswer((_) async => Left(ServerFailure()));
        // assert later
        final expected = [
          const NumberTriviaState.empty(),
          const NumberTriviaState.loading(),
          const NumberTriviaState.error(SERVER_FAILURE_MESSAGE),
        ];
        expectLater(bloc, emitsInOrder(expected));
        // act
        bloc.add(const NumberTriviaEvent.getTriviaForRandomNumber());
      },
    );

    test(
      'should emit [Loading, Error] with a proper message for the error when getting data fails',
      () async {
        // arrange
        when(mockGetRandomNumberTrivia(NoParams())).thenAnswer((_) async => Left(CacheFailure()));
        // assert later
        final expected = [
          const NumberTriviaState.empty(),
          const NumberTriviaState.loading(),
          const NumberTriviaState.error(CACHE_FAILURE_MESSAGE),
        ];
        expectLater(bloc, emitsInOrder(expected));
        // act
        bloc.add(const NumberTriviaEvent.getTriviaForRandomNumber());
      },
    );
  });
}
