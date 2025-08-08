import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[600],
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('status', isEqualTo: 'waiting')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error fetching data',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No waiting users',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userData = users[index].data() as Map<String, dynamic>;
                final userName = userData['name'] ?? 'Unknown';
                final profileImageUrl = userData['profile'] ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: GestureDetector(
                    onTap: () => _fetchAndShowImages(context, users[index].id),
                    child: _buildGlassCard(userName, profileImageUrl),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassCard(String userName, String profileImageUrl) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // ✅ Profile Image
          Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: profileImageUrl.isNotEmpty
                  ? Image.network(
                profileImageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.account_circle,
                  size: 50,
                  color: Colors.grey[400],
                ),
              )
                  : Icon(
                Icons.account_circle,
                size: 50,
                color: Colors.grey[400],
              ),
            ),
          ),

          // ✅ User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Pending Approval',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ✅ Arrow Icon for better UX
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.chevron_right,
              color: Colors.green,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
  // ✅ Fetch and Display Images in AlertDialog
  void _fetchAndShowImages(BuildContext context, String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();

        String? base64BeforeImage = data?['beforeImage'];
        String? base64AfterImage = data?['completedImage'];
        int? quantity = data?['quantity']; // ✅ Quantity is an int now
        int? totalScores = data?['totalScores'];

        Uint8List? beforeImageBytes;
        Uint8List? afterImageBytes;

        if (base64BeforeImage != null) {
          beforeImageBytes = base64Decode(base64BeforeImage);
        }
        if (base64AfterImage != null) {
          afterImageBytes = base64Decode(base64AfterImage);
        }

        // ✅ Controllers to edit fields
        TextEditingController quantityController =
        TextEditingController(text: quantity?.toString());
        TextEditingController scoresController =
        TextEditingController(text: totalScores?.toString());

        // ✅ Show AlertDialog with Editable Fields
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(16),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Before & After',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ✅ Images Row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ Before Image
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Before',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (beforeImageBytes != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    beforeImageBytes,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 120,
                                  height: 120,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ✅ After Image
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'After',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (afterImageBytes != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    afterImageBytes,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 120,
                                  height: 120,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ✅ Editable Quantity Field (as int)
                    TextFormField(
                      controller: quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.edit, color: Colors.green),
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    // ✅ Editable Total Scores Field
                    TextFormField(
                      controller: scoresController,
                      decoration: InputDecoration(
                        labelText: 'Total Scores',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.star, color: Colors.amber),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                // ✅ Save Button to Update Firestore
                TextButton(
                  onPressed: () async {
                    try {
                      int? newQuantity = int.tryParse(quantityController.text);
                      int? newScore = int.tryParse(scoresController.text);

                      if (newQuantity != null && newScore != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .update({

                          'quantity': newQuantity,
                          'totalScore': FieldValue.increment(newScore),
                          'status': 'ok'
                        });

                        // ✅ Success Feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Data updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        Navigator.of(context).pop(); // ✅ Close dialog
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid input!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update data: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("Error fetching images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}

class GlassmorphicCard extends StatelessWidget {
  final String name;
  final String profileImageUrl;

  const GlassmorphicCard({
    Key? key,
    required this.name,
    required this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white.withOpacity(0.1), // ✅ Glassmorphic effect
      shadowColor: Colors.black.withOpacity(0.2),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : const AssetImage('assets/default_profile.png') as ImageProvider,
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.remove_red_eye, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
