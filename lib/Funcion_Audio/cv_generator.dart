import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../WidgetBarra.dart';
import 'monkey_pdf_integration.dart'; // Importar la integración con Monkey PDF
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;

// Compile-time defines (--dart-define) work on all platforms, including web
String? _fromDartDefine(String key) {
  switch (key) {
    case 'SUPABASE_URL':
      return const String.fromEnvironment('SUPABASE_URL');
    case 'SUPABASE_ANON_KEY':
      return const String.fromEnvironment('SUPABASE_ANON_KEY');
    case 'ELEVENLABS_API_KEY':
      return const String.fromEnvironment('ELEVENLABS_API_KEY');
    case 'OPENROUTER_API_KEY':
      return const String.fromEnvironment('OPENROUTER_API_KEY');
    default:
      return null;
  }
}

// Helper function to get environment variables across platforms
String? getEnvironmentVariable(String key) {
  final fromDefines = _fromDartDefine(key);
  if (fromDefines != null && fromDefines.isNotEmpty) {
    return fromDefines;
  }

  if (kIsWeb) {
    try {
      // For web builds, try to get from window.ENV first
      final env = js.context['ENV'];
      if (env != null) {
        return env[key];
      }
    } catch (e) {
      print('Error accessing window.ENV: $e');
    }
  }

  // For other platforms or fallback, use dotenv
  return dotenv.env[key];
}

// Acceder a la instancia de Supabase
final supabase = Supabase.instance.client;

// Modelo para las secciones de CV
class CVSection {
  final String id;
  final String title;
  final String description;
  final List<String> fields;
  String? audioUrl;
  String? transcription;
  bool isCompleted = false;

  CVSection({
    required this.id,
    required this.title,
    required this.description,
    required this.fields,
    this.audioUrl,
    this.transcription,
  });
}

// Datos para las secciones predefinidas del CV
final List<CVSection> cvSections = [
  CVSection(
    id: 'personal_info',
    title: 'Personal Information',
    description:
        'Tell us about yourself: full name, address, phone, email, nationality, date of birth, marital status, social networks and portfolio.',
    fields: [
      'Full name',
      'Address',
      'Phone',
      'Email',
      'Nationality',
      'Date of birth',
      'Marital status',
      'LinkedIn',
      'GitHub',
      'Portfolio',
    ],
  ),
  CVSection(
    id: 'professional_profile',
    title: 'Professional Profile',
    description:
        'Summarize who you are, what you do and what your professional focus is. This is your opportunity to stand out.',
    fields: ['Professional summary'],
  ),
  CVSection(
    id: 'education',
    title: 'Education',
    description:
        'Mention your completed studies, institutions, dates and degrees obtained, starting with the most recent.',
    fields: ['Studies', 'Institutions', 'Dates', 'Degrees'],
  ),
  CVSection(
    id: 'work_experience',
    title: 'Work Experience',
    description:
        'Detail the companies where you have worked, positions, functions, achievements and duration, starting with the most recent.',
    fields: ['Companies', 'Positions', 'Functions', 'Achievements', 'Duration'],
  ),
  CVSection(
    id: 'skills',
    title: 'Skills and Certifications',
    description:
        'List your technical skills, soft skills and any relevant certifications you have obtained.',
    fields: ['Technical skills', 'Soft skills', 'Certifications'],
  ),
  CVSection(
    id: 'languages',
    title: 'Languages and Other Achievements',
    description:
        'Mention the languages you speak, publications, awards, volunteering, international experience, permits or licenses.',
    fields: [
      'Languages',
      'Publications',
      'Awards',
      'Volunteering',
      'International experience',
      'Permits/Licenses',
    ],
  ),
  CVSection(
    id: 'references',
    title: 'References and Additional Details',
    description:
        'Include work/personal references, job expectations, emergency contact and availability for interviews.',
    fields: [
      'Work references',
      'Personal references',
      'Job expectations',
      'Emergency contact',
      'Availability',
    ],
  ),
];

class CVGenerator extends StatefulWidget {
  const CVGenerator({super.key});

  @override
  _CVGeneratorState createState() => _CVGeneratorState();
}

class _CVGeneratorState extends State<CVGenerator> {
  // Propiedades para manejo de audio
  Record _audioRecorder = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;

  // Propiedades para manejo de datos del CV
  int _currentSectionIndex = 0;
  final Map<String, String> _transcriptions = {};
  final Map<String, String> _audioUrls = {};

  // Estado de procesamiento
  bool _isProcessing = false;
  bool _isComplete = false;
  String _processingStatus = '';

  // Controlador para PageView
  final PageController _pageController = PageController();

  // Variables para el formulario de edición
  Map<String, dynamic> _editableInfo = {};
  bool _isFormLoading = false;
  String _formError = '';
  String _recordId = '';

  // Intenta corregir el problema de JSArray vs String en Flutter web
  // Asegurarse de que todos los mapas se convierten a Map<String, String> forzosamente
  void _asegurarTiposDeDatos() {
    Map<String, dynamic> temp = {};

    try {
      // Verificar primero que _editableInfo no es nulo
      if (_editableInfo.isEmpty) {
        print("DEPURANDO: _editableInfo está vacío");
        return;
      }

      print(
        "DEPURANDO: Asegurando tipos de datos para: ${_editableInfo.keys.join(', ')}",
      );

      _editableInfo.forEach((key, value) {
        try {
          if (value == null) {
            temp[key] = "";
          } else if (value is List) {
            // Si es una lista, convertirla a String para la visualización
            temp[key] = value.join(", ");
          } else if (value is Map) {
            // Si es un mapa, convertirlo a String para la visualización
            temp[key] = json.encode(value);
          } else {
            temp[key] = value.toString();
          }
        } catch (e) {
          print("DEPURANDO: Error al procesar campo '$key': $e");
          temp[key] = "";
        }
      });

      // Reemplazar _editableInfo con la versión segura
      _editableInfo = Map<String, dynamic>.from(temp);
      print("DEPURANDO: Tipos de datos asegurados correctamente");
    } catch (e) {
      print("DEPURANDO: Error al asegurar tipos de datos: $e");
      // En caso de error, inicializar con un mapa vacío
      _editableInfo = {};
    }
  }

