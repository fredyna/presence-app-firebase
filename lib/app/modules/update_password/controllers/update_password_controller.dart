import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UpdatePasswordController extends GetxController {
  RxBool isLoading = false.obs;
  TextEditingController currentPasswordC = TextEditingController();
  TextEditingController newPasswordC = TextEditingController();
  TextEditingController confirmPasswordC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> updatePassword() async {
    if (currentPasswordC.text.isNotEmpty &&
        newPasswordC.text.isNotEmpty &&
        confirmPasswordC.text.isNotEmpty) {
      if (newPasswordC.text == confirmPasswordC.text) {
        isLoading.value = true;
        try {
          String emailUser = auth.currentUser!.email!;
          await auth.signInWithEmailAndPassword(
            email: emailUser,
            password: currentPasswordC.text,
          );

          await auth.currentUser!.updatePassword(newPasswordC.text);
          Get.back();
          Get.snackbar("Berhasil", "Berhasil update password.");
        } on FirebaseAuthException catch (e) {
          if (e.code == 'wrong-password') {
            Get.snackbar("Terjadi Kesalahan",
                "Password yang dimasukan salah. Tidak dapat update password.");
          } else if (e.code == 'weak-password') {
            Get.snackbar("Terjadi Kesalahan",
                "Password tidak boleh kurang dari 6 karakter!");
          } else {
            Get.snackbar("Terjadi Kesalahan", "${e.code.toLowerCase()}");
          }
        } catch (e) {
          Get.snackbar("Terjadi Kesalahan", "Tidak dapat update password.");
        } finally {
          isLoading.value = false;
        }
      } else {
        Get.snackbar("Terjadi Kesalahan", "Confirm password tidak cocok.");
      }
    } else {
      Get.snackbar("Terjadi Kesalahan",
          "Curren password, new password dan confirm password harus diisi.");
    }
  }
}
