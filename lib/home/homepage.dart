import 'package:Matchify/chat/chat.dart';
import 'package:Matchify/model/ObjectItem.dart';
import 'package:Matchify/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late SharedPreferences sp;
  late String user_id;
  late String userLikeString;
  bool _isLoading = true;
  int counter = 0;
  int counterResponse = 0;

  List<ObjectItem> imageItems = [
  ];
  late List<dynamic> userLikeArray;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    sp = await SharedPreferences.getInstance();
    user_id = sp.getString('user_id') ?? '';
    userLikeString = sp.getString('user_like') ?? '';

    if (userLikeString.isNotEmpty) {
      userLikeArray = jsonDecode(userLikeString);
    }

    if (user_id.isNotEmpty) {
      final url = Uri.parse('https://api-dating-app.vercel.app/api/users');
      try {
        final response = await http.get(
          url,
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          counterResponse = responseData.length;

          setState(() {
            for (var user in responseData) {
              if(user['_id'] == user_id){
                counter++;
                continue;
              }
              if (userLikeArray.contains(user['_id'])) {
                counter++;
                continue;
              }
              else{
                  imageItems.add(ObjectItem(
                  id: user['_id'],
                  imagePath: user['user_image'],
                  name: user['user_name'],
                  age: int.parse(user['user_age']),
                  location: 'Jakarta',
                ));
              }
              
            }


            _isLoading = false;
          });
        } else {
          _showCustomModal('User Not Found');
        }
      } catch (e) {
        _showCustomModal('An error occurred');
      }
    } else {
      _isLoading = false;
    }
  }

  void _showCustomModal(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void addintoLike(String id) async {
    final url = Uri.parse('https://api-dating-app.vercel.app/api/users/addLike/${user_id}');
    if(id == ''){
      return;
    }else{
      try {
        final response = await http.patch(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'user_id': id,
          }),
        );

        if (response.statusCode == 200) {
          if (!userLikeArray.contains(id)) {
          userLikeArray.add(id);

          sp.setString('user_like', jsonEncode(userLikeArray));
        }


        } else {
          _showCustomModal('Failed to add like');
        }
      } catch (e) {
        _showCustomModal('An error occurred');
      }
    }
    
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      switch (index) {
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatPage()),
          );
          break;
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if(counter == counterResponse){
      return Scaffold(
        body: Center(
          child: _isLoading ? 
          CircularProgressIndicator(color: Colors.blue[800])
          :
          Text(
            "No Data!",
            style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black.withOpacity(0.6),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.textsms),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      );
    }
    else{
          return Scaffold(
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.blue[800])
            : _selectedIndex == 0
                ? Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    height: 590,
                    width: 500,
                    child: CardSwiper(
                      cardsCount: imageItems.length,
                      cardBuilder: (context, index, x, y) {
                        final item = imageItems[index];
                        Uint8List imageBytes = base64Decode(item.imagePath);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                imageBytes,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors:
                                        [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0)],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            item.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 33,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            item.age == 0 ? '' : ', ${item.age}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 33,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        item.location,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      allowedSwipeDirection: AllowedSwipeDirection.only(right: true, left: true),
                      numberOfCardsDisplayed: 1,
                      isLoop: false,
                      onSwipe: (previousIndex, currentIndex, direction) {
                        final swipedItem = imageItems[previousIndex];
                        if (previousIndex == imageItems.length - 1) {
                          Fluttertoast.showToast(
                            msg: "No more profiles available",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            backgroundColor: Colors.blue[800],
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        }
                        if (direction == CardSwiperDirection.right) {
                          addintoLike(swipedItem.id);
                        }
                        if (direction == CardSwiperDirection.left) {

                        }
                        return true;
                      },
                    ),
                  )
                : const SizedBox.shrink(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black.withOpacity(0.6),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.textsms),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
    }

  }
}
