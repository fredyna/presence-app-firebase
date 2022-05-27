import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:presence/app/routes/app_pages.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class PageIndexController extends GetxController {
  RxInt pageIndex = 0.obs;

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  void changePage(int i) async {
    switch (i) {
      case 1:
        Map<String, dynamic> response = await determinePosition();
        if (response["error"]) {
          Get.snackbar("Terjadi Kesalahan", response["message"]);
        } else {
          Position position = response["position"];
          List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude, position.longitude);

          String location =
              "${placemarks[0].name}, ${placemarks[0].subLocality}, ${placemarks[0].locality}";
          await updatePosition(position, location);

          //cek distance between 2 position
          double distance = Geolocator.distanceBetween(
              -6.876586, 109.1261046, position.latitude, position.longitude);

          // presensi
          await presensi(position, location, distance);
        }
        break;
      case 2:
        pageIndex.value = 2;
        Get.offAllNamed(Routes.PROFILE);
        break;
      default:
        pageIndex.value = 0;
        Get.offAllNamed(Routes.HOME);
    }
  }

  Future<void> presensi(
      Position position, String address, double distance) async {
    String uid = await auth.currentUser!.uid;

    CollectionReference<Map<String, dynamic>> colPresence =
        await firestore.collection("pegawai").doc(uid).collection("presence");

    QuerySnapshot<Map<String, dynamic>> snapPresence = await colPresence.get();

    DateTime now = DateTime.now();
    String todayDocID = DateFormat.yMd().format(now).replaceAll("/", "-");
    String status = "Di luar Area";
    if (distance <= 100) {
      status = "Di dalam Area";
    }

    if (snapPresence.docs.length == 0) {
      //belum pernah absen dan set absen masuk pertama kali
      await Get.defaultDialog(
        title: "Validasi Presensi",
        middleText: "Apakah yakin akan mengisi daftar hadir (MASUK) sekarang ?",
        actions: [
          OutlinedButton(
            onPressed: () => Get.back(),
            child: Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              await colPresence.doc(todayDocID).set({
                "date": now.toIso8601String(),
                "masuk": {
                  "date": now.toIso8601String(),
                  "lat": position.latitude,
                  "long": position.longitude,
                  "distance": distance,
                  "address": address,
                  "status": status,
                }
              });

              Get.back();
              Get.snackbar("Berhasil", "Kamu telah mengisi daftar hadir.");
            },
            child: Text("YES"),
          ),
        ],
      );
    } else {
      DocumentSnapshot<Map<String, dynamic>> todayDoc =
          await colPresence.doc(todayDocID).get();

      if (todayDoc.exists) {
        //absen keluar atau sudah masuk & keluar
        Map<String, dynamic>? dataPresenceToday = todayDoc.data();
        if (dataPresenceToday?["keluar"] != null) {
          //sudah absen masuk & keluar
          Get.snackbar("Informasi Penting",
              "Kamu telah absen masuk & keluar. Tidak dapat mengubah data kembali.");
        } else {
          //absen keluar
          await Get.defaultDialog(
            title: "Validasi Presensi",
            middleText:
                "Apakah yakin akan mengisi daftar hadir (KELUAR) sekarang ?",
            actions: [
              OutlinedButton(
                onPressed: () => Get.back(),
                child: Text("CANCEL"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await colPresence.doc(todayDocID).update({
                    "keluar": {
                      "date": now.toIso8601String(),
                      "lat": position.latitude,
                      "long": position.longitude,
                      "distance": distance,
                      "address": address,
                      "status": status,
                    }
                  });

                  Get.back();
                  Get.snackbar("Berhasil", "Kamu telah mengisi daftar hadir.");
                },
                child: Text("YES"),
              ),
            ],
          );
        }
      } else {
        //absen masuk
        await Get.defaultDialog(
          title: "Validasi Presensi",
          middleText:
              "Apakah yakin akan mengisi daftar hadir (MASUK) sekarang ?",
          actions: [
            OutlinedButton(
              onPressed: () => Get.back(),
              child: Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () async {
                await colPresence.doc(todayDocID).set({
                  "date": now.toIso8601String(),
                  "masuk": {
                    "date": now.toIso8601String(),
                    "lat": position.latitude,
                    "long": position.longitude,
                    "distance": distance,
                    "address": address,
                    "status": status,
                  }
                });

                Get.back();
                Get.snackbar("Berhasil", "Kamu telah mengisi daftar hadir.");
              },
              child: Text("YES"),
            ),
          ],
        );
      }
    }
  }

  Future<void> updatePosition(Position position, String location) async {
    String uid = await auth.currentUser!.uid;

    await firestore.collection("pegawai").doc(uid).update({
      "position": {
        "lat": position.latitude,
        "long": position.longitude,
      },
      "address": location,
    });
  }

  Future<Map<String, dynamic>> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return {
        "message": "Tidak dapat mengambil GPS dari perangkat ini.",
        "error": true,
      };
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return {
          "message": "Izin menggunakan GPS ditolak.",
          "error": true,
        };
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return {
        "message":
            "Izin menggunakan GPS tidak diperbolehkan. Ubah pengaturan izin penggunaan GPS perangkat ini.",
        "error": true,
      };
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition();
    return {
      "position": position,
      "message": "Berhasil mendapatkan posisi perangkat.",
      "error": false,
    };
  }
}
