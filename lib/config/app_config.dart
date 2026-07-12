class AppConfig {
  
  static const String baseUrl = 'http://192.168.1.27:8000/api';
  
  
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String doctorsEndpoint = '/doctors';
  static const String specialtiesEndpoint = '/specialties';
  static const String appointmentsEndpoint = '/appointments';
  static const String bookAppointmentEndpoint = '/appointments/book';
  static const String myAppointmentsEndpoint = '/my-appointments';
  
  static const String accessTokenKey = 'access_token';
  static const String userKey = 'user';
}