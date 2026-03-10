class Contact {
  final String username;
  final String friendId; // ← add this

  Contact({required this.username, required this.friendId});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      username: json["username"] ?? "Unknown",
      friendId: json["_id"] ?? "", // ← add this
    );
  }

  Map<String, dynamic> toJson() => {
    "username": username,
    "friendId": friendId,
  };
}
class HomeResponse {
  final List<Contact> contacts;

  HomeResponse({required this.contacts});

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json["contact"] ?? [];
    return HomeResponse(
      contacts: List<Contact>.from(
        (rawList as List).map((x) => Contact.fromJson(x)),
      ),
    );
  }
}