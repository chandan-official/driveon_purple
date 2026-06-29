import 'package:flutter/material.dart';
import '../../../api/api_service.dart';
import '../../../api/socket_service.dart';
import '../../../core/constants/color_constants.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String otherPersonName;
  final String otherPersonRole;

  const ChatScreen({
    super.key,
    required this.bookingId,
    this.otherPersonName = "User",
    this.otherPersonRole = "",
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final ApiService _api = ApiService();
  final SocketService _socket = SocketService();

  bool _isLoading = true;
  bool _isActive = true;
  String? _currentUserId;
  
  List<dynamic> _messages = [];
  String _targetName = "";
  String _targetRole = "";

  @override
  void initState() {
    super.initState();
    _targetName = widget.otherPersonName;
    _targetRole = widget.otherPersonRole;
    _initChat();
  }

  Future<void> _initChat() async {
    // 1. Load token FIRST – required for all subsequent API calls
    await _api.loadToken();

    // 2. Identify ourselves
    final profileRes = await _api.getUserProfile();
    if (profileRes is Map && profileRes['success'] == true) {
      _currentUserId = profileRes['data']['_id'];
    }

    // 2. Fetch Thread Metadata to know if active, and get better targetName if needed
    final threadRes = await _api.getChatThreadByBooking(widget.bookingId);
    if (threadRes is Map && threadRes['success'] == true) {
      final t = threadRes['data'];
      _isActive = t['isActive'] ?? false;
      
      // Override names if from backend
      if (_currentUserId != null) {
        final paxId = t['passengerId'];
        if (paxId != null && paxId['_id'] == _currentUserId) {
          _targetName = t['driverUserId']?['fullname'] ?? _targetName;
          _targetRole = "Driver";
        } else {
          _targetName = paxId?['fullname'] ?? _targetName;
          _targetRole = "Passenger";
        }
      }
    }

    // 3. Load Messages
    await _loadMessages();

    // 4. Mark Thread Read
    await _api.markChatAsRead(widget.bookingId);

    // 5. Connect Socket if needed (fallback if not already connected globally)
    final token = await _api.loadToken();
    if (token != null) {
      _socket.connect(token);
      _socket.joinChat(widget.bookingId);
      
      // Setup listeners
      _socket.onMessage.listen((data) {
        if (data['message'] != null && data['message']['bookingId'] == widget.bookingId) {
          if (mounted) {
            setState(() {
              _messages.insert(0, data['message']);
            });
            _api.markChatAsRead(widget.bookingId);
          }
        }
      });

      _socket.onClosed.listen((data) {
        if (data['bookingId'] == widget.bookingId) {
          if (mounted) setState(() => _isActive = false);
        }
      });
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages() async {
    final res = await _api.getChatMessages(widget.bookingId);
    if (res is Map && res['success'] == true) {
      final list = res['data'] as List<dynamic>;
      // sort descending (latest first) assuming backend might return ascending
      // Actually backend says createdAt, lets sort properly
      list.sort((a, b) {
        final tA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final tB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return tB.compareTo(tA); // DESC to fit ListView.builder(reverse:true)
      });
      if (mounted) setState(() => _messages = list);
    }
  }

  @override
  void dispose() {
    _socket.leaveChat(widget.bookingId);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || !_isActive) return;

    _controller.clear();
    
    // Optimsitic UI Insert
    final optimisticMsg = {
      "_id": DateTime.now().millisecondsSinceEpoch.toString(),
      "senderId": {"_id": _currentUserId},
      "text": text,
      "createdAt": DateTime.now().toIso8601String(),
    };
    setState(() => _messages.insert(0, optimisticMsg));

    // Send via REST
    final res = await _api.sendChatMessage(widget.bookingId, text);
    if (res is Map && res['success'] == false) {
      // Revert if failed
      setState(() {
        _messages.removeAt(0);
        if (res['message'].toString().contains('closed')) {
          _isActive = false;
        }
      });
    } else if (res is Map && res['success'] == true) {
      // Replace optimistic with real
      setState(() {
        _messages[0] = res['message'];
      });
    }
  }

  void _makeMaskedCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Calling $_targetName via Masked Number (+91-XXXXX-1234)..."),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.backgroundDark,
              child: Icon(Icons.person, size: 20, color: AppColors.textDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _targetName,
                    style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _targetRole.isNotEmpty ? _targetRole : "Loading...",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green),
            onPressed: _makeMaskedCall,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
        children: [
          // 1. Privacy Notice
          Container(
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            color: Colors.amber.shade50,
            child: Text(
              "For your privacy, phone numbers are masked during calls.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.amber.shade900, fontSize: 10),
            ),
          ),

          if (!_isActive)
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              color: Colors.red.shade50,
              child: Text(
                "Chat is closed since the booking is ended/cancelled.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),

          // 2. Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // Auto focus bottom
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                
                bool isMe = false;
                final sIdObj = msg['senderId'];
                if (sIdObj != null && sIdObj is Map && sIdObj['_id'] == _currentUserId) isMe = true;

                final rawObj = msg['createdAt'];
                String time = "";
                if (rawObj != null && rawObj is String) {
                  final dt = DateTime.tryParse(rawObj)?.toLocal();
                  if (dt != null) {
                    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
                    final ampm = dt.hour >= 12 ? "PM" : "AM";
                    final min = dt.minute.toString().padLeft(2, '0');
                    time = "$h:$min $ampm";
                  }
                }

                return _chatBubble(msg['text'] ?? '', isMe, time);
              },
            ),
          ),

          // 3. Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.backgroundLight,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: _isActive,
                    decoration: InputDecoration(
                      hintText: _isActive ? "Type a message..." : "Chat closed",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isActive ? _sendMessage : null,
                  child: CircleAvatar(
                    backgroundColor: _isActive ? AppColors.primaryPurple : Colors.grey,
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryPurple : AppColors.backgroundLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(color: isMe ? Colors.white : AppColors.textDark, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              time,
              style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
