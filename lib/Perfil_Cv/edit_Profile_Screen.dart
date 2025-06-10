import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scanner_personal/WidgetBarra.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  late final AnimationController _hoverController;
  late final Animation<double> _scaleAnimation;
  // Mapper for the information that is displayed
  final Map<String, String> fieldMapping = {
    "Names": "nombres",
    "Last Names": "apellidos",
    "Address": "direccion",
    "Phone": "telefono",
    "Email": "correo",
    "Nationality": "nacionalidad",
    "Date of Birth": "fecha_nacimiento",
    "Marital Status": "estado_civil",
    "LinkedIn": "linkedin",
    "GitHub": "github",
    "Portfolio": "portafolio",
    "Professional Profile": "perfil_profesional",
    "Professional Goals": "objetivos_profesionales",
    "Work Experience": "experiencia_laboral",
    "Career Expectations": "expectativas_laborales",
    "International Experience": "experiencia_internacional",
    "Education": "educacion",
    "Skills": "habilidades",
    "Languages": "idiomas",
    "Certifications": "certificaciones",
    "Project Participation": "proyectos",
    "Publications": "publicaciones",
    "Awards": "premios",
    "Volunteering": "voluntariados",
    "References": "referencias",
    "Permissions and Documentation": "permisos_documentacion",
    "Vehicle and Licenses": "vehiculo_licencias",
    "Availability for Interviews": "disponibilidad_entrevistas",
  };

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    fieldMapping.forEach((label, key) {
      _controllers[label] = TextEditingController(text: _getValueByKey(label));
    });

    // For hover/scale effect if you wanted to use it in special fields
    _hoverController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  String _getValueByKey(String label) {
    for (var section in widget.userData.values) {
      if (section is Map && section.containsKey(label)) {
        return section[label] ?? '';
      }
    }
    return '';
  }

  Future<void> _saveChanges() async {
    final updates = <String, dynamic>{};
    fieldMapping.forEach((label, key) {
      updates[key] = _controllers[label]?.text ?? '';
    });
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('perfil_information')
          .update(updates)
          .eq('id', widget.userId);
      Navigator.pop(context, true);
    } catch (error) {
      print('Error saving changes: $error');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving changes.')));
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      appBar: const CustomAppBar(title: 'Edit Information'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color(0xff9ee4b8),
        icon: Icon(Icons.save, color: Color(0xFF090467)),
        label: Text(
          'Save',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF090467),
          ),
        ),
        onPressed: _saveChanges,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children:
                fieldMapping.keys.map((label) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: _controllers[label],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                      ), // Poppins for text
                      decoration: InputDecoration(
                        labelText: label,
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Color(
                            0xFF090467,
                          ), // Poppins and blue for labels
                        ),
                        filled: true,
                        fillColor: Color(
                          0xffeff8ff,
                        ), // same gray background as screen
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // soft corners
                          borderSide: BorderSide(color: Color(0xFF090467)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Color(0xFF090467),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Color(0xff9ee4b8),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}
