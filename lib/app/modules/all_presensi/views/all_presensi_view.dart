import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:presence/app/routes/app_pages.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../controllers/all_presensi_controller.dart';

class AllPresensiView extends GetView<AllPresensiController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Semua Presensi'),
        centerTitle: true,
      ),
      body: GetBuilder<AllPresensiController>(
        builder: (c) => FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: controller.getPresence(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snap.data?.docs.length == 0 || snap.data == null) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text("Belum ada histori presensi."),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(20),
              itemCount: snap.data!.docs.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> data = snap.data!.docs[index].data();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Material(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () {
                        Get.toNamed(Routes.DETAIL_PRESENCE);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Masuk",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${DateFormat.yMMMEd().format(DateTime.parse(data['date']))}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(data['masuk']?['date'] == null
                                ? "-"
                                : "${DateFormat.jms().format(DateTime.parse(data['masuk']!['date']))}"),
                            SizedBox(height: 10),
                            Text(
                              "Keluar",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(data['keluar']?['date'] == null
                                ? "-"
                                : "${DateFormat.jms().format(DateTime.parse(data['keluar']!['date']))}"),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //syncfusion datepicker
          Get.dialog(
            Dialog(
              child: Container(
                padding: EdgeInsets.all(20),
                height: 400,
                child: SfDateRangePicker(
                  monthViewSettings:
                      DateRangePickerMonthViewSettings(firstDayOfWeek: 1),
                  selectionMode: DateRangePickerSelectionMode.range,
                  showActionButtons: true,
                  onCancel: () => Get.back(),
                  onSubmit: (obj) {
                    if (obj != null) {
                      if ((obj as PickerDateRange).endDate != null) {
                        controller.pickDate(obj.startDate!, obj.endDate!);
                      }
                    }
                  },
                ),
              ),
            ),
          );
        },
        child: Icon(Icons.date_range),
      ),
    );
  }
}
