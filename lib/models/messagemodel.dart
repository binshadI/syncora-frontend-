class MessageModel {
  final String senderId;
  final String message;
  final String timestamp;

  MessageModel({
    required this.senderId,
    required this.message,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      senderId: json['senderId'],
      message: json['msg'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString()).toLocal().toString().substring(11, 16)
          : DateTime.now().toString().substring(11, 16), // fallback: "HH:mm"
    );
  }
}