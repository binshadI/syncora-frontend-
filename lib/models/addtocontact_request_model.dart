class FriendreqRequestModel {
  String searchEmail;

  FriendreqRequestModel({
    required this.searchEmail,
  });

  Map<String,dynamic> toJson() =>{
    "searchEmail" : searchEmail
  };
}