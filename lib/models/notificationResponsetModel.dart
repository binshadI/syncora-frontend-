class Request {
  String id;
  From from;

  Request({
    required this.id,
    required this.from,
  });

  factory Request.fromJson(Map<String, dynamic> json) =>
      Request(
        id: json["_id"],
        from: From.fromJson(json["from"]),
      );
}

class From {
  String email;

  From({required this.email});

  factory From.fromJson(Map<String, dynamic> json) =>
      From(
        email: json["email"],
      );
}