import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiChatScreen extends StatefulWidget {
  final UserModel user;
  final ProfileModel? profile;
  final String? initialQuestion;

  const AiChatScreen({
    Key? key,
    required this.user,
    this.profile,
    this.initialQuestion,
  }) : super(key: key);

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<String> _quickPrompts = [
    "What do SPH & CYL numbers mean?",
    "How to apply eye drops properly?",
    "Tips for digital eye strain relief",
    "When should I get a dilated eye exam?",
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(
      ChatMessage(
        text: "Hello ${widget.profile?.name ?? widget.user.name}! I'm your Specz.co AI Eye Care Assistant. Ask me anything about your prescription, eye drop schedule, or vision health tips.",
        isUser: false,
      ),
    );

    if (widget.initialQuestion != null && widget.initialQuestion!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSendMessage(widget.initialQuestion!);
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = text.trim();
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: userMsg, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1000));

    String reply = _generateAiResponse(userMsg);

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: reply, isUser: false));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  String _generateAiResponse(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains("sph") || lower.contains("cyl") || lower.contains("axis") || lower.contains("prescription")) {
      return "SPH (Sphere) measures lens power for nearsightedness (-) or farsightedness (+). CYL (Cylinder) and Axis indicate astigmatism. Always check your prescription date to ensure lenses are up to date!";
    } else if (lower.contains("drop") || lower.contains("apply") || lower.contains("alarm")) {
      return "To apply eye drops correctly: tilt your head back, pull your lower eyelid down to form a pocket, squeeze 1 drop, and close your eye gently for 1-2 minutes without blinking. Use the Eye Drop Tracker alarm schedule to stay consistent!";
    } else if (lower.contains("strain") || lower.contains("screen") || lower.contains("computer")) {
      return "To reduce digital eye strain, follow the 20-20-20 rule: every 20 minutes, look at an object 20 feet away for 20 seconds. Also maintain a comfortable monitor distance (20-24 inches) and adjust screen brightness.";
    } else if (lower.contains("doctor") || lower.contains("exam") || lower.contains("checkup")) {
      return "Comprehensive eye exams are recommended once every 12-24 months for adults. If you experience sudden blurred vision, eye pain, or flashes of light, seek immediate professional care.";
    } else {
      return "That's a great question! For specific symptoms or medical diagnosis, always consult an optometrist or ophthalmologist. Is there anything else about your eye care schedule I can help with?";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("AI Eye Assistant", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Specz.co Intelligence", style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withOpacity(0.8))),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Quick Prompts Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _quickPrompts.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(p, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                    backgroundColor: AppTheme.surface,
                    side: const BorderSide(color: AppTheme.border),
                    onPressed: () => _handleSendMessage(p),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                        bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                      ),
                      boxShadow: msg.isUser ? AppTheme.primaryShadow : AppTheme.softShadow,
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser ? Colors.white : AppTheme.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: Row(
                children: const [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppTheme.primary))),
                  SizedBox(width: 8),
                  Text("AI is typing...", style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: AppTheme.inputDecoration(
                        label: "Ask AI Assistant...",
                        prefixIcon: Icons.chat_bubble_outline_rounded,
                      ),
                      onSubmitted: _handleSendMessage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _handleSendMessage(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
