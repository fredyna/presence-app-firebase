import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:presence/app/routes/app_pages.dart';

class NewPasswordController extends GetxController {
  RxBool isLoading = false.obs;
  TextEditingController newPassC = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> newPassword() async {
    try {
      if (newPassC.text.isNotEmpty) {
        if (newPassC.text != 'password') {
          isLoading.value = true;
          try {
            await auth.currentUser!.updatePassword(newPassC.text);
            String email = auth.currentUser!.email!;

            await auth.signOut();

            await auth.signInWithEmailAndPassword(
              email: email,
              password: newPassC.text,
            );

            Get.offAllNamed(Routes.HOME);
          } on FirebaseAuthException catch (e) {
            if (e.code == 'weak-password') {
              Get.snackbar("Terjadi Kesalahan",
                  "Password tidak boleh kurang dari 6 karakter!");
            }
          } catch (e) {
            Get.snackbar("Terjadi Kesalahan",
                "Tidak dapat membuat password baru. Hubungi admin atau CS");
          } finally {
            isLoading.value = false;
          }
        } else {
          Get.snackbar('Terjadi Kesalahan', 'Password baru harus diubah.');
        }
      }
    } catch (e) {
      Get.snackbar('Terjadi Kesalahan', 'Password baru wajib diisi.');
    }
  }
}
