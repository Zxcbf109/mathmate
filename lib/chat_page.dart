import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:mathmate/services/vivo_chat_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final VivoAiChatService _chatService = VivoAiChatService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  final List<VivoChatMessage> _historyMessages = <VivoChatMessage>[];

  bool _isLoading = false;
  final FocusNode _inputFocus = FocusNode();

  static const String _systemPrompt =
      '你是一个专业的数学辅导助手，名为蓝心。你应该用友好、专业的态度回答用户提出的数学问题，帮助用户理解和解决数学难题。如果用户问的不是数学问题，你可以友善地引导他们回到数学话题上。请用中文回答。回答时可以使用Markdown格式来展示数学公式、步骤和代码。';

  static const List<String> _suggestions = <String>[
    '如何解一元二次方程？',
    '什么是勾股定理？',
    '三角函数的基本关系有哪些？',
    '如何求函数的极值？',
  ];

  @override
  void initState() {
    super.initState();
    _historyMessages.add(
      VivoChatMessage(role: 'system', content: _systemPrompt),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
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

  Future<void> _sendMessage({String? text}) async {
    final String content = (text ?? _inputController.text).trim();
    if (content.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: content));
      _isLoading = true;
    });
    _scrollToBottom();

    _historyMessages.add(VivoChatMessage(role: 'user', content: content));

    try {
      final String response = await _chatService.sendMessage(_historyMessages);
      _historyMessages.add(
        VivoChatMessage(role: 'assistant', content: response),
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: 'assistant', content: response));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失败: $e'),
            action: SnackBarAction(label: '重试', onPressed: _sendMessage),
          ),
        );
      }
    }
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: _messages.isEmpty && !_isLoading
              ? _buildWelcomeScreen()
              : _buildMessageList(),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 48),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 36,
              color: Color(0xFF3F51B5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '你好！我是蓝心数学助手',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '可以问我任何数学问题，我会一步步帮你解答',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ..._suggestions.map(_buildSuggestionCard),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(String question) {
    return GestureDetector(
      onTap: () => _sendMessage(text: question),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EAED)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.help_outline, size: 18, color: Color(0xFF3F51B5)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                question,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index == _messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _TypingDot(delayMs: 0),
            SizedBox(width: 4),
            _TypingDot(delayMs: 200),
            SizedBox(width: 4),
            _TypingDot(delayMs: 400),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: <Widget>[
              if (!isUser) const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.82,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF3F51B5)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: isUser
                            ? const Color(0xFF3F51B5).withValues(alpha: 0.15)
                            : const Color(0x0A000000),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        )
                      : _buildMarkdownContent(message.content),
                ),
              ),
              if (isUser) const SizedBox(width: 4),
            ],
          ),
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: GestureDetector(
                onTap: () => _copyMessage(message.content),
                child: const Icon(
                  Icons.content_copy,
                  size: 14,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(String text) {
    final List<Widget> blocks = <Widget>[];
    final RegExp mathRegex = RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$');
    final Iterable<RegExpMatch> matches = mathRegex.allMatches(text);

    int lastEnd = 0;
    for (final RegExpMatch match in matches) {
      if (match.start > lastEnd) {
        final String plainText = text.substring(lastEnd, match.start);
        if (plainText.trim().isNotEmpty) {
          blocks.add(_mdWidget(plainText));
        }
      }

      final String? displayMath = match.group(1);
      final String? inlineMath = match.group(2);
      final String mathSource = (displayMath ?? inlineMath ?? '').trim();
      if (mathSource.isNotEmpty) {
        try {
          blocks.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Math.tex(
                mathSource,
                mathStyle: displayMath != null
                    ? MathStyle.display
                    : MathStyle.text,
                textStyle: const TextStyle(fontSize: 15),
              ),
            ),
          );
        } catch (_) {
          blocks.add(
            Text(mathSource, style: const TextStyle(fontFamily: 'monospace')),
          );
        }
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      final String remaining = text.substring(lastEnd);
      if (remaining.trim().isNotEmpty) {
        blocks.add(_mdWidget(remaining));
      }
    }

    if (blocks.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.55,
          color: Color(0xFF333333),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  Widget _mdWidget(String data) {
    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: _mdStyle(context),
    );
  }

  static MarkdownStyleSheet _mdStyle(BuildContext context) {
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: const TextStyle(fontSize: 15, height: 1.55, color: Color(0xFF333333)),
      code: const TextStyle(
        fontSize: 13,
        fontFamily: 'monospace',
        backgroundColor: Color(0xFFF5F5F5),
      ),
      codeblockDecoration: const BoxDecoration(
        color: Color(0xFFF8F8F8),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      h2: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
      ),
      h3: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
      blockquoteDecoration: const BoxDecoration(
        color: Color(0xFFF5F7FF),
        border: Border(left: BorderSide(color: Color(0xFF3F51B5), width: 3)),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocus,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: '输入数学问题...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isLoading
                      ? Colors.grey.shade300
                      : const Color(0xFF3F51B5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _isLoading ? Colors.grey : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delayMs;
  const _TypingDot({required this.delayMs});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: _animation.value,
          child: child,
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF3F51B5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});
}
