import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../WidgetBarra.dart';
import '../Funcion_Audio/monkey_pdf_integration.dart';

class CVFormEditor extends StatefulWidget {
  const CVFormEditor({super.key});

  @override
  State<CVFormEditor> createState() => _CVFormEditorState();
}

class _CVFormEditorState extends State<CVFormEditor> {
  final supabase = Supabase.instance.client;

  int? _perfilId;
  String? id;
  bool _isFormLoading = true;
  String _formError = '';
  Map<String, dynamic> _formData = {};

  final Map<String, String> fieldLabels = {
    'nombres': 'First Names',
    'apellidos': 'Last Names',
    'direccion': 'Address',
    'telefono': 'Phone',
    'correo': 'Email',
    'nacionalidad': 'Nationality',
    'fecha_nacimiento': 'Date of Birth',
    'estado_civil': 'Marital Status',
    'linkedin': 'LinkedIn',
    'github': 'GitHub',
    'portafolio': 'Portfolio',
    'perfil_profesional': 'Professional Profile',
    'objetivos_profesionales': 'Professional Objectives',
    'experiencia_laboral': 'Work Experience',
    'educacion': 'Education',
    'habilidades': 'Skills',
    'idiomas': 'Languages',
    'certificaciones': 'Certifications',
    'proyectos': 'Projects',
    'publicaciones': 'Publications',
    'premios': 'Awards',
    'voluntariados': 'Volunteering',
    'referencias': 'References',
    'expectativas_laborales': 'Job Expectations',
    'experiencia_internacional': 'International Experience',
    'permisos_documentacion': 'Permits / Documentation',
    'vehiculo_licencias': 'Vehicle / Licenses',
    'contacto_emergencia': 'Emergency Contact',
    'disponibilidad_entrevistas': 'Interview Availability',
  };

  @override
  void initState() {
    super.initState();
    _loadOrCreatePerfil();
  }

  Future<void> _loadOrCreatePerfil() async {
    setState(() {
      _isFormLoading = true;
      _formError = '';
    });

    try {
      final user = "3";

      id = user;

      // Buscar si ya existe un perfil con este user_id
      final response =
          await supabase
              .from('perfil_information')
              .select()
              .eq('id', id as Object)
              .maybeSingle();

      if (response != null) {
        // Ya existe, usarlo
        _perfilId = response['id'];
        _formData = Map<String, dynamic>.from(response);
      } else {
        // Crear uno nuevo vacío con user_id
        final insert =
            await supabase
                .from('perfil_information')
                .insert({'id': id})
                .select()
                .single();

        _perfilId = insert['id'];
        _formData = Map<String, dynamic>.from(insert);
      }

      _asegurarCampos();
    } catch (e) {
      _formError = 'Error: $e';
    } finally {
      setState(() {
        _isFormLoading = false;
      });
    }
  }

  void _asegurarCampos() {
    for (var key in fieldLabels.keys) {
      _formData[key] ??= '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xff9ee4b8);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Fill Form'),
      body:
          _isFormLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          Text(
                            'Complete the information',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF090467),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_formError.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formError,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ...fieldLabels.entries.map((entry) {
                            final key = entry.key;
                            final label = entry.value;
                            final isLongText = [
                              'perfil_profesional',
                              'objetivos_profesionales',
                              'experiencia_laboral',
                              'educacion',
                              'habilidades',
                            ].contains(key);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF090467),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  TextFormField(
                                    initialValue:
                                        _formData[key]?.toString() ?? '',
                                    maxLines: isLongText ? 4 : 1,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: Color(0xFF090467),
                                        ),
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
                                      suffixStyle: GoogleFonts.poppins(
                                        color: Color(0xff090467),
                                      ),
                                      hintText: 'Enter $label',
                                    ),
                                    onChanged: (value) {
                                      _formData[key] = value;
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(
                            height: 100,
                          ), // Espacio para los botones flotantes
                        ],
                      ),
                    ),
                    // Barra de botones fija en la parte inferior
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Botón Guardar
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.save, color: Color(0xFF090467)),
                              label: Text(
                                'Save',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF090467),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xff9ee4b8),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _saveForm,
                            ),
                          ),
                          SizedBox(width: 12),
                          // Botón Vista Previa
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.preview, color: Colors.white),
                              label: Text(
                                'Preview',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF090467),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _showPreview,
                            ),
                          ),
                          SizedBox(width: 12),
                          // Botón Generar PDF
                          Expanded(
                            child: GeneratePDFButton(
                              cvData: _prepareCVData(),
                              onGenerating: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Generating PDF...',
                                      style: GoogleFonts.poppins(
                                        color: Color(0xFF090467),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              },
                              onGenerated: (String pdfUrl) {
                                print("PDF generated: $pdfUrl");
                              },
                              onError: (String error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error generating PDF: $error',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // Método para preparar los datos del CV para la generación de PDF
  Map<String, dynamic> _prepareCVData() {
    Map<String, dynamic> cvData = Map.from(_formData);

    // Ensure required fields
    if ((cvData['nombres']?.toString() ?? '').isEmpty) {
      cvData['nombres'] = 'Name';
    }
    if ((cvData['apellidos']?.toString() ?? '').isEmpty) {
      cvData['apellidos'] = 'Surname';
    }
    if ((cvData['profesion']?.toString() ?? '').isEmpty) {
      cvData['profesion'] = 'Professional';
    }

    return cvData;
  }

  // Método para mostrar vista previa
  void _showPreview() {
    try {
      if (_formData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No information to show. Please complete some fields first.',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Generating preview...',
            style: GoogleFonts.poppins(
              color: Color(0xFF090467),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );

      final cvData = _prepareCVData();

      // Generate preview
      MonkeyPDFIntegration.generatePDFFromCV(cvData)
          .then((result) {
            print("Preview generated successfully: $result");
          })
          .catchError((error) {
            print("Error generating preview: $error");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: $error',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          });
    } catch (e) {
      print("Error generating preview: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _saveForm() async {
    setState(() {
      _isFormLoading = true;
      _formError = '';
    });

    try {
      if (_perfilId == null) throw Exception('Profile ID not found');

      final updateData =
          Map<String, dynamic>.from(_formData)
            ..remove('id')
            ..remove('user_id');

      await supabase
          .from('perfil_information')
          .update(updateData)
          .eq('id', _perfilId as Object);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Information saved successfully',
            style: GoogleFonts.poppins(
              color: Color(0xFF090467),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Color(0xff9ee4b8),
        ),
      );
    } catch (e) {
      setState(() {
        _formError = 'Error saving: $e';
      });
    } finally {
      setState(() {
        _isFormLoading = false;
      });
    }
  }
}
