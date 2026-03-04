class Contact {
  final String username;

  Contact({required this.username});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(username: json["username"] ?? "Unknown");
  }

  Map<String, dynamic> toJson() => {"username": username};
}

class HomeResponse {
  final List<Contact> contacts;

  HomeResponse({required this.contacts});

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json["contact"] ?? []; // ✅ "contact" matches your backend

    return HomeResponse(
      contacts: List<Contact>.from(
        (rawList as List).map((x) => Contact.fromJson(x)),
      ),
    );
  }
}