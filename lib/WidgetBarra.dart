import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: Color(0xFFeff8ff),
      elevation: 2,
      automaticallyImplyLeading: true,
      iconTheme: const IconThemeData(
        color: Color(0xFF090467),
      ), // permite que Flutter decida si poner flecha o menú
      titleSpacing: 0,
      title: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10, bottom: 12, top: 9),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: Color(0xFF090467),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
