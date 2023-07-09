import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:excel/excel.dart' as excelLib;
import 'package:flutter/src/painting/box_border.dart' as boxbrd;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'questionList.dart';

class QuizQuestion {
  final String question;
  final List<QuizAnswer> answers;
  final int correctAnswerIndex;
  int selectedAnswer;
  String explaination;

  QuizQuestion(
      {required this.question,
      required this.answers,
      required this.correctAnswerIndex,
      this.explaination = "",
      this.selectedAnswer = -1});
}

class QuizAnswer {
  final String answer;
  QuizAnswer({required this.answer});
}

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedAnswerIndex; // Nullable to allow no answer to be selected

  bool isAnswered = false;
  bool isCorrect = false;

  List<QuizQuestion> quizQuestions = questionList;
  List<int?> selectedAnswerIndices = List.filled(questionList.length, null);
  List<bool> answeredQuestions = List.filled(questionList.length, false);

  SharedPreferences? _prefs;
  final String _current_questionKey = 'current_question';
  final String _elapsed_timeKey = 'elapsed_time';

  String stopwatchText = '00:00';
  Stopwatch stopwatch = Stopwatch();
  late Timer timer;

  bool isDarkThemeEnabled = false;

  @override
  void initState() {
    super.initState();
    startStopwatch();

    //final filePath = 'Flutter\lib\questionList.dart';
    //final quizQuestions = readQuestionsFromExcel(filePath);
    //print(quizQuestions);

    // for cache
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _prefs = prefs;
        final currentQuestionCache =
            _prefs!.getStringList(_current_questionKey) ?? [];

        if (currentQuestionCache.isNotEmpty &&
            int.parse(currentQuestionCache.last) < quizQuestions.length) {
          currentQuestionIndex = int.parse(currentQuestionCache.last);
        } else {
          currentQuestionIndex = 0;
        }
      });
    });

    retrieveSelectedAnswers().then((answers) {
      setState(() {
        selectedAnswerIndices = answers;
      });
    });

    retrieveScore().then((value) {
      setState(() {
        score = value;
      });
    });

    retrieveElapsedTime().then((elapsedTime) {
      setState(() {
        stopwatch = Stopwatch()..start();
        //stopwatch.elapsed += Duration(seconds: elapsedTime);
      });
      startStopwatch();
    });

    stopwatch.start();
  }

  @override
  void dispose() {
    stopStopwatch();
    super.dispose();
  }

