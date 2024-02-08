import 'dart:io' as io;
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'theme_provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<dynamic> images = [];
  bool isPopUpVisible = false;
  int currentPage = 1;
  bool isLoading = true;
  ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    fetchImages();
    _scrollController.addListener(_scrollListener);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 5.0, // You can adjust the end value for stronger blur
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchImages() async {
    final response = await http.get(
        Uri.parse('https://picsum.photos/v2/list?page=$currentPage&limit=10'));

    if (response.statusCode == 200) {
      setState(() {
        images.addAll(jsonDecode(response.body));
        isLoading = false;
        currentPage++;
      });
    } else {
      throw Exception('Failed to load Images');
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      fetchImages();
    }
  }

  void _showImageDetailsPopup(
      BuildContext context, Map<String, dynamic> imageDetails) {
    setState(() {
      isPopUpVisible = true;
    });
    _animationController.reset();
    _animationController.forward();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _animationController.value,
              child: Stack(
                children: [
                  // Blurred background
                  BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: _blurAnimation.value,
                        sigmaY: _blurAnimation.value),
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                  // Popup
                  Center(
                    child: SizedBox(
                      child: AlertDialog(
                        titleTextStyle: const TextStyle(letterSpacing: 5),
                        alignment: Alignment.center,
                        elevation: 5,
                        title: const Text(
                          'DETAILS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        contentPadding: const EdgeInsets.all(16.0),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height / 2,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: PhotoViewGallery.builder(
                                    itemCount: 1,
                                    builder: (context, index) {
                                      return PhotoViewGalleryPageOptions(
                                          imageProvider: NetworkImage(
                                            imageDetails['download_url'],
                                          ),
                                          minScale:
                                              PhotoViewComputedScale.contained *
                                                  0.8,
                                          maxScale:
                                              PhotoViewComputedScale.covered *
                                                  2);
                                    },
                                    scrollPhysics:
                                        const BouncingScrollPhysics(),
                                    backgroundDecoration: const BoxDecoration(
                                        color: Colors.transparent),
                                    pageController: PageController(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10.0),
                              Text('Author: ${imageDetails['author']}'),
                              Text('ID: ${imageDetails['id']}'),
                              // Add more details as needed
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Close'),
                          ),
                          TextButton(
                              onPressed: () async {
                                final urlImage = imageDetails['download_url'];
                                final url = Uri.parse(urlImage);
                                final response = await http.get(url);
                                final bytes = response.bodyBytes;

                                final temp = await getTemporaryDirectory();
                                final path = '${temp.path}/image.jpg';
                                io.File(path).writeAsBytesSync(bytes);
                                await Share.shareFiles([path],
                                    text: 'This is a image');
                              },
                              child: Text('Share'))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        isPopUpVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'PICSUM GALLERY',
          style: GoogleFonts.aBeeZee(
              textStyle: const TextStyle(
                  letterSpacing: 5,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_4_outlined),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Blurred background
          isLoading
              ? BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: _blurAnimation.value,
                      sigmaY: _blurAnimation.value),
                  child: Center(
                      child: Text(
                    'Loading...',
                    style: GoogleFonts.aclonica(
                        textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic)),
                  )),
                )
              : Container(),
          ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: images.length + 1,
            // +1 to account for the loading indicator
            controller: _scrollController,
            itemBuilder: (context, index) {
              if (index < images.length) {
                return GestureDetector(
                  onTap: () {
                    _showImageDetailsPopup(context, images[index]);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      elevation: 10,
                      child: Image.network(images[index]['download_url']),
                    ),
                  ),
                );
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }
}

// import 'dart:ui';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter/material.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:photo_view/photo_view_gallery.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'package:share/share.dart';
// import 'dart:convert';
// import 'theme_provider.dart';
//
// class HomePage extends StatefulWidget {
//   @override
//   _HomePageState createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
//   List<dynamic> images = [];
//   bool isPopUpVisible = false;
//   int currentPage = 1;
//   bool isLoading = true;
//   ScrollController _scrollController = ScrollController();
//   late AnimationController _animationController;
//   late Animation<double> _opacityAnimation;
//   late Animation<double> _blurAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchImages();
//     _scrollController.addListener(_scrollListener);
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 1),
//     );
//     _opacityAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(_animationController);
//     _blurAnimation = Tween<double>(
//       begin: 0.0,
//       end: 5.0, // You can adjust the end value for stronger blur
//     ).animate(_animationController);
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   Future<void> fetchImages() async {
//     final response = await http.get(
//         Uri.parse('https://picsum.photos/v2/list?page=$currentPage&limit=10'));
//
//     if (response.statusCode == 200) {
//       setState(() {
//         images.addAll(jsonDecode(response.body));
//         isLoading = false;
//         currentPage++;
//       });
//     } else {
//       throw Exception('Failed to load Images');
//     }
//   }
//
//   void _scrollListener() {
//     if (_scrollController.offset >=
//             _scrollController.position.maxScrollExtent &&
//         !_scrollController.position.outOfRange) {
//       fetchImages();
//     }
//   }
//
//   void _showImageDetailsPopup(
//       BuildContext context, Map<String, dynamic> imageDetails) {
//     setState(() {
//       isPopUpVisible = true;
//     });
//     _animationController.reset();
//     _animationController.forward();
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AnimatedBuilder(
//           animation: _animationController,
//           builder: (context, child) {
//             return Opacity(
//               opacity: _animationController.value,
//               child: Stack(
//                 children: [
//                   // Blurred background
//                   BackdropFilter(
//                     filter: ImageFilter.blur(
//                         sigmaX: _blurAnimation.value,
//                         sigmaY: _blurAnimation.value),
//                     child: Container(
//                       color: Colors.black.withOpacity(0.1),
//                     ),
//                   ),
//                   // Popup
//                   Center(
//                     child: SizedBox(
//                       child: AlertDialog(
//                         titleTextStyle: const TextStyle(letterSpacing: 5),
//                         alignment: Alignment.center,
//                         elevation: 5,
//                         title: const Text('DETAILS',style: TextStyle(fontWeight: FontWeight.bold),),
//                         contentPadding: const EdgeInsets.all(16.0),
//                         content: SizedBox(
//                           width: double.maxFinite,
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               SizedBox(
//                                 height: MediaQuery.of(context).size.height / 2,
//                                 child: PhotoViewGallery.builder(
//                                   itemCount: 1,
//                                   builder: (context, index) {
//                                     return PhotoViewGalleryPageOptions(
//                                         imageProvider: NetworkImage(
//                                             imageDetails['download_url']),
//                                         minScale:
//                                             PhotoViewComputedScale.contained *
//                                                 0.8,
//                                         maxScale:
//                                             PhotoViewComputedScale.covered * 2);
//                                   },
//                                   scrollPhysics: const BouncingScrollPhysics(),
//                                   backgroundDecoration: const BoxDecoration(
//                                       color: Colors.transparent),
//                                   pageController: PageController(),
//                                 ),
//                               ),
//                               const SizedBox(height: 10.0),
//                               Text('Author: ${imageDetails['author']}'),
//                               Text('ID: ${imageDetails['id']}'),
//                               // Add more details as needed
//                             ],
//                           ),
//                         ),
//                         actions: [
//                           TextButton(
//                             onPressed: () {
//                               Navigator.of(context).pop();
//                             },
//                             child: const Text('Close'),
//                           ),
//                           // TextButton(onPressed: Share.share(imageDetails['download_url']), child: child)
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     ).then((_) {
//       setState(() {
//         isPopUpVisible = false;
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         title: Text(
//           'PICSUM GALLERY',
//           style: GoogleFonts.aBeeZee(
//               textStyle:
//                   const TextStyle(letterSpacing: 5, fontWeight: FontWeight.bold,fontStyle: FontStyle.italic)),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.brightness_4_outlined),
//             onPressed: () {
//               Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
//             },
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           // Blurred background
//           isLoading
//               ? BackdropFilter(
//                   filter: ImageFilter.blur(
//                       sigmaX: _blurAnimation.value,
//                       sigmaY: _blurAnimation.value),
//                   child: Center(
//                       child: Text(
//                     'Loading...',
//                     style: GoogleFonts.aclonica(
//                         textStyle: const TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             fontStyle: FontStyle.italic)),
//                   )),
//                 )
//               : Container(),
//           ListView.builder(
//             physics: const AlwaysScrollableScrollPhysics(),
//             itemCount: images.length + 1,
//             // +1 to account for the loading indicator
//             controller: _scrollController,
//             itemBuilder: (context, index) {
//               if (index < images.length) {
//                 return GestureDetector(
//                   onTap: () {
//                     _showImageDetailsPopup(context, images[index]);
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Card(
//                       elevation: 10,
//                       child: Image.network(images[index]['download_url']),
//                     ),
//                   ),
//                 );
//               } else {
//                 return Container();
//               }
//             },
//           )
//           // GridView.builder(
//           //   physics: const AlwaysScrollableScrollPhysics(),
//           //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           //     crossAxisCount: 2,
//           //     crossAxisSpacing: 8.0,
//           //     mainAxisSpacing: 8.0,
//           //   ),
//           //   itemCount: images.length + 1,
//           //   // +1 to account for the loading indicator
//           //   controller: _scrollController,
//           //   itemBuilder: (context, index) {
//           //     if (index < images.length) {
//           //       return GestureDetector(
//           //         onTap: () {
//           //           _showImageDetailsPopup(context, images[index]);
//           //         },
//           //         child: Card(
//           //           child: Image.network(images[index]['download_url']),
//           //         ),
//           //       );
//           //     } else {
//           //       return Container();
//           //     }
//           //   },
//           // ),
//         ],
//       ),
//     );
//   }
// }
