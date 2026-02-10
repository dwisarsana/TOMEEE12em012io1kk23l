// onboard.dart — Onboarding (Cupertino-first, Flutter 3.8+ safe)
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============== Helpers ==============
String safeString(String input) {
  return input.replaceAll(RegExp(
      r'([^\u0000-\uD7FF\uE000-\uFFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?<![\uD800-\uDBFF])[\uDC00-\uDFFF])'), '');
}

// ============== Model ==============
class ChatMessage {
  final String role; // 'bot' or 'user'
  final String text;
  ChatMessage({required this.role, required this.text});
}

// ============== Screen ==============
class OnboardingChatScreen extends StatefulWidget {
  final VoidCallback? onFinish;
  const OnboardingChatScreen({Key? key, this.onFinish}) : super(key: key);

  @override
  State<OnboardingChatScreen> createState() => _OnboardingChatScreenState();
}

enum OnboardStatus { showQuestion, typingExplain, waitUser }

class _OnboardingChatScreenState extends State<OnboardingChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  int _step = 0;

  // Typing states
  String _typingText = "";
  bool _isTyping = false;
  Timer? _typingTimer;

  int? _selectedChoice;
  OnboardStatus _status = OnboardStatus.showQuestion;

  // Brand palette (selaras dengan app)
  static const _indigo = Color(0xFF5865F2); // brand primary
  static const _violet = Color(0xFF8B5CF6); // brand secondary
  static const _bgTop  = Color(0xFFEEF2FF); // soft bg grad 1
  static const _bgBot  = Color(0xFFF6F7FB); // soft bg grad 2
  static const _ink    = Color(0xFF111827); // text
  static const _chip   = Color(0xFFF5F7FF); // bubble bg (bot)

  // ============== Questions (Tome AI) ==============
  final List<Map<String, dynamic>> _questions = [
    {
      "q": "✨ Welcome to Tome AI!\n\nWhat will you create today?",
      "choices": [
        "Pitch deck",
        "Company profile",
        "Education / Lecture",
        "Marketing report",
        "Portfolio"
      ],
      "explain": [
        "Great—let’s shape a persuasive pitch with clear storyline.",
        "Nice—clean company intro with team, services, and traction.",
        "Awesome—structured slides for lessons and takeaways.",
        "Perfect—data-first layout with charts and insights.",
        "Cool—visual showcase with projects and highlights."
      ]
    },
    {
      "q": "Pick your preferred visual style:",
      "choices": [
        "Minimal clean",
        "Corporate modern",
        "Gradient & bold",
        "Playful / illustrative",
        "Dark mode",
        "Not sure"
      ],
      "explain": [
        "Minimal = focus on clarity and whitespace.",
        "Corporate = confident typography + subtle accents.",
        "Gradient & bold = vibrant covers and striking headers.",
        "Playful = friendly shapes and soft illustrations.",
        "Dark mode = cinematic look with high contrast.",
        "No worries—AI will suggest a matching visual system!"
      ]
    },
    {
      "q": "What will your slides include (mostly)?",
      "choices": [
        "Charts & data",
        "Process diagrams",
        "Product screenshots",
        "Icons & illustrations",
        "Photos",
        "Let AI mix"
      ],
      "explain": [
        "We’ll prioritise chart-ready layouts and data clarity.",
        "We’ll add flows, timelines, and step-by-step visuals.",
        "We’ll frame screenshots clearly with callouts.",
        "We’ll use cohesive iconography and clean graphics.",
        "We’ll choose imagery that supports the narrative.",
        "Got it—AI will balance elements automatically."
      ]
    },
    {
      "q": "Where will you present or export?",
      "choices": [
        "In-person meeting",
        "Online meeting",
        "Share link",
        "Export PPTX / PDF"
      ],
      "explain": [
        "We’ll tune font sizes and contrast for room screens.",
        "We’ll optimise for screen-share clarity and pacing.",
        "We’ll keep it scannable and easy to browse.",
        "Export options will be ready when you’re done."
      ]
    },
    {
      "q": "Ready to start?",
      "choices": [
        "Start with AI",
        "Blank presentation"
      ],
      "explain": [
        "Great—AI will draft your outline and slide flow.",
        "Nice—open a clean canvas and build as you go."
      ]
    }
  ];

  // ============== Lifecycle ==============
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      _showBotQuestion(_questions[0]['q']);
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  // ============== Bot typing logic ==============
  void _showBotQuestion(String text) {
    _typingTimer?.cancel();
    setState(() {
      _isTyping = true;
      _typingText = "";
      _status = OnboardStatus.showQuestion;
      _selectedChoice = null;
    });
    int i = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (i < text.length) {
        _typingText += text[i];
        i++;
        _scrollToBottom();
      } else {
        timer.cancel();
        setState(() {
          _messages.add(ChatMessage(role: 'bot', text: text));
          _isTyping = false;
          _typingText = "";
          _status = OnboardStatus.waitUser;
        });
        _scrollToBottom();
      }
    });
  }

  void _showBotExplain(String text) {
    _typingTimer?.cancel();
    setState(() {
      _isTyping = true;
      _typingText = "";
      _status = OnboardStatus.typingExplain;
    });
    int i = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (i < text.length) {
        _typingText += text[i];
        i++;
        _scrollToBottom();
      } else {
        timer.cancel();
        setState(() {
          _messages.add(ChatMessage(role: 'bot', text: text));
          _isTyping = false;
          _typingText = "";
        });
        _scrollToBottom();
        Future.delayed(const Duration(milliseconds: 350), () {
          if (_step < _questions.length - 1) {
            setState(() => _step++);
            _showBotQuestion(_questions[_step]['q']);
          } else {
            _onFinishOnboarding();
          }
        });
      }
    });
  }

  Future<void> _onSelectChoice(int idx) async {
    if (_isTyping || _selectedChoice != null || _status != OnboardStatus.waitUser) return;

    setState(() {
      _selectedChoice = idx;
      _messages.add(ChatMessage(role: 'user', text: _questions[_step]['choices'][idx]));
      _status = OnboardStatus.typingExplain;
    });

    await Future.delayed(const Duration(milliseconds: 400));
    _showBotExplain(_questions[_step]['explain'][idx]);
  }

  Future<void> _onFinishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await Future.delayed(const Duration(milliseconds: 700));
    widget.onFinish?.call();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ============== UI bits (Cupertino) ==============
  Widget _avatar({required bool isBot}) {
    final bg = isBot ? _indigo : _violet;
    final icon = isBot ? CupertinoIcons.sparkles : CupertinoIcons.person_alt_circle;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.06),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: CupertinoColors.white, size: 24),
    );
  }

  Widget _bubble({
    required bool isBot,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.only(
        bottom: 10,
        left: isBot ? 0 : 40,
        right: isBot ? 40 : 0,
      ),
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
        decoration: BoxDecoration(
          gradient: isBot
              ? const LinearGradient(
            colors: [_chip, Color(0xFFF8F9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [_indigo, _violet],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isBot ? 0 : 16),
            bottomRight: Radius.circular(isBot ? 16 : 0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.06),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _typingBubble() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _avatar(isBot: true),
        const SizedBox(width: 8),
        Flexible(
          child: _bubble(
            isBot: true,
            child: Text(
              "...",
              style: GoogleFonts.poppins(
                color: _ink.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                fontSize: 15,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _choiceButton(String label, bool selected, VoidCallback? onPressed) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      color: selected ? CupertinoColors.systemGrey3 : _indigo,
      borderRadius: BorderRadius.circular(16),
      onPressed: onPressed,
      child: Text(
        safeString(label),
        style: GoogleFonts.poppins(
          color: CupertinoColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14.2,
        ),
      ),
    );
  }

  // ============== Build ==============
  @override
  Widget build(BuildContext context) {
    final renderMessages = List<ChatMessage>.of(_messages);
    final currentQ = (_step < _questions.length) ? _questions[_step] : null;

    return CupertinoPageScaffold(
      backgroundColor: _bgBot,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "Tome AI",
          style: GoogleFonts.poppins(
            color: _indigo,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        border: null,
        backgroundColor: _bgBot.withOpacity(0.8),
      ),
      child: SafeArea(
        bottom: true,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "Tell us about your presentation",
              style: GoogleFonts.poppins(
                color: const Color(0x99000000),
                fontWeight: FontWeight.w600,
                fontSize: 14.8,
              ),
            ),
            const SizedBox(height: 8),

            // Messages
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_bgTop, _bgBot],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  itemCount: renderMessages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_isTyping && i == renderMessages.length) {
                      return _typingBubble();
                    }
                    final m = renderMessages[i];
                    final isBot = m.role == 'bot';
                    return Row(
                      mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isBot) ...[
                          _avatar(isBot: true),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: _bubble(
                            isBot: isBot,
                            child: Text(
                              safeString(m.text),
                              style: GoogleFonts.poppins(
                                color: isBot ? _ink : CupertinoColors.white,
                                fontWeight: isBot ? FontWeight.w500 : FontWeight.w700,
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                        if (!isBot) ...[
                          const SizedBox(width: 8),
                          _avatar(isBot: false),
                        ]
                      ],
                    );
                  },
                ),
              ),
            ),

            // Choices
            if (currentQ != null && !_isTyping && _status == OnboardStatus.waitUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 28.0, left: 8, right: 8),
                child: Wrap(
                  spacing: 9,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List<Widget>.generate(
                    currentQ['choices'].length,
                        (idx) => _choiceButton(
                      currentQ['choices'][idx],
                      _selectedChoice == idx,
                      (_isTyping || _selectedChoice != null)
                          ? null
                          : () => _onSelectChoice(idx),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
