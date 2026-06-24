// import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
// import 'package:aboglumbo_bbk_panel/models/location.dart';
// import 'package:aboglumbo_bbk_panel/styles/color.dart';
// import 'package:flutter/material.dart';
// 
// showLocationPicker(
//   BuildContext context,
//   Function(String) districtName,
//   List<LocationModel> locations,
// ) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.white,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//     ),
//     builder: (context) {
//       return SizedBox(
//         height: MediaQuery.of(context).size.height * 0.6,
//         child: Locations(districtName: districtName, locations: locations),
//       );
//     },
//   );
// }

// class Locations extends StatelessWidget {
//   final Function(String) districtName;
//   List<LocationModel> locations;
//   Locations({super.key, required this.districtName, required this.locations});

//   @override
//   Widget build(BuildContext context) {
//     final safePaddings = MediaQuery.of(context).padding;
//     locations.sort((a, b) => (a.n ?? '').compareTo(b.name ?? ''));
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 AppLocalizations.of(context)?.selectLocation ?? '',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.black87,
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.close),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: ListView.builder(
//             itemCount: locations.length,
//             padding: EdgeInsets.only(bottom: safePaddings.bottom + 16),
//             itemBuilder: (context, index) {
//               final location = locations[index];
//               return ListTile(
//                 dense: true,
//                 leading: Icon(
//                   Icons.location_on_rounded,
//                   color: AppColors.grey2,
//                 ),
//                 title: Text(
//                   AppLocalizations.of(context)?.localeName == 'ar'
//                       ? location.name_ar ?? ''
//                       : location.name ?? '',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 onTap: () {
//                   districtName(location.name ?? '');
//                   Navigator.pop(context);
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
