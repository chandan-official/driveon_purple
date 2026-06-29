import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../api/api_service.dart';
import '../../../api/socket_service.dart';
import '../../../core/constants/color_constants.dart';
import 'chat_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final ApiService _api = ApiService();
  final SocketService _socketService = SocketService();
  
  bool _isLoading = true;
  List<dynamic> _threads = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initInbox();
  }

  Future<void> _initInbox() async {
    final token = await _api.loadToken();
    if (token != null) {
      _socketService.connect(token);
    }
    
    // Load profile to identify who 'I' am
    final profileRes = await _api.getUserProfile();
    if (profileRes is Map && profileRes['success'] == true) {
      _currentUserId = profileRes['data']['_id'];
    }

    _loadThreads();

    // Listen to realtime thread updates
    _socketService.onThreadUpdated.listen((_) {
      if (mounted) {
        _loadThreads(showLoading: false);
      }
    });

    _socketService.onMessage.listen((_) {
      if (mounted) {
        _loadThreads(showLoading: false);
      }
    });
  }

  Future<void> _loadThreads({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    
    try {
      final res = await _api.getChatThreads();
      if (res is Map && res['success'] == true && res['data'] is List) {
        if (mounted) {
          setState(() {
            _threads = res['data'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Handle name based on role
  String _getOtherPersonName(Map<String, dynamic> thread) {
    if (_currentUserId == null) return "Unknown";
    
    final passengerIdObj = thread['passengerId'];
    final driverUserIdObj = thread['driverUserId'];

    if (passengerIdObj != null && passengerIdObj['_id'] == _currentUserId) {
      // I am passenger, show driver
      return driverUserIdObj?['fullname'] ?? 'Driver';
    } else {
      // I am driver, show passenger
      return passengerIdObj?['fullname'] ?? 'Passenger';
    }
  }

  // Same for role
  String _getOtherPersonRole(Map<String, dynamic> thread) {
    if (_currentUserId == null) return "";
    final passengerIdObj = thread['passengerId'];
    if (passengerIdObj != null && passengerIdObj['_id'] == _currentUserId) {
      return "Driver";
    }
    return "Passenger";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: AppColors.backgroundDark,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _threads.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("No messages yet", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _threads.length,
              itemBuilder: (context, index) {
                final t = _threads[index];
                
                final name = _getOtherPersonName(t);
                final role = _getOtherPersonRole(t);
                final lastMsg = t['lastMessageText'] ?? 'No messages yet';
                final unread = t['unreadCount'] ?? 0;
                final bookingIdObj = t['bookingId'];
                final String bookingId = bookingIdObj is Map ? bookingIdObj['_id'] ?? "" : bookingIdObj?.toString() ?? "";
                final bool isActive = t['isActive'] ?? false;

                if (bookingId.isEmpty) return const SizedBox.shrink();

                return InkWell(
                  onTap: () {
                    // Navigate to chat detail
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          bookingId: bookingId,
                          otherPersonName: name, 
                          otherPersonRole: role,
                        ),
                      ),
                    ).then((_) {
                      // refresh when coming back
                      _loadThreads(showLoading: false);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 20, color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text("CLOSED", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lastMsg,
                                style: GoogleFonts.inter(
                                  fontSize: 14, 
                                  color: unread > 0 ? AppColors.textDark : Colors.grey.shade600,
                                  fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 10),
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryPurple,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unread.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
