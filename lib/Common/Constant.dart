class Constant {
// static var baseurl = "http://localhost:7007/api/"; //dev
  //  static var baseurl = "https://l3ww2hjs-7007.inc1.devtunnels.ms/"; //dev
   static var baseurl = "http://13.234.217.235:3001/api/"; //dev
  // static var baseurl service 07/"; //dev
  // static var baseurl = "https://cf5f40e34c76.ngro0-free.app/"; //ngrok tunnel
  static var versionNumber = "v1";


  //static var generateOTP = "auth/otp-generate-user/bypass";
  //static var verifyOtp = "auth/otp-verify-user/bypass";
  static var generateOTP = "auth/otp-generate-user";
  static var verifyOtp = "auth/otp-verify-user";
  static var getUserDetails = "$versionNumber/user/get-user-details";
  static var updateUserDetails = "$versionNumber/user/update-details/";
  static var category = "$versionNumber/category";
  static var getAllService = "$versionNumber/services/get-all-services?";
  static var getAllVendors = "$versionNumber/services/get-all-vendors?";
  static var getOffer = "$versionNumber/offers/get-offers?";
  static var getBookmarks = "$versionNumber/bookmarks/get-bookmarks";
  static var postBookmark = "$versionNumber/bookmarks/add-bookmark";
  static var postPlaceId = "$versionNumber/vendor/capture-external-vendor";
  static var captureVendorService = "$versionNumber/vendor/capture-vendor-service";
  static var removeBookmark = "$versionNumber/bookmarks/remove-bookmark/";
  static var serviceDetails = "$versionNumber/services/service-details/";
  static var postBooking = "$versionNumber/bookings/creating-booking";
  static var uploadFile = "$versionNumber/upload/file";
  static var myBooking = "$versionNumber/bookings/my-bookings";
  static var addRating = "$versionNumber/ratings-review/add-rating-review";
  static var editRating = "$versionNumber/ratings-review/edit-rating-review/";
  static var getReviewRate = "$versionNumber/ratings-review/get-reviews/";
  static var cancelBooking =
      "$versionNumber/bookings/cancel/";
  static var getNotifications = "$versionNumber/notification";
  static var getVendorPackages = "$versionNumber/packages/vendor/";
  static var markTourShown = "$versionNumber/user/mark-tour-shown";

  static double textsise14 = 14;

  static String navid = "navid";
  static String roleType = "roleType";
  static String rupee = "₹";
  static String fbtoken ="fbtoken";
  static String UserID ="UserID";


  static String accessToken = "accessToken";
  static String refreshToken = "refreshToken";
  static String refreshTokenExpireTime = "refreshTokenExpireTime";

  static String firstName = "firstName";
  static String lastName = "lastName";
  static String image = "image";
  static String email = "email";
  static String isEmailVerified = "isEmailVerified";
  static String mobile = "mobile";
  static String isNewUser = "isNewUser";
  static String roleName = "roleName";
  static String id = "id";
  static String location = "location";
  static String lat = "lat";
  static String long = "long";

}
