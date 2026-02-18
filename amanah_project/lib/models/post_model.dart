class PostModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String location;
  final String type; 
  final String? status;
  final String? imageUrl;

 
  final String? contactEmail;

  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.location,
    required this.type,
    this.status,
    this.imageUrl,
    this.contactEmail,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      type: json['type'] ?? '',
      status: json['status'],
      imageUrl: json['image_url'],

      
      contactEmail: json['contact_email'],

      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
