import 'dart:math';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/word_model.dart';
import '../utils/physics.dart';
import '../viewmodels/game_viewmodel.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/score_bar.dart';
import '../widgets/word_item.dart';
import '../widgets/help_button.dart';
import '../services/notification_service.dart';

class AreaScreen extends StatelessWidget {
  const AreaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GameViewModel>();
    return BaseScaffold(
      showLeaf: true,
      withPadding: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            HelpButton(
              helpText: vm.isLastWord() ? 'Открыть случайное слово. Нельзя открыть последнее слово' : 'Открыть случайное слово. Уберите курсор из ячейки',
            ),
            HelpButton(
              word: true,
              helpText: vm.isLastWord() ? 'Открыть выбранное слово. Нельзя открыть последнее слово' : 'Открыть выбранное слово. Выберете ячейку',
            ),
            const SizedBox(
              height: 66,
            ),
          ],
        ),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          toolbarHeight: 76.0,
          flexibleSpace: const ScoreBar(
            withPadding: true,
            showLevel: true,
            prevScreen: 'Level',
          ),
          backgroundColor: Colors.transparent,
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
            vm.clearActiveWord();
          },
          child: const _NestedScroll(),
        ),
      ),
    );
  }
}

class _NestedScroll extends StatefulWidget {
  const _NestedScroll({Key? key}) : super(key: key);

  @override
  __NestedScrollState createState() => __NestedScrollState();
}

class __NestedScrollState extends State<_NestedScroll> {
  final dataKey = GlobalKey();
  late final ScrollController _scrollCtrl;
  double widthOffset = 0.0;
  double wordWidth = 160.0;
  double itemHeight = 66.0;

  @override
  void initState() {
    _scrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final notifications = NotificationService();
      notifications.init(context: context);
    });
    super.initState();
  }

  _ensureScroll(BuildContext ctx) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) ctx.read<GameViewModel>().scrollToWidget();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GameViewModel>();
    final groups = vm.groups;
    late final WordModel firstWord;
    int countWord = 0;

    final double minContainerHeight = MediaQuery.of(context).size.height - 70;
    const double bottomContainerPadding = 66;

    _ensureScroll(context);
    final advContainerWidth = MediaQuery.of(context).size.width - wordWidth;

    return NotificationListener<ScrollEndNotification>(
      onNotification: (end) {
        setState(() {
          widthOffset = _scrollCtrl.offset;
        });
        return true;
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: CustomScrollPhysics(itemDimension: wordWidth),
              controller: _scrollCtrl,
              child: Row(
                children: [
                  ...groups.map((group) {
                    final index = vm.groups.indexOf(group);
                    final page = (widthOffset / wordWidth).floor();

                    var itemCounts = vm.groups[page > 0 ? page : 0].length;

                    return Container(
                      height: (itemCounts + 1) * itemHeight,
                      constraints: BoxConstraints(minHeight: minContainerHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...group.map((word) {
                            final key = word == vm.scrollableWord ? dataKey : null;
                            if (key != null) {
                              vm.scrollKey = key;
                            }

                            final showEndLeaf = (widthOffset / wordWidth).floor() <= index;
                            final showStartLeaf = (widthOffset / wordWidth).floor() == index;
                            countWord += 1;
                            if (countWord == 1) firstWord = word;

                            return AnimatedBuilder(
                              animation: _scrollCtrl,
                              builder: (context, child) {
                                final page = max((widthOffset / wordWidth).floor(), 0);
                                final position = _recalculateOffset(
                                  maxItems: groups[page].length,
                                  depth: word.depth,
                                );

                                return AnimatedContainer(
                                  width: wordWidth,
                                  height: itemHeight,
                                  duration: const Duration(milliseconds: 150),
                                  margin: EdgeInsets.only(
                                    right: 0,
                                    top: position,
                                    bottom: position,
                                  ),
                                  child: child,
                                );
                              },
                              child: WordItem(
                                key: key,
                                word: word,
                                showEndLeaf: showEndLeaf,
                                showStartLeaf: showStartLeaf,
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: bottomContainerPadding),
                        ],
                      ),
                    );
                  }).toList(),
                  Container(width: advContainerWidth),
                ],
              ),
            ),
          ),
          Positioned(
            top: (minContainerHeight / 2) - bottomContainerPadding - (itemHeight / 2),
            left: wordWidth / 2 - 44,
            child: _buildLottie(firstWord),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: Center(
              child: AnimatedSmoothIndicator(
                activeIndex: max(((_scrollCtrl.hasClients ? _scrollCtrl.offset : 0) / wordWidth).floor(), 0),
                count: groups.length,
                effect: const ExpandingDotsEffect(
                  dotWidth: 12,
                  dotHeight: 8,
                  expansionFactor: 2,
                  dotColor: Color.fromRGBO(169, 126, 74, 1),
                  activeDotColor: Color.fromRGBO(255, 244, 205, 1),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  double _recalculateOffset({required int maxItems, required int depth}) {
    final totalItemsHeight = maxItems * itemHeight;
    final totalDepthHeight = totalItemsHeight - (depth * itemHeight);
    final offsetValue = max<double>((totalDepthHeight / depth) / 2, 0.0);

    return offsetValue;
  }

  Widget _buildLottie(WordModel firstWord) {
    final levelId = context.read<GameViewModel>().getLevelIndex();
    final isFirstLevelComplete = context.read<GameViewModel>().isFirstLevelComplete;
    final skipLottie = levelId == 1 && !isFirstLevelComplete && firstWord.state != WordState.correct;
    if (!skipLottie) return const SizedBox.shrink();

    const String assetName = 'assets/lottie/word_item_animation.json';
    return IgnorePointer(
      ignoring: true,
      child: Lottie.asset(
        assetName,
        width: 120,
        alignment: Alignment.center,
      ),
    );
  }
}