// Store the elapsed time in the cache
  Future<void> storeElapsedTime(int elapsedTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_elapsed_timeKey, elapsedTime);
  }

  Future<int> retrieveElapsedTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? elapsedTime = prefs.getInt(_elapsed_timeKey);
    return elapsedTime ??
        0; // Return 0 if no elapsed time is found in the cache
  }

  Future<void> storeSelectedAnswers(List<int?> selectedAnswers) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_answers',
        selectedAnswers.map((answer) => answer?.toString() ?? "").toList());
  }

  Future<List<int?>> retrieveSelectedAnswers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? answers = prefs.getStringList('selected_answers');
    return answers
            ?.map((answer) => answer.isNotEmpty ? int.parse(answer) : null)
            .toList() ??
        List.filled(questionList.length, null);
  }

  void storeScore(int score) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('score', score);
  }

  Future<int> retrieveScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? score = prefs.getInt('score');
    return score ?? 0; // Return 0 if no score is found in the cache
  }

  void startStopwatch() {
    stopwatch.start();
    timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {});
    });

    Timer.periodic(Duration(seconds: 1), (timer) {
      final int minutes = (stopwatch.elapsed.inSeconds ~/ 60);
      final int seconds = (stopwatch.elapsed.inSeconds % 60);
      setState(() {
        stopwatchText =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      });
    });
  }

  void stopStopwatch() {
    stopwatch.stop();
    timer.cancel();
    storeElapsedTime(stopwatch.elapsed.inSeconds);
  }

  void checkAnswer(int selectedAnswerIndex) {
    if (!isAnswered) {
      isAnswered = true;
      answeredQuestions[currentQuestionIndex] =
          true; // Mark the question as answered

      if (selectedAnswerIndex ==
          quizQuestions[currentQuestionIndex].correctAnswerIndex) {
        // User selected the correct answer
        setState(() {
          score++;
          isCorrect = true;

          // Store the score in the cache
          storeScore(score);
        });
      } else {
        setState(() {
          isCorrect = false;
        });
      }

      // Store the selected answer index in the cache
      selectedAnswerIndices[currentQuestionIndex] = selectedAnswerIndex;
      storeSelectedAnswers(selectedAnswerIndices);

      // Save the current question index to the cache
      _saveCurrentQuestionToCache(currentQuestionIndex);
    }
  }

  void _saveCurrentQuestionToCache(int questionIndex) async {
    if (_prefs != null) {
      final answeredQuestions =
          _prefs!.getStringList(_current_questionKey) ?? [];

      answeredQuestions.add(questionIndex.toString());
      await _prefs!.setStringList(_current_questionKey, answeredQuestions);
    }
  }

  void skipQuestion(int numToSKip) {
    if (numToSKip == 0) {
      currentQuestionIndex = Random().nextInt(quizQuestions.length - 1);
    }

    if (currentQuestionIndex + numToSKip < quizQuestions.length) {
      setState(() {
        currentQuestionIndex = currentQuestionIndex + numToSKip;
        isAnswered = false;
        isCorrect = false;
        selectedAnswerIndex = selectedAnswerIndices[currentQuestionIndex];
        _saveCurrentQuestionToCache(currentQuestionIndex);
      });
    } else {
      currentQuestionIndex = 0;
      isAnswered = false;
      isCorrect = false;
      selectedAnswerIndex = selectedAnswerIndices[currentQuestionIndex];
      _saveCurrentQuestionToCache(currentQuestionIndex);
    }
  }

  void goBack(int numToSKip) {
    if (currentQuestionIndex > 0 && currentQuestionIndex - numToSKip >= 0) {
      setState(() {
        currentQuestionIndex = currentQuestionIndex - numToSKip;
        isAnswered = answeredQuestions[
            currentQuestionIndex]; // Check if the previous question was answered

        if (isAnswered) {
          // Retrieve the selected answer index and update the correctness indicator
          selectedAnswerIndex = selectedAnswerIndices[currentQuestionIndex];
          isCorrect = selectedAnswerIndex ==
              quizQuestions[currentQuestionIndex].correctAnswerIndex;
        } else {
          //      isCorrect = false; // Reset the correctness indicator
        }

        _saveCurrentQuestionToCache(currentQuestionIndex);
      });
    }
  }

  void resetQuiz() {
    setState(() {
      currentQuestionIndex = 0;
      score = 0;
      selectedAnswerIndex = null;
      isAnswered = false;
      isCorrect = false;
      selectedAnswerIndices = List.filled(questionList.length, null);
      answeredQuestions = List.filled(questionList.length, false);
      stopwatch.reset();

      // Clear the caching data
      _prefs?.remove(_current_questionKey);
      _prefs?.remove('selected_answers');
      _prefs?.remove('score');
      _prefs?.remove(_elapsed_timeKey);
    });

    startStopwatch(); // Restart the stopwatch
  }

  void toggleDarkTheme() {
    setState(() {
      isDarkThemeEnabled = !isDarkThemeEnabled;
      // Apply dark theme using Flutter's ThemeMode
      if (isDarkThemeEnabled) {
        // Enable dark theme
        MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData.dark(),
        );
      } else {
        // Enable light theme
        MaterialApp(
          themeMode: ThemeMode.light,
          theme: ThemeData.light(),
        );
      }
    });
  }

  //----

  List<QuizQuestion> readQuestionsFromExcel(String filePath) {
    final excel = excelLib.Excel.decodeBytes(File(filePath).readAsBytesSync());

    final excelLib.Sheet sheet = excel.tables[excel.tables.keys.first]!;
    final List<QuizQuestion> quizQuestions = [];

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];

      final question = row[0]?.value ?? '';
      final options = [
        row[1]?.value ?? '',
        row[2]?.value ?? '',
        row[3]?.value ?? '',
        row[4]?.value ?? '',
      ];

      final correctAnswerIndex = findCorrectAnswerIndex(row);

      final quizQuestion = QuizQuestion(
        question: question,
        answers: options.map((option) => QuizAnswer(answer: option)).toList(),
        correctAnswerIndex: correctAnswerIndex,
      );

      quizQuestions.add(quizQuestion);
    }

    return quizQuestions;
  }

  int findCorrectAnswerIndex(List<excelLib.Data?> row) {
    for (var i = 5; i < row.length; i++) {
      final cellValue = row[i]?.value ?? '';
      if (cellValue.Trim().toUpperCase() == 'X') {
        return i - 5;
      }
    }
    return -1; // No correct answer found
  }
  //-----------------

  @override
  Widget build(BuildContext context) {
    QuizQuestion currentQuestion = quizQuestions[currentQuestionIndex];

    return Material(
      color: isDarkThemeEnabled
          ? Color.fromARGB(18, 0, 0, 0)
          : Color.fromARGB(255, 243, 221, 221),
      child: Column(
        children: [
          AppBar(
            foregroundColor: Colors.white,
            backgroundColor: isDarkThemeEnabled
                ? Color.fromARGB(255, 18, 18, 18)
                : Colors.blue,
            title: Text('אפליקציה לפינקו'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'שאלה ${currentQuestionIndex + 1}/${quizQuestions.length}',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkThemeEnabled ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      currentQuestion.question,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkThemeEnabled ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 16),
                    Column(
                      children: List.generate(
                        currentQuestion.answers.length,
                        (index) => GestureDetector(
                          onTap: () {
                            if (isAnswered ||
                                answeredQuestions[currentQuestionIndex]) {
                              return;
                            }

                            setState(() {
                              selectedAnswerIndex = index;
                              checkAnswer(selectedAnswerIndex!);
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedAnswerIndex == index
                                  ? (isAnswered && isCorrect
                                      ? Colors.green
                                      : Colors.red)
                                  : (isAnswered &&
                                          currentQuestion.correctAnswerIndex ==
                                              index
                                      ? Color.fromARGB(255, 133, 255, 194)
                                          .withOpacity(0.5)
                                      : (isDarkThemeEnabled
                                          ? Color.fromARGB(255, 160, 110, 153)
                                          : Color.fromARGB(
                                              255, 255, 226, 212))),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedAnswerIndex == index
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            ),
                            child: Wrap(
                              children: [
                                Text(
                                  currentQuestion.answers[index].answer,
                                  overflow: TextOverflow.visible,
                                  maxLines: null,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: selectedAnswerIndex == index
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => goBack(1),
                          child: Text('שאלה קודמת'),
                        ),
                        ElevatedButton(
                          onPressed: resetQuiz,
                          child: Text('אפס הכל'),
                        ),
                        ElevatedButton(
                          onPressed: () => skipQuestion(1),
                          child: Text('שאלה הבאה'),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => goBack(50),
                          child: Text('50 אחורה'),
                        ),
                        ElevatedButton(
                          onPressed: () => skipQuestion(0),
                          child: Text('אקראית'),
                        ),
                        ElevatedButton(
                          onPressed: () => skipQuestion(50),
                          child: Text('50 קדימה'),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),
                    Text(
                      'ענית נכון: $score',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '$stopwatchText',
                      style: TextStyle(fontSize: 16),
                    ),
                    // IconButton(
                    //   onPressed: toggleDarkTheme,
                    //   icon: Icon(
                    //     isDarkThemeEnabled ? Icons.dark_mode : Icons.light_mode,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