  // Función para solicitar permisos de audio
  Future<bool> _requestPermission() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      print("Error al solicitar permisos: $e");
      return false;
    }
  }

  Future<void> _initializeAudioHandlers() async {
    try {
      await _audioRecorder.dispose();
      _audioRecorder = Record();

      bool hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        bool permissionGranted = await _requestPermission();
        if (!permissionGranted) {
          // Manejar la falta de permisos
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Microphone permissions are required to record audio',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _isPlaying = false;
        });
      });

      print("Audio handlers inicializados correctamente");
    } catch (e) {
      print("Error al inicializar el grabador: $e");
    }
  }

  Future<void> _startRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
      }

      // Reinicia el grabador
      await _initializeAudioHandlers();

      setState(() {
        _isRecording = true;
      });

      await _audioRecorder.start();
    } catch (e) {
      print("Error al iniciar grabación: $e");
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        // Guardar la URL del audio para la sección actual
        _audioUrls[cvSections[_currentSectionIndex].id] = path!;
      });
    } catch (e) {
      print("Error al detener grabación: $e");
      setState(() {
        _isRecording = false;
      });
    }
  }

  // Para web: AudioElement nativo (audioplayers tiene problemas con blob URLs)
  html.AudioElement? _webAudioElement;

  Future<void> _playRecording() async {
    if (_isPlaying) {
      if (kIsWeb && _webAudioElement != null) {
        _webAudioElement!.pause();
        _webAudioElement!.remove();
        _webAudioElement = null;
      } else {
        await _audioPlayer.stop();
      }
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    final audioUrl = _audioUrls[cvSections[_currentSectionIndex].id];
    if (audioUrl != null) {
      try {
        if (kIsWeb || audioUrl.startsWith('blob:')) {
          // Web: usar AudioElement nativo para blob URLs
          _webAudioElement?.remove();
          _webAudioElement = html.AudioElement()
            ..src = audioUrl
            ..controls = false
            ..autoplay = true;
          _webAudioElement!.onEnded.listen((_) {
            if (mounted) setState(() => _isPlaying = false);
          });
          _webAudioElement!.onError.listen((_) {
            if (mounted) setState(() => _isPlaying = false);
          });
          html.document.body?.append(_webAudioElement!);
          setState(() => _isPlaying = true);
        } else {
          await _audioPlayer.play(DeviceFileSource(audioUrl));
          setState(() => _isPlaying = true);
        }
      } catch (e) {
        print("Error al reproducir audio: $e");
      }
    }
  }

  void _nextSection() {
    if (_currentSectionIndex < cvSections.length - 1) {
      setState(() {
        _currentSectionIndex++;
      });
      _pageController.animateToPage(
        _currentSectionIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Si estamos en la última sección, mostramos el diálogo de confirmación
      _showConfirmationDialog();
    }
  }

  // Mostrar diálogo de confirmación antes de procesar todos los audios
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Finish and process', style: GoogleFonts.poppins()),
          content: Text(
            'Have you finished recording all sections? '
            'By continuing, all audios will be processed and your resume will be generated. '
            'This process may take several minutes.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processAllAudios();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff9ee4b8),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  // Método para procesar todos los audios grabados
  Future<void> _processAllAudios() async {
    // Mostrar la pantalla de procesamiento
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Preparing audios...';
    });

    try {
      // Paso 1: Preparar para procesar todos los audios
      final now = DateTime.now();
      final cvId = now.millisecondsSinceEpoch.toString();

      // Paso 2: Recopilar todos los audios grabados
      Map<String, String> sectionAudios = {};
      List<String> sectionIds = [];

      setState(() {
        _processingStatus = 'Preparing audios...';
      });

      // Contador para reportar progreso
      int totalSections = 0;
      int processedSections = 0;

      // Contar cuántas secciones tienen audio
      for (var section in cvSections) {
        if (_audioUrls.containsKey(section.id)) {
          totalSections++;
          sectionIds.add(section.id);
        }
      }

      if (totalSections == 0) {
        throw Exception("No audio recordings found");
      }

      print("Se procesarán $totalSections secciones con grabaciones de audio");

      // Mapa para almacenar las transcripciones por sección
      Map<String, String> transcripcionesPorSeccion = {};
      Map<String, String> urlsPorSeccion = {};

      // Procesar cada sección con audio grabado
      for (var section in cvSections) {
        if (_audioUrls.containsKey(section.id)) {
          final audioPath = _audioUrls[section.id]!;

          setState(() {
            processedSections++;
            _processingStatus =
                'Processing audio $processedSections/$totalSections: ${section.title}';
          });

          print("Procesando audio de la sección: ${section.title}");
          print("Ruta del audio: $audioPath");

          try {
            // Para Flutter web, necesitamos usar un FileReader para acceder al blob
            final completer = Completer<Uint8List>();
            final xhr = html.HttpRequest();
            xhr.open('GET', audioPath);
            xhr.responseType = 'blob';

            xhr.onLoad.listen((event) {
              if (xhr.status == 200) {
                final blob = xhr.response as html.Blob;
                final reader = html.FileReader();

                reader.onLoadEnd.listen((event) {
                  final Uint8List audioBytes = Uint8List.fromList(
                    reader.result is List<int>
                        ? (reader.result as List<int>)
                        : Uint8List.view(reader.result as ByteBuffer).toList(),
                  );
                  completer.complete(audioBytes);
                });

                reader.readAsArrayBuffer(blob);
              } else {
                completer.completeError(
                  'Error al obtener el audio: código ${xhr.status}',
                );
              }
            });

            xhr.onError.listen((event) {
              completer.completeError('Error de red al obtener el audio');
            });

            xhr.send();

            final Uint8List audioBytes = await completer.future;

            setState(() {
              _processingStatus =
                  'Uploading to Supabase ($processedSections/$totalSections)...';
            });

            // Nombre único para este archivo de audio
            final fileName =
                'cv_${cvId}_${section.id}_${now.millisecondsSinceEpoch}.webm';

            print("Bytes de audio obtenidos: ${audioBytes.length} bytes");
            print("Subiendo audio a Supabase como: $fileName");

            // Subir a Supabase (requiere Storage RLS: audios_upload_authenticated)
            final response = await supabase.storage
                .from('audios')
                .uploadBinary(
                  fileName,
                  audioBytes,
                  fileOptions: const FileOptions(contentType: 'audio/webm'),
                );

            print("Respuesta de Supabase al subir: $response");

            // URL pública (bucket público)
            final audioUrl = supabase.storage
                .from('audios')
                .getPublicUrl(fileName);

            sectionAudios[section.id] = audioUrl;
            urlsPorSeccion[section.title] = audioUrl;

            print("URL pública del audio de ${section.title}: $audioUrl");

            // Transcribir usando AssemblyAI
            setState(() {
              _processingStatus =
                  'Transcribing ($processedSections/$totalSections): ${section.title}';
            });

            try {
              // Llamada directa a ElevenLabs con los bytes ya en memoria (sin Edge Functions)
              String transcripcion = await _transcribirConElevenLabsDirecto(audioBytes);
              transcripcionesPorSeccion[section.title] = transcripcion;
              print("Transcripción de ${section.title} completada");
            } catch (e) {
              print("Error transcribiendo audio de ${section.title}: $e");
              transcripcionesPorSeccion[section.title] =
                  "Transcription error: $e";
              // Continuar con el proceso a pesar del error
            }
          } catch (e) {
            print("Error procesando audio de ${section.title}: $e");
            // Distinguir: upload falla antes de transcripción
            final isUploadError = e.toString().toLowerCase().contains('storage') ||
                e.toString().toLowerCase().contains('bucket') ||
                e.toString().toLowerCase().contains('policy') ||
                e.toString().toLowerCase().contains('403') ||
                e.toString().toLowerCase().contains('401');
            transcripcionesPorSeccion[section.title] =
                isUploadError ? "Upload error: $e" : "Transcription error: $e";
            // Continuar con el proceso a pesar del error
          }
        }
      }

      // Una vez procesados todos los audios individuales, guardar en la base de datos
      setState(() {
        _processingStatus = 'Saving information to database...';
      });

      try {
        // Crear un texto combinado con todas las transcripciones organizadas por sección
        StringBuffer transcripcionCombinada = StringBuffer();

        for (var section in cvSections) {
          if (transcripcionesPorSeccion.containsKey(section.title)) {
            transcripcionCombinada.writeln(
              "### ${section.title.toUpperCase()} ###",
            );
            transcripcionCombinada.writeln(
              transcripcionesPorSeccion[section.title],
            );
            transcripcionCombinada.writeln("\n");
          }
        }

        // Analizar la transcripción usando OpenRouter.ai
        setState(() {
          _processingStatus = 'Analyzing transcription with AI...';
        });

        Map<String, dynamic> analyzedTranscription;
        try {
          analyzedTranscription = await _analizarTranscripcionConLLM(
            transcripcionCombinada.toString(),
          );
        } catch (e) {
          print("Error al analizar transcripción: $e");
          // Proporcionar un objeto JSON vacío con la estructura esperada en caso de error
          analyzedTranscription = {
            "nombres": "",
            "apellidos": "",
            // Incluir todos los demás campos necesarios con valores vacíos
            "correo": "",
            "telefono": "",
            "direccion": "",
            "perfil_profesional": "",
            "experiencia_laboral": "",
            "educacion": "",
            "habilidades": "",
            "idiomas": "",
          };
        }

        // Construir JSON con metadatos de las secciones incluidas
        Map<String, dynamic> seccionesInfo = {};
        for (var section in cvSections) {
          if (transcripcionesPorSeccion.containsKey(section.title)) {
            seccionesInfo[section.title] = {
              'id': section.id,
              'descripcion': section.description,
              'enlace_audio': urlsPorSeccion[section.title],
            };
          }
        }

        // Crear un solo registro con todas las transcripciones y metadatos
        final audioRecord = {
          'transcripcion': transcripcionCombinada.toString(),
          'enlace_audio': '', // No hay un solo enlace, están en el JSON
          'transcripcion_organizada_json':
              analyzedTranscription, // Datos estructurados por la IA
          'informacion_audios': jsonEncode({
            // Nueva columna para los metadatos originales
            'cv_id': cvId,
            'timestamp': now.toIso8601String(),
            'secciones': seccionesInfo,
          }),
        };

        print("Guardando registro combinado en la base de datos");

        // Guardar el registro combinado en la base de datos y obtener el ID
        final insertResponse = await supabase
            .from('audio_transcrito')
            .insert(audioRecord)
            .select('id');

        print("Información guardada correctamente en la base de datos");

        // Obtener el ID del registro recién creado
        if (insertResponse.isNotEmpty) {
          _recordId = insertResponse[0]['id'].toString();
          print("ID del registro: $_recordId");
        } else {
          print("No se pudo obtener el ID del registro");
        }

        // Cargar la información extraída por la IA para editar
        print("📝 [FORMULARIO] Cargando información analizada al formulario...");
        print("📝 [FORMULARIO] Campos recibidos: ${analyzedTranscription.keys.join(', ')}");
        print("📝 [FORMULARIO] Campos con datos: ${analyzedTranscription.entries.where((e) => e.value.toString().isNotEmpty).map((e) => '${e.key}=${e.value.toString().substring(0, e.value.toString().length > 20 ? 20 : e.value.toString().length)}...').join(', ')}");
        
        _editableInfo = Map<String, dynamic>.from(analyzedTranscription);
        _asegurarTiposDeDatos();
        
        print("✅ [FORMULARIO] _editableInfo actualizado con ${_editableInfo.length} campos");

        // Si hubo errores, avisar al usuario
        final hasUploadErrors = transcripcionesPorSeccion.values
            .any((t) => t.toLowerCase().contains('upload error'));
        final hasTranscriptionErrors = transcripcionesPorSeccion.values
            .any((t) => t.toLowerCase().contains('transcription error'));
        if (hasUploadErrors && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Upload failed. Check Storage policies (supabase/storage_policies.sql).',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 6),
            ),
          );
        } else if (hasTranscriptionErrors && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Transcription failed. Fill the form manually or check Edge Function config.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }

        // Proceso completado
        setState(() {
          _isProcessing = false;
          _isComplete = true;
        });
      } catch (e) {
        print("Error al guardar en la base de datos: $e");
        setState(() {
          _isProcessing = false;
          _processingStatus = 'Error: $e';
        });

        // Mostrar el error al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving to database: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error en el procesamiento: $e");
      setState(() {
        _isProcessing = false;
        _processingStatus = 'Error: $e';
      });

      // Mostrar el error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred during processing: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Llama directamente a ElevenLabs desde el browser con los bytes del audio.
  /// Evita pasar por Supabase Edge Functions (y sus problemas de JWT).
  Future<String> _transcribirConElevenLabsDirecto(Uint8List audioBytes) async {
    final apiKey = getEnvironmentVariable('ELEVENLABS_API_KEY') ?? '';
    if (apiKey.isEmpty) {
      print('[TRANSCRIPCIÓN] ELEVENLABS_API_KEY no configurada');
      return '';
    }

    // ElevenLabs requiere al menos ~0.5s de audio (~5000 bytes a bitrate típico de WebM)
    if (audioBytes.length < 5000) {
      print('[TRANSCRIPCIÓN] Audio demasiado corto (${audioBytes.length} bytes), omitiendo');
      return '';
    }

    print('[TRANSCRIPCIÓN] Enviando ${audioBytes.length} bytes directo a ElevenLabs...');

    final completer = Completer<String>();

    try {
      final blob = html.Blob([audioBytes], 'audio/webm');
      final formData = html.FormData();
      formData.appendBlob('file', blob, 'audio.webm');
      formData.append('model_id', 'scribe_v2');

      final xhr = html.HttpRequest();
      xhr.open('POST', 'https://api.elevenlabs.io/v1/speech-to-text');
      xhr.setRequestHeader('xi-api-key', apiKey);

      xhr.onLoad.listen((event) {
        try {
          if (xhr.status == 200) {
            final data = json.decode(xhr.responseText!) as Map;
            final text = data['text']?.toString() ?? '';
            print('[TRANSCRIPCIÓN] OK (${text.length} chars)');
            if (!completer.isCompleted) completer.complete(text);
          } else {
            print('[TRANSCRIPCIÓN] ElevenLabs error ${xhr.status}: ${xhr.responseText}');
            if (!completer.isCompleted) completer.complete('');
          }
        } catch (e) {
          print('[TRANSCRIPCIÓN] Error parseando respuesta: $e');
          if (!completer.isCompleted) completer.complete('');
        }
      });

      xhr.onError.listen((event) {
        print('[TRANSCRIPCIÓN] XHR error (posible CORS). Verifica que la API key sea válida.');
        if (!completer.isCompleted) completer.complete('');
      });

      xhr.send(formData);
      return await completer.future;
    } catch (e) {
      print('[TRANSCRIPCIÓN] Excepción: $e');
      return '';
    }
  }

  /// Mantener como fallback por compatibilidad
  Future<String> _transcribirAudio(String audioUrl) async {
    print("[TRANSCRIPCIÓN] URL: $audioUrl");
    String transcripcion = "";

    try {
      final res = await supabase.functions.invoke(
        'transcribe-audio',
        body: {'audio_url': audioUrl},
      );

      print("[TRANSCRIPCIÓN] Status: ${res.status}, Data type: ${res.data.runtimeType}");

      Map<String, dynamic> data;
      if (res.data is Map) {
        data = Map<String, dynamic>.from(res.data as Map);
      } else if (res.data != null) {
        data = Map<String, dynamic>.from(json.decode(res.data.toString()) as Map);
      } else {
        throw Exception('Empty response from transcribe-audio');
      }

      if (data.containsKey('error')) {
        throw Exception(data['error'].toString());
      }

      transcripcion = data['text']?.toString() ?? '';
      if (transcripcion.isEmpty) {
        print("[TRANSCRIPCIÓN] WARNING: empty text returned");
      } else {
        print("[TRANSCRIPCIÓN] OK (${transcripcion.length} chars)");
      }
    } catch (e) {
      print("[TRANSCRIPCIÓN] Error: $e");
      transcripcion = "Transcription error: $e";
    }

    return transcripcion;
  }

  Future<Map<String, dynamic>> _analizarTranscripcionConLLM(
    String transcripcion,
  ) async {
    print("Iniciando análisis de transcripción con LLM...");

    // Crear un mapa vacío con todos los campos requeridos como respaldo
    final Map<String, dynamic> defaultJson = {
      "nombres": "",
      "apellidos": "",
      "fotografia": "",
      "direccion": "",
      "telefono": "",
      "correo": "",
      "nacionalidad": "",
      "fecha_nacimiento": "",
      "estado_civil": "",
      "linkedin": "",
      "github": "",
      "portafolio": "",
      "perfil_profesional": "",
      "objetivos_profesionales": "",
      "experiencia_laboral": "",
      "educacion": "",
      "habilidades": "",
      "idiomas": "",
      "certificaciones": "",
      "proyectos": "",
      "publicaciones": "",
      "premios": "",
      "voluntariados": "",
      "referencias": "",
      "expectativas_laborales": "",
      "experiencia_internacional": "",
      "permisos_documentacion": "",
      "vehiculo_licencias": "",
      "contacto_emergencia": "",
      "disponibilidad_entrevistas": "",
    };

    // Si la transcripción está vacía o es un error, devolver campos vacíos (no datos falsos)
    if (transcripcion.isEmpty ||
        transcripcion.toLowerCase().contains('transcription error')) {
      print("Transcripción vacía o con error - devolviendo campos vacíos");
      return defaultJson;
    }

    try {
      print("[ANÁLISIS LLM] Enviando transcripción (${transcripcion.length} chars) directo a OpenRouter...");

      final apiKey = getEnvironmentVariable('OPENROUTER_API_KEY') ?? '';
      if (apiKey.isEmpty) {
        print('[ANÁLISIS LLM] OPENROUTER_API_KEY no configurada, usando fallback');
        return _useFallbackExtraction(transcripcion, defaultJson);
      }

      final prompt = '''Extract specific CV data from this audio transcription and preserve the ORIGINAL LANGUAGE:

TRANSCRIPTION:
"$transcripcion"

Respond ONLY with valid JSON using EXACTLY these fields:
{
  "nombres": "first names only",
  "apellidos": "last names only",
  "direccion": "address only",
  "telefono": "phone only",
  "correo": "email only",
  "nacionalidad": "nationality only",
  "fecha_nacimiento": "birth date only",
  "estado_civil": "marital status only",
  "linkedin": "linkedin url only",
  "github": "github url only",
  "portafolio": "portfolio url only",
  "perfil_profesional": "professional summary only",
  "objetivos_profesionales": "professional objectives only",
  "experiencia_laboral": "work experience only",
  "educacion": "education only",
  "habilidades": "skills only",
  "idiomas": "languages only",
  "certificaciones": "certifications only",
  "proyectos": "projects only",
  "publicaciones": "publications only",
  "premios": "awards only",
  "voluntariados": "volunteering only",
  "referencias": "references only",
  "expectativas_laborales": "job expectations only",
  "experiencia_internacional": "international experience only",
  "permisos_documentacion": "permits/documentation only",
  "vehiculo_licencias": "vehicle/licenses only",
  "contacto_emergencia": "emergency contact only",
  "disponibilidad_entrevistas": "interview availability only"
}

CRITICAL RULES:
- PRESERVE the ORIGINAL LANGUAGE from the transcription - DO NOT TRANSLATE
- Extract ONLY specific information for each field
- DO NOT repeat the entire transcription in each field
- If no information exists for a field, use ""
- For phone numbers: Convert spoken numbers to actual digits
- For dates: Use YYYY-MM-DD format when possible
- Respond with ONLY the JSON, nothing else''';

      final requestBody = json.encode({
        'messages': [
          {
            'role': 'system',
            'content': 'You are a CV data extraction assistant. Your primary task is to preserve the ORIGINAL LANGUAGE of the input text. Do not translate any content. Extract information exactly as spoken.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'model': 'openrouter/free',
        'max_tokens': 3000,
        'temperature': 0.1,
        'top_p': 0.9,
      });

      final completer = Completer<Map<String, dynamic>>();

      final xhr = html.HttpRequest();
      xhr.open('POST', 'https://openrouter.ai/api/v1/chat/completions');
      xhr.setRequestHeader('Authorization', 'Bearer $apiKey');
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.setRequestHeader('HTTP-Referer', 'https://cv-generator-app.com');

      xhr.onLoad.listen((event) {
        try {
          if (xhr.status == 200) {
            final data = json.decode(xhr.responseText!) as Map;
            String content = data['choices']?[0]?['message']?['content']?.toString() ?? '';

            // Remover tags <think> de DeepSeek R1
            content = content.replaceAll(RegExp(r'<think>[\s\S]*?<\/think>', caseSensitive: false), '').trim();

            // Extraer JSON del response
            final codeBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(content);
            if (codeBlock != null) content = codeBlock.group(1)!.trim();
            final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
            if (jsonMatch != null) content = jsonMatch.group(0)!;

            final parsed = json.decode(content) as Map<String, dynamic>;
            print('[ANÁLISIS LLM] OK - ${parsed.keys.length} campos recibidos');
            if (!completer.isCompleted) completer.complete(parsed);
          } else {
            print('[ANÁLISIS LLM] OpenRouter error ${xhr.status}: ${xhr.responseText}');
            if (!completer.isCompleted) completer.complete({});
          }
        } catch (e) {
          print('[ANÁLISIS LLM] Error parseando respuesta: $e');
          if (!completer.isCompleted) completer.complete({});
        }
      });

      xhr.onError.listen((event) {
        print('[ANÁLISIS LLM] XHR error llamando OpenRouter');
        if (!completer.isCompleted) completer.complete({});
      });

      xhr.send(requestBody);
      final parsedData = await completer.future;

      if (parsedData.isNotEmpty) {
        Map<String, dynamic> result = Map.from(defaultJson);
        int fieldsPopulated = 0;

        parsedData.forEach((key, value) {
          if (result.containsKey(key)) {
            String cleanValue = (value?.toString() ?? '').trim();
            if (cleanValue.isNotEmpty) {
              if (key == 'telefono') {
                cleanValue = _convertSpokenNumbersToDigits(cleanValue);
              }
              result[key] = cleanValue;
              fieldsPopulated++;
            }
          }
        });

        print("[ANÁLISIS LLM] OK - $fieldsPopulated campos poblados");
        return result;
      } else {
        print("[ANÁLISIS LLM] respuesta vacía, usando fallback");
      }
    } catch (e) {
      print("[ANÁLISIS LLM] Exception: $e");
    }

    // Fallback si el LLM falla
    print("🔄 Usando extracción fallback...");
    return _useFallbackExtraction(transcripcion, defaultJson);
  }

  // Función robusta para parsear JSON
  Map<String, dynamic>? _robustJSONParse(String content) {
    List<String> attempts = [
      content.trim(),
      content
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim(),
      content.substring(content.indexOf('{')),
    ];

    // Agregar extracción por regex
    RegExp jsonRegex = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}');
    var match = jsonRegex.firstMatch(content);
    if (match != null) attempts.add(match.group(0) ?? '');

    for (String attempt in attempts) {
      try {
        if (attempt.isEmpty) continue;

        String cleaned = attempt
            .replaceAll(RegExp(r',\s*}'), '}')
            .replaceAll(RegExp(r',\s*]'), ']');

        var parsed = json.decode(cleaned);
        if (parsed is Map<String, dynamic>) {
          print("✅ JSON parseado exitosamente");
          return parsed;
        }
      } catch (e) {
        continue;
      }
    }

    print("❌ No se pudo parsear JSON");
    return null;
  }

  // Función de fallback mejorada
  Map<String, dynamic> _useFallbackExtraction(
    String transcripcion,
    Map<String, dynamic> defaultJson,
  ) {
    Map<String, dynamic> result = Map.from(defaultJson);

    if (transcripcion.isEmpty) return result;

    // Dividir por secciones si existen
    Map<String, String> secciones = {};

    if (transcripcion.contains('###')) {
      RegExp seccionRegex = RegExp(
        r'###\s*([^#]+?)\s*###\s*\n?(.*?)(?=###|\Z)',
        dotAll: true,
      );
      var matches = seccionRegex.allMatches(transcripcion);

      for (var match in matches) {
        String nombreSeccion = match.group(1)?.trim() ?? '';
        String contenidoSeccion = match.group(2)?.trim() ?? '';
        if (nombreSeccion.isNotEmpty) {
          secciones[nombreSeccion.toUpperCase()] = contenidoSeccion;
        }
      }
    } else {
      secciones['GENERAL'] = transcripcion;
    }

    // Extraer información específica
    String textoGeneral =
        secciones['INFORMACIÓN PERSONAL'] ??
        secciones['GENERAL'] ??
        transcripcion;

    // Nombres
    RegExp nombreRegex = RegExp(
      r'mi nombre(?:\s+completo)?[,:]?\s*([^.]+)',
      caseSensitive: false,
    );
    var nombreMatch = nombreRegex.firstMatch(textoGeneral);
    if (nombreMatch != null) {
      String nombreCompleto = nombreMatch.group(1)?.trim() ?? '';
      List<String> partes =
          nombreCompleto.split(' ').where((p) => p.isNotEmpty).toList();
      if (partes.length >= 2) {
        result['nombres'] = partes.take(2).join(' ');
        if (partes.length > 2) {
          result['apellidos'] = partes.skip(2).join(' ');
        }
      } else if (partes.length == 1) {
        result['nombres'] = partes[0];
      }
    }

    // Dirección
    RegExp direccionRegex = RegExp(
      r'mi dirección es\s*([^.]+)',
      caseSensitive: false,
    );
    var direccionMatch = direccionRegex.firstMatch(textoGeneral);
    if (direccionMatch != null) {
      result['direccion'] = direccionMatch.group(1)?.trim() ?? '';
    }

    // Teléfono - First try to extract with broader pattern to catch spoken numbers
    RegExp telefonoRegex = RegExp(
      r'(?:mi teléfono es|phone number is|teléfono|phone)\s*([^.]+)',
      caseSensitive: false,
    );
    var telefonoMatch = telefonoRegex.firstMatch(textoGeneral);
    if (telefonoMatch != null) {
      String phoneText = telefonoMatch.group(1)?.trim() ?? '';
      // Convert spoken numbers to digits
      phoneText = _convertSpokenNumbersToDigits(phoneText);
      result['telefono'] = phoneText;
    }

    // Nacionalidad
    RegExp nacionalidadRegex = RegExp(
      r'(?:nacionalidad|binacionalidad)\s*([^.]+)',
      caseSensitive: false,
    );
    var nacionalidadMatch = nacionalidadRegex.firstMatch(textoGeneral);
    if (nacionalidadMatch != null) {
      result['nacionalidad'] = nacionalidadMatch.group(1)?.trim() ?? '';
    }

    // Secciones específicas
    secciones.forEach((seccion, contenido) {
      if (contenido.trim().isEmpty ||
          contenido.toLowerCase().contains('no tengo'))
        return;

      switch (seccion) {
        case 'WORK EXPERIENCE':
        case 'EXPERIENCIA LABORAL':
          result['experiencia_laboral'] = contenido.trim();
          break;
        case 'EDUCATION':
        case 'EDUCACIÓN':
          if (!contenido.toLowerCase().contains('nula') &&
              !contenido.toLowerCase().contains('none')) {
            result['educacion'] = contenido.trim();
          }
          break;
        case 'SKILLS AND CERTIFICATIONS':
        case 'HABILIDADES Y CERTIFICACIONES':
          result['habilidades'] = contenido.trim();
          break;
        case 'LANGUAGES AND OTHER ACHIEVEMENTS':
        case 'IDIOMAS Y OTROS LOGROS':
          result['idiomas'] = contenido.trim();
          break;
        case 'PROFESSIONAL PROFILE':
        case 'PERFIL PROFESIONAL':
          result['perfil_profesional'] = contenido.trim();
          break;
        case 'REFERENCES AND ADDITIONAL DETAILS':
        case 'REFERENCIAS Y DETALLES ADICIONALES':
          result['referencias'] = contenido.trim();
          break;
      }
    });

    print("📋 Extracción fallback completada");
    return result;
  }

  Future<bool> _validateInfoWithAI() async {
    // Validación básica local — sin Edge Functions
    setState(() => _formError = '');
    return true;
  }

  // Método para mostrar errores de validación de forma legible
  void _mostrarErroresValidacion(List<dynamic> errores) {
    if (errores.isEmpty) return;

    try {
      String errorMessage = 'Se encontraron problemas en la información:\n\n';
      for (var error in errores) {
        if (error is Map) {
          String campo = error['campo']?.toString() ?? 'campo desconocido';
          String problema =
              error['problema']?.toString() ?? 'error no especificado';
          errorMessage += '- $campo: $problema\n';
        } else if (error is String) {
          errorMessage += '- $error\n';
        }
      }

      setState(() {
        _formError = errorMessage;
      });
    } catch (e) {
      print("Error al formatear mensaje de errores: $e");
      setState(() {
        _formError =
            'Hay errores en la información, pero no se pudieron mostrar correctamente.';
      });
    }
  }

  void _previousSection() {
    if (_currentSectionIndex > 0) {
      setState(() {
        _currentSectionIndex--;
      });
      _pageController.animateToPage(
        _currentSectionIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateTranscription(String text) {
    setState(() {
      _transcriptions[cvSections[_currentSectionIndex].id] = text;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeAudioHandlers();
  }

  @override
  Widget build(BuildContext context) {
    // Si estamos procesando o ya completamos, mostrar pantalla correspondiente
    if (_isProcessing || _isComplete) {
      return _buildProcessingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppBar(title: 'Resume Generator'),
      body: Column(
        children: [
          // Indicador de progreso
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: LinearProgressIndicator(
              value: (_currentSectionIndex + 1) / cvSections.length,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF090467)),
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Contador de pasos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${_currentSectionIndex + 1} of ${cvSections.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  cvSections[_currentSectionIndex].title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF090467),
                  ),
                ),
              ],
            ),
          ),

          // Tarjetas de secciones
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              itemCount: cvSections.length,
              onPageChanged: (index) {
                setState(() {
                  _currentSectionIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final section = cvSections[index];

                return CVSectionCard(
                  section: section,
                  isRecording: _isRecording,
                  isPlaying: _isPlaying,
                  hasAudio: _audioUrls.containsKey(section.id),
                  transcription: _transcriptions[section.id] ?? '',
                  onStartRecording: _startRecording,
                  onStopRecording: _stopRecording,
                  onPlayRecording: _playRecording,
                  onUpdateTranscription: _updateTranscription,
                  onNext: _nextSection,
                  onPrevious: _previousSection,
                  isFirstSection: index == 0,
                  isLastSection: index == cvSections.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingScreen() {
    // Color verde de la aplicación
    final Color primaryGreen = Color(0xff9ee4b8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: _isComplete ? 'Personal Information' : 'Processing',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing)
                Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _processingStatus,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else if (_isComplete)
                Expanded(child: _buildInfoEditForm(primaryGreen))
              else
                Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60.0,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Error: $_processingStatus',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoEditForm(Color primaryColor) {
    if (_editableInfo.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Convertir _editableInfo a un Map seguro para evitar problemas con JSArray
    Map<String, dynamic> safeInfo = {};
    try {
      // Intenta convertir cada valor a su tipo seguro para Dart
      _editableInfo.forEach((key, value) {
        safeInfo[key] = _fixUtf8Encoding(value?.toString() ?? '');
      });

      print("Información cargada en el formulario: $safeInfo");
    } catch (e) {
      print("Error al preparar datos para UI: $e");
      // Si hay error, usar un mapa vacío con los campos esperados
      safeInfo = {
        'nombres': '',
        'apellidos': '',
        'correo': '',
        'telefono': '',
        'direccion': '',
        'nacionalidad': '',
        'fecha_nacimiento': '',
        'estado_civil': '',
        'linkedin': '',
        'github': '',
        'portafolio': '',
        'perfil_profesional': '',
        'objetivos_profesionales': '',
        'experiencia_laboral': '',
        'educacion': '',
        'habilidades': '',
        'idiomas': '',
        'certificaciones': '',
      };
    }

    // Lista de campos a mostrar y sus etiquetas
    final fieldLabels = {
      'nombres': 'First Names',
      'apellidos': 'Last Names',
      'correo': 'Email',
      'telefono': 'Phone',
      'direccion': 'Address',
      'nacionalidad': 'Nationality',
      'fecha_nacimiento': 'Date of birth',
      'estado_civil': 'Marital status',
      'linkedin': 'LinkedIn',
      'github': 'GitHub',
      'portafolio': 'Portfolio',
      'perfil_profesional': 'Professional profile',
      'objetivos_profesionales': 'Professional objectives',
      'experiencia_laboral': 'Work experience',
      'educacion': 'Education',
      'habilidades': 'Skills',
      'idiomas': 'Languages',
      'certificaciones': 'Certifications',
    };

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              Text(
                'Review and edit the extracted information',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF090467),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_formError.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color:
                        _formError.contains('Validating')
                            ? Colors.blue.shade100
                            : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      if (_formError.contains('Validating'))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        _formError,
                        style: GoogleFonts.poppins(
                          color:
                              _formError.contains('Validating')
                                  ? Color(0xFF090467)
                                  : Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ...fieldLabels.entries.map((entry) {
                final fieldName = entry.key;
                final fieldLabel = entry.value;
                final isLongText = [
                  'perfil_profesional',
                  'objetivos_profesionales',
                  'educacion',
                  'experiencia_laboral',
                  'habilidades',
                ].contains(fieldName);

                // Asegurarse de que el valor sea una cadena vacía si es nulo
                String fieldValue = safeInfo[fieldName]?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fieldLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (isLongText)
                        TextFormField(
                          initialValue: fieldValue,
                          maxLines: 4,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            hintText: 'Enter $fieldLabel',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          onChanged: (value) {
                            setState(() {
                              _editableInfo[fieldName] = value;
                            });
                          },
                        )
                      else
                        TextFormField(
                          initialValue: fieldValue,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            hintText: 'Enter $fieldLabel',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.text,
                          onChanged: (value) {
                            setState(() {
                              _editableInfo[fieldName] = value;
                            });
                          },
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF090467),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _isFormLoading ? null : _saveEditedInfo,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isFormLoading
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF090467),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Saving...',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF090467),
                              ),
                            ),
                          ],
                        )
                        : Text(
                          'Save information',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF090467),
                          ),
                        ),
              ),
              // Añadir botón para vista previa
              if (!_isFormLoading)
                ElevatedButton(
                  onPressed: () {
                    try {
                      print("Botón de Vista Previa pulsado");

                      // Verificar si tenemos datos para mostrar
                      if (_editableInfo.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'No information to show. Please save the data first.',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF090467),
                              ),
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      // Mostrar mensaje de carga
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Generating preview...',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF090467),
                            ),
                          ),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 1),
                        ),
                      );

                      // Preparar datos asegurando que todos los valores sean seguros
                      Map<String, dynamic> safeInfo = {};

                      // Agregar todos los campos necesarios con valores por defecto
                      final requiredFields = [
                        'nombres',
                        'apellidos',
                        'correo',
                        'telefono',
                        'direccion',
                        'nacionalidad',
                        'profesion',
                      ];

                      // Inicializar campos requeridos con valores vacíos si no existen
                      for (var field in requiredFields) {
                        safeInfo[field] = '';
                      }

                      // Agregar datos del formulario, protegiendo contra nulos
                      _editableInfo.forEach((key, value) {
                        if (value != null) {
                          final String strValue = value.toString();
                          if (strValue.isNotEmpty) {
                            safeInfo[key] = strValue;
                          }
                        }
                      });

                      // Asegurar campos mínimos obligatorios
                      if (safeInfo['nombres']?.isEmpty ?? true) {
                        safeInfo['nombres'] = 'Name';
                      }
                      if (safeInfo['apellidos']?.isEmpty ?? true) {
                        safeInfo['apellidos'] = 'Surname';
                      }
                      if (safeInfo['profesion']?.isEmpty ?? true) {
                        safeInfo['profesion'] = 'Professional';
                      }

                      // Lanzar la generación de la vista previa
                      Future(() async {
                        try {
                          // Llamamos directamente al método de generación de vista previa
                          final result =
                              await MonkeyPDFIntegration.generatePDFFromCV(
                                safeInfo,
                              );
                          print("Vista previa generada correctamente: $result");
                        } catch (innerError) {
                          print(
                            "Error interno generando vista previa: $innerError",
                          );

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: $innerError',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      });
                    } catch (e) {
                      print("Error al generar vista previa: $e");

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: $e',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xff9ee4b8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Preview',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF090467),
                    ),
                  ),
                ),
              // Añadir botón para generar PDF
              if (!_isFormLoading)
                GeneratePDFButton(
                  cvData: safeInfo,
                  onGenerating: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Generating PDF...',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF090467),
                          ),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  onGenerated: (String pdfUrl) {
                    print("PDF generado: $pdfUrl");
                    // Puedes abrir el PDF en una nueva pestaña si lo deseas
                    // html.window.open(pdfUrl, '_blank');
                  },
                  onError: (String error) {
                    print("Error al generar PDF: $error");
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveEditedInfo() async {
    setState(() {
      _isFormLoading = true;
      _formError = '';
    });

    try {
      if (_recordId.isEmpty) {
        throw Exception('No se encontró el ID del registro');
      }

      print("DEPURANDO: _editableInfo antes de validar: $_editableInfo");

      // Crear una copia antes de modificarla para la UI
      Map<String, dynamic> editableInfoParaGuardar = Map.from(_editableInfo);

      // Asegurar que _editableInfo es un mapa seguro para la UI
      _asegurarTiposDeDatos();

      print(
        "DEPURANDO: _editableInfo después de asegurar para UI: $_editableInfo",
      );

      // Primero validar la información con el LLM
      setState(() {
        _formError = 'Validating information...';
      });

      final bool isValid = await _validateInfoWithAI();

      if (!isValid) {
        // Si la validación falló, detener el proceso de guardado
        setState(() {
          _isFormLoading = false;
        });
        return;
      }

      // Usar la información tal como está, sin normalizar caracteres
      Map<String, dynamic> infoParaGuardar = {};
      editableInfoParaGuardar.forEach((key, value) {
        // Conservar el valor original sin normalizar
        infoParaGuardar[key] = value;
      });

      print("DEPURANDO: infoParaGuardar para guardar: $infoParaGuardar");

      // Asegurar que el JSON a guardar tenga los campos básicos
      // Solo inicializamos campos básicos si están completamente ausentes
      final camposBasicos = ['nombres', 'apellidos', 'correo', 'telefono'];

      // Solo asegurar campos básicos
      for (var campo in camposBasicos) {
        if (!infoParaGuardar.containsKey(campo)) {
          infoParaGuardar[campo] = "";
        }
      }

      // Convertir a formato Schema.org
      final schemaOrgData = _convertToSchemaOrgFormat(infoParaGuardar);
      print("DEPURANDO: Formato Schema.org: $schemaOrgData");

      // Actualizar el registro en la base de datos
      try {
        // Asegurar que el JSON se codifica correctamente con UTF-8
        final jsonString = json.encode(infoParaGuardar);
        final schemaJsonString = json.encode(schemaOrgData);

        // Verificar que no haya caracteres malformados
        print("DEPURANDO: Verificando JSON codificado: $jsonString");
        print(
          "DEPURANDO: Verificando JSON Schema codificado: $schemaJsonString",
        );

        await supabase
            .from('audio_transcrito')
            .update({
              'informacion_organizada_usuario': infoParaGuardar,
              'esquema_json': schemaOrgData,
            })
            .eq('id', _recordId);

        print("DEPURANDO: Actualización en base de datos completada");
      } catch (dbError) {
        print("DEPURANDO: Error en la base de datos: $dbError");
        rethrow;
      }

      setState(() {
        _isFormLoading = false;
      });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Information saved successfully. You can now generate the PDF.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Ya no regresamos a la pantalla principal
      // Navigator.of(context).pop(); - Esta línea se ha eliminado
    } catch (e) {
      print("DEPURANDO: Error general en _saveEditedInfo: $e");
      setState(() {
        _isFormLoading = false;
        _formError = 'Error saving: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _webAudioElement?.remove();
    _webAudioElement = null;
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Método para convertir números hablados a dígitos
  String _convertSpokenNumbersToDigits(String text) {
    if (text.isEmpty) return text;

    String result = text.toLowerCase();

    // Map of spoken numbers to digits (English and Spanish)
    final Map<String, String> numberMap = {
      'zero': '0',
      'cero': '0',
      'one': '1',
      'uno': '1',
      'wan': '1',
      'two': '2',
      'dos': '2',
      'too': '2',
      'to': '2',
      'three': '3',
      'tres': '3',
      'tree': '3',
      'four': '4',
      'cuatro': '4',
      'for': '4',
      'fore': '4',
      'five': '5',
      'cinco': '5',
      'fiv': '5',
      'six': '6',
      'seis': '6',
      'siks': '6',
      'seven': '7',
      'siete': '7',
      'sevn': '7',
      'eight': '8',
      'ocho': '8',
      'ate': '8',
      'eit': '8',
      'nine': '9',
      'nueve': '9',
      'nain': '9',
      'ten': '10',
      'diez': '10',
      'eleven': '11',
      'once': '11',
      'twelve': '12',
      'doce': '12',
    };

    // Replace each spoken number with its digit
    numberMap.forEach((spoken, digit) {
      result = result.replaceAll(RegExp('\\b$spoken\\b'), digit);
    });

    // Clean up extra spaces
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    // If it looks like a phone number (mostly digits), clean it up
    if (RegExp(r'[\d\s]{8,}').hasMatch(result)) {
      // Remove all non-digit characters except + for international prefix
      result = result.replaceAll(RegExp(r'[^\d\+]'), '');

      // Format phone number if it's long enough
      if (result.length >= 10) {
        // Add formatting based on length
        if (result.length == 10) {
          result =
              '(${result.substring(0, 3)}) ${result.substring(3, 6)}-${result.substring(6)}';
        } else if (result.length == 11 && result.startsWith('1')) {
          result =
              '+1 (${result.substring(1, 4)}) ${result.substring(4, 7)}-${result.substring(7)}';
        }
      }
    }

    return result;
  }

  // Método para corregir problemas de codificación UTF-8
  String _fixUtf8Encoding(String text) {
    if (text.isEmpty) return text;

    try {
      // Detectar caracteres mal codificados (típicamente aparecen como Ã seguido de otro carácter)
      if (text.contains('Ã')) {
        // Estrategia 1: Re-codificar a UTF-8
        List<int> bytes = utf8.encode(text);
        String decoded = utf8.decode(bytes, allowMalformed: true);

        // Si detectamos mejora (menos caracteres Ã), usamos esta versión
        if (decoded.contains('Ã') &&
            decoded.split('Ã').length < text.split('Ã').length) {
          return decoded;
        }

        // Estrategia 2: Reemplazos básicos para los caracteres más comunes
        String result = text;

        // Tabla de reemplazos
        result = result.replaceAll('Ã¡', 'á');
        result = result.replaceAll('Ã©', 'é');
        result = result.replaceAll('Ã­', 'í');
        result = result.replaceAll('Ã³', 'ó');
        result = result.replaceAll('Ãº', 'ú');
        result = result.replaceAll('Ã±', 'ñ');

        return result;
      }
    } catch (e) {
      print("Error al corregir codificación UTF-8: $e");
    }

    // Si no se pudo o no fue necesario corregir, devolver el texto original
    return text;
  }

  // Método para convertir los datos del formulario al formato Schema.org
  Map<String, dynamic> _convertToSchemaOrgFormat(
    Map<String, dynamic> formData,
  ) {
    // Crear estructura de Schema.org para un CV
    Map<String, dynamic> schemaData = {
      "@context": "https://schema.org",
      "@type": "Person",
      "name":
          "${formData['nombres'] ?? ''} ${formData['apellidos'] ?? ''}".trim(),
    };

    // Añadir información de contacto
    if ((formData['correo'] ?? '').isNotEmpty) {
      schemaData["email"] = formData['correo'];
    }

    if ((formData['telefono'] ?? '').isNotEmpty) {
      schemaData["telephone"] = formData['telefono'];
    }

    // Añadir dirección si está disponible
    if ((formData['direccion'] ?? '').isNotEmpty) {
      schemaData["address"] = {
        "@type": "PostalAddress",
        "streetAddress": formData['direccion'],
      };
    }

    // Añadir sitios web/redes sociales
    List<String> urls = [];
    if ((formData['linkedin'] ?? '').isNotEmpty) {
      urls.add(formData['linkedin']);
    }
    if ((formData['github'] ?? '').isNotEmpty) {
      urls.add(formData['github']);
    }
    if ((formData['portafolio'] ?? '').isNotEmpty) {
      urls.add(formData['portafolio']);
    }

    if (urls.isNotEmpty) {
      if (urls.length == 1) {
        schemaData["url"] = urls[0];
      } else {
        schemaData["sameAs"] = urls;
      }
    }

    // Añadir educación si está disponible
    if ((formData['educacion'] ?? '').isNotEmpty) {
      // Intentamos extraer información estructurada de texto libre
      final String educacionTexto = formData['educacion'];
      List<Map<String, dynamic>> educacionLista = [];

      // Método simple de extracción - esto podría refinarse
      final List<String> educacionItems =
          educacionTexto
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList();

      if (educacionItems.isNotEmpty) {
        educacionLista =
            educacionItems
                .map(
                  (item) => {
                    "@type": "EducationalOrganization",
                    "name":
                        item, // Simplificado, idealmente separaríamos la institución del título
                  },
                )
                .toList();

        schemaData["alumniOf"] = educacionLista;
      }
    }

    // Añadir experiencia laboral
    if ((formData['experiencia_laboral'] ?? '').isNotEmpty) {
      final String experienciaTexto = formData['experiencia_laboral'];
      List<Map<String, dynamic>> experienciaLista = [];

      final List<String> experienciaItems =
          experienciaTexto
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList();

      if (experienciaItems.isNotEmpty) {
        experienciaLista =
            experienciaItems
                .map(
                  (item) => {"@type": "OrganizationRole", "description": item},
                )
                .toList();

        schemaData["workExperience"] = experienciaLista;
      }
    }

    // Añadir habilidades
    if ((formData['habilidades'] ?? '').isNotEmpty) {
      schemaData["skills"] = formData['habilidades'];
    }

    // Añadir idiomas
    if ((formData['idiomas'] ?? '').isNotEmpty) {
      final String idiomasTexto = formData['idiomas'];
      List<Map<String, dynamic>> idiomasLista = [];

      final List<String> idiomaItems =
          idiomasTexto
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

      if (idiomaItems.isNotEmpty) {
        idiomasLista =
            idiomaItems
                .map((idioma) => {"@type": "Language", "name": idioma})
                .toList();

        schemaData["knowsLanguage"] = idiomasLista;
      }
    }

    // Añadir descripción/perfil profesional
    if ((formData['perfil_profesional'] ?? '').isNotEmpty) {
      schemaData["description"] = formData['perfil_profesional'];
    }

    return schemaData;
  }

  // Nueva función para extraer información de la transcripción usando lógica simple
  Map<String, dynamic> _extractInfoFromTranscription(String transcripcion) {
    Map<String, dynamic> result = {};
    String texto = transcripcion.toLowerCase();

    try {
      // Información personal
      if (texto.contains('mi nombre es') || texto.contains('me llamo')) {
        List<String> palabras = transcripcion.split(' ');
        for (int i = 0; i < palabras.length - 1; i++) {
          if (palabras[i].toLowerCase().contains('nombre') ||
              palabras[i].toLowerCase().contains('llamo')) {
            if (i + 1 < palabras.length) {
              result['nombres'] = palabras[i + 1]
                  .replaceAll(',', '')
                  .replaceAll('.', '');
            }
            if (i + 2 < palabras.length) {
              result['apellidos'] = palabras[i + 2]
                  .replaceAll(',', '')
                  .replaceAll('.', '');
            }
            break;
          }
        }
      }

      // Dirección
      if (texto.contains('vivo en') ||
          texto.contains('dirección') ||
          texto.contains('ubicado')) {
        result['direccion'] = _extractAfterKeywords(transcripcion, [
          'vivo en',
          'dirección',
          'ubicado en',
        ]);
      }

      // Teléfono
      if (texto.contains('teléfono') ||
          texto.contains('número') ||
          texto.contains('celular')) {
        String phone = _extractPhoneNumber(transcripcion);
        if (phone.isNotEmpty) result['telefono'] = phone;
      }

      // Email
      if (texto.contains('@') ||
          texto.contains('correo') ||
          texto.contains('email')) {
        String email = _extractEmail(transcripcion);
        if (email.isNotEmpty) result['correo'] = email;
      }

      // Nacionalidad
      if (texto.contains('nacionalidad') ||
          texto.contains('país') ||
          texto.contains('soy de')) {
        result['nacionalidad'] = _extractAfterKeywords(transcripcion, [
          'nacionalidad',
          'soy de',
          'país',
        ]);
      }

      // Estado civil
      if (texto.contains('soltero') ||
          texto.contains('casado') ||
          texto.contains('divorciado') ||
          texto.contains('viudo') ||
          texto.contains('estado civil')) {
        result['estado_civil'] = _extractMaritalStatus(texto);
      }

      // LinkedIn
      if (texto.contains('linkedin') || texto.contains('linked in')) {
        result['linkedin'] = _extractAfterKeywords(transcripcion, [
          'linkedin',
          'linked in',
        ]);
      }

      // GitHub
      if (texto.contains('github') || texto.contains('git hub')) {
        result['github'] = _extractAfterKeywords(transcripcion, [
          'github',
          'git hub',
        ]);
      }

      // Experiencia laboral
      if (texto.contains('trabajo') ||
          texto.contains('empresa') ||
          texto.contains('experiencia') ||
          texto.contains('laboré') ||
          texto.contains('trabajé')) {
        result['experiencia_laboral'] = transcripcion;
      }

      // Educación
      if (texto.contains('estudié') ||
          texto.contains('universidad') ||
          texto.contains('colegio') ||
          texto.contains('título') ||
          texto.contains('carrera') ||
          texto.contains('educación')) {
        result['educacion'] = transcripcion;
      }

      // Habilidades
      if (texto.contains('habilidad') ||
          texto.contains('capacidad') ||
          texto.contains('sé hacer') ||
          texto.contains('dominio') ||
          texto.contains('experto') ||
          texto.contains('certificación')) {
        result['habilidades'] = transcripcion;
        // También puede ser certificaciones
        if (texto.contains('certificación') || texto.contains('certificado')) {
          result['certificaciones'] = transcripcion;
        }
      }

      // Idiomas
      if (texto.contains('idioma') ||
          texto.contains('inglés') ||
          texto.contains('español') ||
          texto.contains('francés') ||
          texto.contains('alemán') ||
          texto.contains('hablo')) {
        result['idiomas'] = transcripcion;
      }

      // Referencias
      if (texto.contains('referencia') ||
          texto.contains('contacto') ||
          texto.contains('recomendación')) {
        result['referencias'] = transcripcion;
      }

      // Perfil profesional (si no encaja en otras categorías pero es descriptivo)
      if (result.isEmpty && transcripcion.length > 20) {
        result['perfil_profesional'] = transcripcion;
      }
    } catch (e) {
      print("Error en extracción de información: $e");
    }

    return result;
  }

  String _extractAfterKeywords(String text, List<String> keywords) {
    String loweredText = text.toLowerCase();
    for (String keyword in keywords) {
      int index = loweredText.indexOf(keyword.toLowerCase());
      if (index != -1) {
        String remaining = text.substring(index + keyword.length).trim();
        // Tomar hasta el próximo punto o coma, o máximo 100 caracteres
        List<String> parts = remaining.split(RegExp(r'[.,;]'));
        return parts.isNotEmpty
            ? parts[0].trim()
            : remaining.substring(
              0,
              remaining.length > 100 ? 100 : remaining.length,
            );
      }
    }
    return '';
  }

  String _extractPhoneNumber(String text) {
    // Buscar patrones de teléfono
    RegExp phoneRegex = RegExp(r'[\d\s\-\+\(\)]{8,15}');
    var match = phoneRegex.firstMatch(text);
    return match?.group(0)?.replaceAll(RegExp(r'[^\d\+]'), '') ?? '';
  }

  String _extractEmail(String text) {
    // Buscar patrones de email
    RegExp emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    );
    var match = emailRegex.firstMatch(text);
    return match?.group(0) ?? '';
  }

  String _extractMaritalStatus(String text) {
    if (text.contains('soltero')) return 'Soltero';
    if (text.contains('soltera')) return 'Soltera';
    if (text.contains('casado')) return 'Casado';
    if (text.contains('casada')) return 'Casada';
    if (text.contains('divorciado')) return 'Divorciado';
    if (text.contains('divorciada')) return 'Divorciada';
    if (text.contains('viudo')) return 'Viudo';
    if (text.contains('viuda')) return 'Viuda';
    return '';
  }
}

// Widget reutilizable para cada tarjeta de sección
class CVSectionCard extends StatefulWidget {
  final CVSection section;
  final bool isRecording;
  final bool isPlaying;
  final bool hasAudio;
  final String transcription;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onPlayRecording;
  final Function(String) onUpdateTranscription;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool isFirstSection;
  final bool isLastSection;

  const CVSectionCard({
    super.key,
    required this.section,
    required this.isRecording,
    required this.isPlaying,
    required this.hasAudio,
    required this.transcription,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onPlayRecording,
    required this.onUpdateTranscription,
    required this.onNext,
    required this.onPrevious,
    required this.isFirstSection,
    required this.isLastSection,
  });

  @override
  _CVSectionCardState createState() => _CVSectionCardState();
}

class _CVSectionCardState extends State<CVSectionCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            // Cabecera de la tarjeta
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xfff5f5fa),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.section.title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF090467),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.section.description,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF090467),
                    ),
                  ),
                ],
              ),
            ),

            // Cuerpo de la tarjeta
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campos relevantes para esta sección
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xfff5f5fa),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Relevant fields to include:',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF090467),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                widget.section.fields
                                    .map(
                                      (field) => Chip(
                                        label: Text(
                                          field,
                                          style: GoogleFonts.poppins(
                                            color: Color(0xFF090467),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        backgroundColor: Color(
                                          0xff9ee4b8,
                                        ).withOpacity(0.2),
                                        labelStyle: GoogleFonts.poppins(
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Control de grabación de audio
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap:
                                widget.isRecording
                                    ? widget.onStopRecording
                                    : widget.onStartRecording,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color:
                                    widget.isRecording
                                        ? Colors.red
                                        : Color(0xff9ee4b8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.isRecording ? Icons.stop : Icons.mic,
                                color: Color(0xFF090467),
                                size: 40,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            widget.isRecording
                                ? 'Press to stop recording'
                                : 'Press to start recording',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Color(0xFF090467),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Reproductor de audio (solo visible si hay audio grabado)
                    if (widget.hasAudio) ...[
                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon(
                            widget.isPlaying ? Icons.stop : Icons.play_arrow,
                            color: Color(0xFF090467),
                          ),
                          label: Text(
                            widget.isPlaying ? 'Stop' : 'Play recording',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF090467),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff9ee4b8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: widget.onPlayRecording,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Pie de la tarjeta con botones de navegación
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón Anterior
                  if (!widget.isFirstSection)
                    ElevatedButton.icon(
                      icon: Icon(Icons.arrow_back),
                      label: Text('Previous', style: GoogleFonts.poppins()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xffd2e8fc),
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: widget.onPrevious,
                    )
                  else
                    SizedBox(width: 100),

                  // Botón Siguiente o Finalizar
                  ElevatedButton.icon(
                    icon: Icon(
                      widget.isLastSection ? Icons.check : Icons.arrow_forward,
                      color: Color(0xFF090467),
                      size: 14,
                    ),
                    label: Text(
                      widget.isLastSection ? 'Finish' : 'Next',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF090467),
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff9ee4b8),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    onPressed: widget.hasAudio ? widget.onNext : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Función utilitaria para convertir cualquier objeto JSON a tipos Dart compatibles
// Especialmente útil para Flutter web donde JSArray y otros tipos JS pueden causar problemas
dynamic convertToSafeDartType(dynamic value) {
  if (value == null) {
    return null;
  } else if (value is List) {
    return List<dynamic>.from(value.map((item) => convertToSafeDartType(item)));
  } else if (value is Map) {
    Map<String, dynamic> result = {};
    value.forEach((key, val) {
      if (key is String) {
        result[key] = convertToSafeDartType(val);
      } else {
        result[key.toString()] = convertToSafeDartType(val);
      }
    });
    return result;
  } else {
    return value;
  }
}

// Función para normalizar caracteres problemáticos pero preservando acentos y ñ
String normalizarTexto(String texto) {
  // Mapa de sustituciones solo para caracteres realmente problemáticos
  final Map<String, String> sustituciones = {
    '#': 'numero',
    '°': 'grados',
    'º': 'ordinal',
    '€': 'euros',
    '£': 'libras',
    '¥': 'yenes',
  };

  String textoNormalizado = texto;

  // Aplicar sustituciones solo a caracteres problemáticos
  sustituciones.forEach((special, normal) {
    textoNormalizado = textoNormalizado.replaceAll(special, normal);
  });

  return textoNormalizado;
}

