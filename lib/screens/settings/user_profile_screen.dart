import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seba/features/auth/auth_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isUploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // ضغط مبدئي للصورة
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    setState(() {
      _isUploadingImage = true; // إظهار المؤشر
    });

    try {
      final authService = AuthService();
      await authService.updateProfileImage(file);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الصورة الشخصية بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء رفع الصورة: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false; // إخفاء المؤشر
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("الصفحة الشخصية"), centerTitle: true),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("لم يتم العثور على بيانات المستخدم"),
            );
          }

          final userData = snapshot.data!.data()!;
          final String name = userData['name'] ?? 'بدون اسم';
          final String email = userData['email'] ?? '';
          final String photoUrl = userData['photoUrl'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // 🖼️ عرض الصورة مع زري التحميل والكاميرا بتنسيق مظبوط
                Center(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior:
                          Clip.none, // ليظهر زر الكاميرا خارج الحدود برتابة
                      children: [
                        // 1. الصورة الشخصية
                        buildProfileAvatar(
                          photoUrl,
                          isUploading: _isUploadingImage,
                        ),

                        // 2. مؤشر التحميل عند التحديث
                        if (_isUploadingImage)
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),

                        // 3. زر إضافة/تغيير الصورة (الكاميرا)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            radius: 18,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                              onPressed: _isUploadingImage
                                  ? null
                                  : _pickAndUploadImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 30),
                const Divider(),

                // باقي بيانات ومعلومات المدرس...
              ],
            ),
          );
        },
      ),
    );
  }
}

/// دالة مساعدة معالجة لصورة الـ Base64 ورابط الـ HTTP
Widget buildProfileAvatar(String photoUrl, {required bool isUploading}) {
  ImageProvider? imageProvider;

  if (photoUrl.isNotEmpty) {
    if (photoUrl.startsWith('http')) {
      // 🌐 صورة قادمة من جوجل أو رابط عادي
      imageProvider = NetworkImage(photoUrl);
    } else if (photoUrl.startsWith('data:image')) {
      // 🔤 صورة Base64 مخزنة في Firestore
      try {
        final base64Data = photoUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        imageProvider = MemoryImage(bytes);
      } catch (e) {
        print('خطأ في فك تشفير Base64: $e');
      }
    }
  }

  return CircleAvatar(
    radius: 60,
    backgroundColor: Colors.grey[300],
    backgroundImage: imageProvider,
    child: (imageProvider == null && !isUploading)
        ? const Icon(Icons.person, size: 60, color: Colors.grey)
        : null,
  );
}
