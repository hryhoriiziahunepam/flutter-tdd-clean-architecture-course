import 'package:clean_architecture_tdd_course/features/number_trivia/presentation/bloc/number_trivia_bloc.dart';
import 'package:clean_architecture_tdd_course/features/number_trivia/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';

class NumberTriviaPage extends StatelessWidget {
  const NumberTriviaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Number Trivia'),
      ),
      body: SingleChildScrollView(
        child: buildBody(context),
      ),
    );
  }

  BlocProvider<NumberTriviaBloc> buildBody(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NumberTriviaBloc>(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 10),
              // Top half
              BlocBuilder<NumberTriviaBloc, NumberTriviaState>(
                builder: (context, state) {
                  return state.when(
                    empty: () {
                      return const MessageDisplay(
                        message: 'Start searching!',
                      );
                    },
                    loading: () {
                      return const LoadingWidget();
                    },
                    loaded: (numberTrivia) {
                      return TriviaDisplay(numberTrivia: numberTrivia);
                    },
                    error: (message) {
                      return MessageDisplay(
                        message: message,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              // Bottom half
              const TriviaControls(),
            ],
          ),
        ),
      ),
    );
  }
}
