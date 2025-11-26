import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({Key? key}) : super(key: key);

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool isEditMode = false;
  bool _loading = true;

  late TextEditingController nameC;
  late TextEditingController ageC;
  late TextEditingController genderC;
  late TextEditingController emailC;
  late TextEditingController addressC;
  late TextEditingController diseaseC;
  late TextEditingController specializationC;
  late TextEditingController clinicNameC;

  String imageBase64 = "";
  String mobile = "";
  String type = "";
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    nameC = TextEditingController();
    ageC = TextEditingController();
    genderC = TextEditingController();
    emailC = TextEditingController();
    addressC = TextEditingController();
    diseaseC = TextEditingController();
    specializationC = TextEditingController();
    clinicNameC = TextEditingController();

    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    nameC.text = prefs.getString("name") ?? "";
    ageC.text = prefs.getString("age") ?? "";
    genderC.text = prefs.getString("gender") ?? "";
    emailC.text = prefs.getString("email") ?? "";
    addressC.text = prefs.getString("address") ?? "";
    mobile = prefs.getString("mobile") ?? "";
    imageBase64 = prefs.getString("imageBase64") ?? "";
    type = prefs.getString("type") ?? "";

    if (type == "doctor") {
      specializationC.text = prefs.getString("specialization") ?? "";
      clinicNameC.text = prefs.getString("clinicName") ?? "";
    } else {
      diseaseC.text = prefs.getString("diseaseType") ?? "";
    }

    setState(() => _loading = false);
  }

  ImageProvider _decode() {
    try {
      if (imageBase64.isEmpty) {
        return const AssetImage("assets/images/default_user.png");
      }

      final clean = imageBase64.replaceAll("\n", "").replaceAll(" ", "");
      return MemoryImage(base64Decode(clean));
    } catch (e) {
      return const AssetImage("assets/images/default_user.png");
    }
  }

  void toggleEdit() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  // Future<void> pickPhoto() async {
  //   if (!isEditMode) return;
  //
  //   final XFile? file = await picker.pickImage(source: ImageSource.gallery);
  //
  //   if (file != null) {
  //     final bytes = await file.readAsBytes();
  //     setState(() {
  //       imageBase64 = base64Encode(bytes);
  //     });
  //   }
  // }
  Future<void> pickPhoto() async {
    if (!isEditMode) return;

    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,   // <<< CAMERA instead of GALLERY
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );

    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        imageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> updateProfile() async {
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Mobile missing")));
      return;
    }

    final Map<String, dynamic> updates = {
      "name": nameC.text.trim(),
      "age": ageC.text.trim(),
      "gender": genderC.text.trim(),
      "email": emailC.text.trim(),
      "address": addressC.text.trim(),
      "imageBase64": imageBase64,
    };

    if (type == "doctor") {
      updates["specialization"] = specializationC.text.trim();
      updates["clinicName"] = clinicNameC.text.trim();
    } else {
      updates["diseaseType"] = diseaseC.text.trim();
    }

    final ref = FirebaseDatabase.instance
        .ref("users")
        .child(type)
        .child(mobile);

    await ref.update(updates);

    final prefs = await SharedPreferences.getInstance();

    // Wait for all writes to finish
    final futures = <Future<bool>>[];
    updates.forEach((key, value) {
      futures.add(prefs.setString(key, value));
    });
    await Future.wait(futures);

    setState(() {
      isEditMode = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Profile updated")));

    // Pop and return updated data so the caller can refresh UI immediately
    Navigator.pop(context, updates);
  }

  Widget field(String label, TextEditingController c, {bool multi = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          enabled: isEditMode,
          maxLines: multi ? 2 : 1,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff6D8EBE),
      floatingActionButton: isEditMode
          ? FloatingActionButton.extended(
        onPressed: updateProfile,
        label: const Text("Update"),
        icon: const Icon(Icons.save),
      )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.arrow_back, color: Colors.white),
                    const Text("My Profile",
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                    IconButton(
                        onPressed: toggleEdit,
                        icon: Icon(
                          isEditMode ? Icons.close : Icons.edit,
                          color: Colors.white,
                          size: 30,
                        ))
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xffF9FEFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: pickPhoto,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _decode(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        field("Name", nameC),
                        field("Age", ageC),
                        field("Gender", genderC),
                        field("Email", emailC),
                        field("Address", addressC, multi: true),

                        if (type != "doctor")
                          field("Disease", diseaseC),

                        if (type == "doctor")
                          field("Specialization", specializationC),

                        if (type == "doctor")
                          field("Clinic Name", clinicNameC),
                      ],
                    ),
                  ),
                ),
              )
            ],
          )),
    );
  }
}
