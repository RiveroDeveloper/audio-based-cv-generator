import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanner_personal/Formulario/main.dart';
import 'package:scanner_personal/Login/data_base/database_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scanner_personal/Configuracion/mainConfig.dart';
import 'package:scanner_personal/WidgetBarra.dart';
import '../Funcion_Audio/cv_generator.dart';
import '../Formulario/cv_form.dart';

final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      //Donde dice Menu en el sidebar ->
      drawer: Drawer(
        backgroundColor: Color(0xfff5f5fa),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 70,
              child: DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFFeff8ff)),
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 12),
                    child: Text(
                      'Menu',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF090467),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            HoverableListTile(
              icon: Icons.person,
              text: "Account",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccountScreen()),
                );
              },
            ),
            HoverableListTile(
              icon: Icons.notifications,
              text: "Notifications",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsScreen(),
                  ),
                );
              },
            ),
            HoverableListTile(
              icon: Icons.help,
              text: "Help",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AcercaDeScreen()),
                );
              },
            ),

            // Pendiente mirar los colores de este coso para cerrar sesion !
            HoverableListTile(
              icon: Icons.exit_to_app,
              text: "Sign Out",
              iconColor: Colors.red,
              textColor: Colors.red,
              backgroundColor: const Color(0xff9ee4b8),
              textStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              onTap: () {
                Navigator.pop(context); // cerrar el drawer primero
                Future.delayed(const Duration(milliseconds: 300), () {
                  final parentContext = scaffoldKey.currentContext!;
                  showDialog(
                    context: parentContext,
                    builder:
                        (dialogContext) => AlertDialog(
                          title: Text(
                            'Sign Out?',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF090467),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to exit the application?',
                            style: GoogleFonts.poppins(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                scaffoldKey.currentState?.openDrawer();
                              },
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(dialogContext);

                                scaffoldMessengerKey.currentState?.showSnackBar(
                                  const SnackBar(
                                    content: Text('Signing out...'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );

                                await DatabaseHelper.instance.cerrarSesion();
                                await Future.delayed(
                                  const Duration(seconds: 2),
                                );

                                if (!parentContext.mounted) return;

                                Navigator.of(
                                  parentContext,
                                ).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              },
                              child: Text(
                                'Yes, exit',
                                style: GoogleFonts.poppins(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );
                });
              },
            ),
          ],
        ),
      ),
      appBar: const CustomAppBar(title: ''), // appBar
      // Este es el body, donde están las funcionalidades
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Color(0xffffffff)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select an option',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount;
                    double width = constraints.maxWidth;

                    if (width >= 1000) {
                      crossAxisCount = 4;
                    } else if (width >= 600) {
                      crossAxisCount = 3;
                    } else {
                      crossAxisCount = 2;
                    }

                    return AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: GridView.count(
                        key: ValueKey(crossAxisCount),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1,
                        // Llamo a la clase para generar las diferentes cards de funciones
                        children: [
                          CustomCard(
                            text: 'Record Audio',
                            icon: Icons.mic,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CVGenerator(),
                                ),
                              );
                            },
                          ),
                          CustomCard(
                            text: 'Fill Form',
                            icon: Icons.newspaper_rounded,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CVFormEditor(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Clase para confirmar Logout
class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Sign Out?'),
            content: Text('Are you sure you want to exit the application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  exit(0); // cierra completamente la app pero en emulador
                },
                child: Text('Yes, exit'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Out')),
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.logout),
          label: Text('Sign Out'),
          onPressed: () => _confirmLogout(context),
        ),
      ),
    );
  }
}

// Clases para las opciones de menu principal
class CustomCard extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap; // 👈 Agregado

  const CustomCard({
    super.key,
    required this.text,
    required this.icon,
    this.onTap, // 👈 Agregado
  });

  @override
  _CustomCardState createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(_controller);
  }

  void _onHover(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
      if (isHovering) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: 50, // 👈 Ancho fijo
          height: 50, // 👈 Alto fijo
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: _isHovering ? Color(0xff9ee4b8) : Color(0xfff5f5fa),
              borderRadius: BorderRadius.circular(12), // 👈 Bordes redondeado
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF787a80).withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(12), // 👈 Padding reducido
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: 46,
                      color:
                          _isHovering ? Color(0xFF090467) : Color(0xFF787a80),
                    ), // 👈 Icono más pequeño
                    SizedBox(height: 6),

                    Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18, // 👈 Texto más pequeño
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF090467),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Clases para las opciones laterales del menu
class HoverableListTile extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;
  final Color backgroundColor;
  final TextStyle? textStyle;

  const HoverableListTile({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.iconColor = const Color(0xFF787a80),
    this.textColor = const Color(0xFF090467),
    this.backgroundColor = const Color(0xff9ee4b8),
    this.textStyle,
  });

  @override
  State<HoverableListTile> createState() => _HoverableListTileState();
}

class _HoverableListTileState extends State<HoverableListTile> {
  bool _isHovering = false;

  bool get isMobile {
    final width = MediaQuery.of(context).size.width;
    return width < 600;
  }

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            _isHovering || isMobile
                ? widget.backgroundColor
                : const Color(0xfff5f5fa),
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            _isHovering
                ? [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: ListTile(
        leading: Icon(widget.icon, color: widget.iconColor),
        title: Text(
          widget.text,
          style:
              widget.textStyle ??
              GoogleFonts.poppins(
                color: widget.textColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        onTap: widget.onTap,
      ),
    );

    return isMobile
        ? InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: tile,
        )
        : MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: tile,
          ),
        );
  }
}
