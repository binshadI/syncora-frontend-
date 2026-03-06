
class FriendreqResponsetModel {
  String message;

  FriendreqResponsetModel({
    required this.message,
  });

  factory FriendreqResponsetModel.fromJson(Map<String,dynamic>json){
    return FriendreqResponsetModel(message: json['message']?? '' ,);
  }
  Map<String,dynamic> toJson(){
    return{
      'message':message,
  };
  }

}
