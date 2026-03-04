  class VerificationRequestModel {
    String email;
    String otp;

    VerificationRequestModel({
      required this.email,
      required this.otp,
    });

    Map<String,dynamic> toJson()=>{
      "email":email,
      "otp":otp,
    };

  }

