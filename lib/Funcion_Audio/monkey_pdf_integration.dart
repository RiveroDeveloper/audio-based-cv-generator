import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:js' as js;

/// Clase para integrar con API para convertir HTML a PDF
class MonkeyPDFIntegration {
  // Usar htmltopdf.io que es más compatible con CORS
  static const String _apiKey =
      '17B87A5F5CEB'; // Reemplazar con tu propia API key
  static const String _apiUrl = 'https://api.html2pdf.app/v1/generate';

  /// Método para generar un PDF desde los datos de un CV
  /// Toma los datos del CV en formato Map y devuelve una URL al PDF generado
  static Future<String> generatePDFFromCV(Map<String, dynamic> cvData) async {
    try {
      // Validar datos de entrada
      if (cvData.isEmpty) {
        print("Error: No hay datos para generar el PDF");
        throw Exception('No hay datos suficientes para generar el PDF');
      }

      print("Iniciando generación de PDF con ${cvData.length} campos");

      // 1. Aplicar los datos del CV a una plantilla HTML
      final String htmlContent = _applyDataToTemplate(cvData);

      if (htmlContent.isEmpty) {
        print("Error: La plantilla HTML generada está vacía");
        throw Exception('La plantilla HTML generada está vacía');
      }

      print(
        "Plantilla HTML generada correctamente, longitud: ${htmlContent.length}",
      );

      // 2. Generar archivo PDF directamente en el navegador usando html2canvas y jsPDF
      return _generatePDFInBrowser(htmlContent, cvData);
    } catch (e) {
      print("Error generando PDF: $e");
      print("Stack trace: ${StackTrace.current}");

      // Si el error es un RangeError, proporcionar información más detallada
      if (e is RangeError) {
        print(
          "RangeError detectado: ${e.message}. Este error puede ocurrir al procesar la plantilla.",
        );
        throw Exception(
          'Error en la generación del PDF: Problema con índices en la plantilla. Por favor, intente de nuevo o contacte soporte.',
        );
      }

      throw Exception('Error en la generación del PDF: $e');
    }
  }

  /// Método para generar PDF en el navegador sin depender de API externas
  static Future<String> _generatePDFInBrowser(
    String htmlContent,
    Map<String, dynamic> cvData,
  ) async {
    try {
      print("Iniciando generación de vista previa con método ultra simple...");

      // Crear un nuevo div para mostrar la vista previa
      final previewId = 'cv-preview-container';

      // Remover versión anterior si existe
      final existingPreview = html.document.getElementById(previewId);
      if (existingPreview != null) {
        existingPreview.remove();
        print("Contenedor previo eliminado");
      }

      // Crear contenedor principal con fondo oscuro transparente
      final previewContainer =
          html.DivElement()
            ..id = previewId
            ..style.position = 'fixed'
            ..style.top = '0'
            ..style.left = '0'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.backgroundColor = 'rgba(0,0,0,0.85)'
            ..style.zIndex = '9999'
            ..style.display = 'flex'
            ..style.flexDirection = 'column'
            ..style.justifyContent = 'center'
            ..style.alignItems = 'center';

      // Intentar aplicar backdrop-filter si el navegador lo soporta
      try {
        js.context.callMethod('eval', [
          'document.getElementById("$previewId").style.backdropFilter = "blur(5px)";',
        ]);
      } catch (e) {
        // Si no es soportado, no hacer nada
        print("Backdrop filter no soportado: $e");
      }

      // Botón de cierre en la esquina superior derecha
      final closeButton =
          html.ButtonElement()
            ..innerText = '✕'
            ..style.position = 'absolute'
            ..style.top = '20px'
            ..style.right = '20px'
            ..style.backgroundColor = 'transparent'
            ..style.border = 'none'
            ..style.color = 'white'
            ..style.fontSize = '28px'
            ..style.cursor = 'pointer'
            ..style.transition = 'all 0.2s ease'
            ..style.width = '40px'
            ..style.height = '40px'
            ..style.borderRadius = '50%'
            ..style.display = 'flex'
            ..style.justifyContent = 'center'
            ..style.alignItems = 'center'
            ..onClick.listen((event) {
              previewContainer.remove();
              print("Vista previa cerrada por el usuario");
            });

      // Efecto hover para el botón de cierre
      closeButton.onMouseOver.listen((event) {
        closeButton.style.backgroundColor = 'rgba(255,255,255,0.2)';
        closeButton.style.transform = 'scale(1.1)';
      });

      closeButton.onMouseOut.listen((event) {
        closeButton.style.backgroundColor = 'transparent';
        closeButton.style.transform = 'scale(1)';
      });

      // Un simple contenedor para el CV
      final contentContainer =
          html.DivElement()
            ..style.backgroundColor = 'white'
            ..style.maxWidth = '800px'
            ..style.width = '90%'
            ..style.maxHeight = '80vh'
            ..style.overflowY = 'auto'
            ..style.padding = '0'
            ..style.borderRadius = '12px'
            ..style.boxShadow = '0 10px 30px rgba(0,0,0,0.25)'
            ..style.transition = 'all 0.3s ease';

      // Insertar el HTML directamente
      contentContainer.setInnerHtml(
        htmlContent,
        validator:
            html.NodeValidatorBuilder()
              ..allowHtml5()
              ..allowInlineStyles()
              ..allowElement('style', attributes: ['type'])
              ..allowElement('title')
              ..allowElement(
                'meta',
                attributes: [
                  'charset',
                  'http-equiv',
                  'content',
                  'name',
                  'viewport',
                ],
              )
              ..allowElement('link', attributes: ['rel', 'href', 'type'])
              ..allowSvg()
              ..allowNavigation()
              ..allowImages()
              ..allowTextElements(),
      );

      // Crear barra de botones
      final buttonBar =
          html.DivElement()
            ..style.display = 'flex'
            ..style.justifyContent = 'center'
            ..style.marginTop = '25px'
            ..style.gap = '15px';

      // Botón para descargar PDF
      final downloadButton =
          html.ButtonElement()
            ..innerText = 'Descargar PDF'
            ..style.padding = '12px 25px'
            ..style.backgroundColor = '#00FF7F'
            ..style.color = '#333'
            ..style.border = 'none'
            ..style.borderRadius = '8px'
            ..style.cursor = 'pointer'
            ..style.fontWeight = 'bold'
            ..style.fontSize = '16px'
            ..style.transition = 'all 0.2s ease'
            ..style.boxShadow = '0 4px 12px rgba(0, 255, 127, 0.3)'
            ..onClick.listen((event) {
              print("Botón de descarga pulsado");
              _downloadAsPDF(previewContainer);
            });

      // Efecto hover para el botón de descarga
      downloadButton.onMouseOver.listen((event) {
        downloadButton.style.backgroundColor = '#00E070';
        downloadButton.style.transform = 'translateY(-2px)';
        downloadButton.style.boxShadow = '0 6px 15px rgba(0, 255, 127, 0.4)';
      });

      downloadButton.onMouseOut.listen((event) {
        downloadButton.style.backgroundColor = '#00FF7F';
        downloadButton.style.transform = 'translateY(0)';
        downloadButton.style.boxShadow = '0 4px 12px rgba(0, 255, 127, 0.3)';
      });

      // Botón para cerrar la vista previa
      final closeViewButton =
          html.ButtonElement()
            ..innerText = 'Cerrar Vista Previa'
            ..style.padding = '12px 25px'
            ..style.backgroundColor = 'transparent'
            ..style.color = 'white'
            ..style.border = '2px solid white'
            ..style.borderRadius = '8px'
            ..style.cursor = 'pointer'
            ..style.fontWeight = 'bold'
            ..style.fontSize = '16px'
            ..style.transition = 'all 0.2s ease'
            ..onClick.listen((event) {
              previewContainer.remove();
              print("Vista previa cerrada desde botón inferior");
            });

      // Efecto hover para el botón de cerrar
      closeViewButton.onMouseOver.listen((event) {
        closeViewButton.style.backgroundColor = 'rgba(255,255,255,0.2)';
      });

      closeViewButton.onMouseOut.listen((event) {
        closeViewButton.style.backgroundColor = 'transparent';
      });

      // Juntar todos los elementos
      buttonBar.append(downloadButton);
      buttonBar.append(closeViewButton);
      previewContainer.append(closeButton);
      previewContainer.append(contentContainer);
      previewContainer.append(buttonBar);

      // Agregar al documento
      html.document.body!.append(previewContainer);

      // Añadir efecto de entrada con animación
      try {
        js.context.callMethod('eval', [
          'setTimeout(function() { document.querySelector("#$previewId > div:nth-child(2)").style.opacity = "1"; }, 100);',
        ]);
      } catch (e) {
        // Si hay un error, simplemente ignorarlo
        print("Error al aplicar animación: $e");
      }

      return "preview-generated";
    } catch (e) {
      print("Error al generar vista previa: $e");
      html.window.alert("Error al generar vista previa: $e");
      throw Exception('Error al generar vista previa: $e');
    }
  }

  /// Método para descargar el contenido como PDF
  static void _downloadAsPDF(html.Element contentElement) {
    try {
      // Asegurar que las librerías estén cargadas primero
      _loadJsLibraries(() {
        // Código JavaScript extremadamente simple sin ningún cálculo de coordenadas
        final jsCode = '''
          console.log("Generando PDF con método ultra simple...");
          
          // Función para guardar como PDF sin ningún cálculo problemático
          function simpleSavePDF() {
            try {
              // Buscar el contenedor de CV con múltiples opciones de selector
              var contentContainer = null;
              
              // Intentar varios selectores para encontrar el contenedor
              var selectors = [
                "#cv-preview-container div.container",
                "#cv-preview-container .container",
                "#cv-preview-container > div > div",
                "#cv-preview-container > div:nth-child(2)",
                "#cv-preview-container > div"
              ];
              
              // Probar cada selector hasta encontrar uno válido
              for (var i = 0; i < selectors.length; i++) {
                contentContainer = document.querySelector(selectors[i]);
                if (contentContainer) {
                  console.log("Contenedor encontrado con selector: " + selectors[i]);
                  break;
                }
              }
              
              // Si todavía no encontramos el contenedor, buscar de otra manera
              if (!contentContainer) {
                console.log("Intentando encontrar el contenedor por estructura anidada");
                var parentContainer = document.querySelector("#cv-preview-container");
                if (parentContainer && parentContainer.children.length > 1) {
                  // Normalmente el segundo hijo es el contenedor de contenido (después del botón de cierre)
                  contentContainer = parentContainer.children[1];
                  console.log("Contenedor encontrado mediante hijos del contenedor principal");
                }
              }
              
              if (!contentContainer) {
                alert("No se pudo encontrar el contenedor del CV. Intente de nuevo.");
                console.error("No se encontró ningún contenedor válido");
                return;
              }
              
              // Asegurar que los caracteres especiales se muestren correctamente
              var allTextElements = contentContainer.querySelectorAll('*');
              allTextElements.forEach(function(el) {
                if (el.childNodes.length === 1 && el.childNodes[0].nodeType === 3) {
                  // Es un nodo de texto, podemos asegurar la codificación si es necesario
                  // En este caso no hacemos nada ya que los navegadores modernos manejan UTF-8 correctamente
                }
              });
              
              // Guardar dimensiones originales
              var origWidth = contentContainer.style.width;
              var origHeight = contentContainer.style.height;
              
              // Fijar tamaño para mejorar la calidad
              contentContainer.style.width = "800px";
              
              try {
                // Crear un nuevo canvas simple con dimensiones seguras
                var canvas = document.createElement('canvas');
                
                // Dimensiones generosas para el canvas
                canvas.width = 1600; // Doble de 800px para mejor calidad
                canvas.height = 2200; // Aproximadamente proporción A4
                
                var ctx = canvas.getContext('2d');
                ctx.fillStyle = '#FFFFFF';
                ctx.fillRect(0, 0, canvas.width, canvas.height);
                
                console.log("Iniciando renderizado con html2canvas...");
                console.log("Contenedor dimensiones: " + contentContainer.offsetWidth + "x" + contentContainer.offsetHeight);
                
                // Usar html2canvas con opciones simplificadas y valores seguros
                html2canvas(contentContainer, {
                  canvas: canvas,
                  scale: 2,
                  useCORS: true,
                  allowTaint: true,
                  backgroundColor: '#FFFFFF',
                  logging: true,
                  width: contentContainer.offsetWidth || 800,
                  height: contentContainer.offsetHeight || 1100,
                  onclone: function(clonedDoc) {
                    console.log("Documento clonado correctamente");
                    // Asegurar que el contenedor clonado tenga dimensiones correctas
                    var clonedContainer = clonedDoc.querySelector(selectors[0]);
                    if (clonedContainer) {
                      clonedContainer.style.width = "800px";
                      clonedContainer.style.height = "auto";
                    }
                    
                    // Asegurar que la fuente se cargue en el documento clonado
                    var linkElement = document.createElement('link');
                    linkElement.rel = 'stylesheet';
                    linkElement.href = 'https://fonts.googleapis.com/css2?family=Open+Sans:wght@300;400;600;700&family=Poppins:wght@400;500;600;700&display=swap';
                    clonedDoc.head.appendChild(linkElement);
                  }
                }).then(function(canvas) {
                  try {
                    console.log("Canvas generado correctamente: " + canvas.width + "x" + canvas.height);
                    
                    // Crear un PDF simple sin múltiples páginas
                    var pdf = new jspdf.jsPDF({
                      orientation: 'portrait',
                      unit: 'mm',
                      format: 'a4',
                      putOnlyUsedFonts: true
                    });
                    
                    // Dimensiones A4
                    var pageWidth = 210;
                    var pageHeight = 297;
                    
                    // Obtener la URL de la imagen de forma segura
                    var imgData;
                    try {
                      imgData = canvas.toDataURL('image/jpeg', 0.95);
                      console.log("Imagen generada correctamente");
                    } catch (e) {
                      console.error("Error al generar la imagen:", e);
                      alert("Error al generar la imagen. Intente de nuevo. Detalles: " + e.message);
                      return;
                    }
                    
                    // Agregar imagen simple sin cálculos complejos
                    pdf.addImage(
                      imgData, 
                      'JPEG', 
                      0, // X position
                      0, // Y position
                      pageWidth, // Width in mm
                      pageHeight // Height in mm (recortar lo que no quepa)
                    );
                    
                    // Guardar PDF con nombre mejorado
                    pdf.save('curriculum_vitae.pdf');
                    console.log("PDF generado correctamente");
                    
                    // Restaurar dimensiones originales
                    contentContainer.style.width = origWidth;
                    contentContainer.style.height = origHeight;
                  } catch(err) {
                    alert("Error al crear PDF: " + err.message);
                    console.error("Error al crear PDF:", err);
                    
                    // Restaurar dimensiones originales en caso de error
                    contentContainer.style.width = origWidth;
                    contentContainer.style.height = origHeight;
                  }
                }).catch(function(err) {
                  alert("Error al generar imagen: " + err.message);
                  console.error("Error al generar imagen:", err);
                  
                  // Restaurar dimensiones originales en caso de error
                  contentContainer.style.width = origWidth;
                  contentContainer.style.height = origHeight;
                });
              } catch (canvasErr) {
                alert("Error al preparar el canvas: " + canvasErr.message);
                console.error("Error al preparar el canvas:", canvasErr);
                
                // Restaurar dimensiones originales en caso de error
                contentContainer.style.width = origWidth;
                contentContainer.style.height = origHeight;
              }
            } catch(err) {
              alert("Error general: " + err.message);
              console.error("Error general:", err);
            }
          }
          
          // Ejecutar con pequeño retraso para asegurar que todo está cargado
          setTimeout(simpleSavePDF, 500);
        ''';

        // Ejecutar el código JavaScript
        js.context.callMethod('eval', [jsCode]);
      });
    } catch (e) {
      print("Error al descargar como PDF: $e");
      html.window.alert("Error al generar el PDF: $e");
    }
  }

  /// Método para cargar librerías JavaScript necesarias
  static void _loadJsLibraries(Function callback) {
    try {
      print("Iniciando carga de librerías JavaScript...");

      // Verificar si las librerías ya están cargadas
      if (js.context.hasProperty('html2canvas') &&
          js.context.hasProperty('jspdf') &&
          js.context.hasProperty('domtoimage')) {
        print("Todas las librerías ya están cargadas");
        callback();
        return;
      }

      // Contador para controlar cuando todas las librerías estén cargadas
      var loadedLibraries = 0;
      var requiredLibraries = 3; // html2canvas, jspdf, domtoimage

      // Función para verificar si todas las librerías están cargadas
      void checkAllLoaded() {
        loadedLibraries++;
        print("Librería cargada: $loadedLibraries de $requiredLibraries");
        if (loadedLibraries >= requiredLibraries) {
          print("Todas las librerías cargadas correctamente");
          callback();
        }
      }

      // Cargar domtoimage (nueva librería)
      if (!js.context.hasProperty('domtoimage')) {
        print("Cargando dom-to-image...");
        final domtoImageScript =
            html.ScriptElement()
              ..src =
                  'https://cdnjs.cloudflare.com/ajax/libs/dom-to-image/2.6.0/dom-to-image.min.js'
              ..type = 'text/javascript'
              ..id = 'domtoimage-script'; // Añadir ID para checkeo

        domtoImageScript.onLoad.listen((event) {
          print("dom-to-image cargado");
          checkAllLoaded();
        });

        domtoImageScript.onError.listen((event) {
          print("Error al cargar dom-to-image");
          // Continuar de todos modos
          checkAllLoaded();
        });

        html.document.head!.append(domtoImageScript);
      } else {
        print("dom-to-image ya cargado");
        checkAllLoaded();
      }

      // Cargar html2canvas
      if (!js.context.hasProperty('html2canvas')) {
        print("Cargando html2canvas...");
        final html2canvasScript =
            html.ScriptElement()
              ..src =
                  'https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js'
              ..type = 'text/javascript'
              ..id = 'html2canvas-script';

        html2canvasScript.onLoad.listen((event) {
          print("html2canvas cargado");
          checkAllLoaded();
        });

        html2canvasScript.onError.listen((event) {
          print("Error al cargar html2canvas");
          // Continuar de todos modos
          checkAllLoaded();
        });

        html.document.head!.append(html2canvasScript);
      } else {
        print("html2canvas ya cargado");
        checkAllLoaded();
      }

      // Cargar jsPDF
      if (!js.context.hasProperty('jspdf')) {
        print("Cargando jsPDF...");
        final jspdfScript =
            html.ScriptElement()
              ..src =
                  'https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js'
              ..type = 'text/javascript'
              ..id = 'jspdf-script';

        jspdfScript.onLoad.listen((event) {
          print("jsPDF cargado");
          checkAllLoaded();
        });

        jspdfScript.onError.listen((event) {
          print("Error al cargar jsPDF");
          // Continuar de todos modos
          checkAllLoaded();
        });

        html.document.head!.append(jspdfScript);
      } else {
        print("jsPDF ya cargado");
        checkAllLoaded();
      }
    } catch (e) {
      print("Error al cargar librerías: $e");
      callback(); // Intentar continuar de todos modos
    }
  }

  /// Método auxiliar para reemplazar marcadores de forma segura
  static String _safeReplace(
    String template,
    String placeholder,
    String value,
  ) {
    try {
      // Si el placeholder no existe, devolver la plantilla sin cambios
      if (!template.contains(placeholder)) {
        return template;
      }

      // Asegurar que los caracteres especiales se manejan correctamente
      String safeValue = _ensureUtf8Encoding(value);

      return template.replaceAll(placeholder, safeValue);
    } catch (e) {
      print("Error al reemplazar '$placeholder': $e");
      // En caso de error, devolver la plantilla original
      return template;
    }
  }

  /// Método para asegurar que los caracteres especiales se codifican correctamente
  static String _ensureUtf8Encoding(String text) {
    try {
      if (text.isEmpty) {
        return '';
      }

      // Escapar caracteres que puedan romper el HTML
      String result = text
          .replaceAll('&', '&amp;') // Escapar ampersand primero
          .replaceAll('<', '&lt;') // Escapar menor que
          .replaceAll('>', '&gt;') // Escapar mayor que
          .replaceAll('"', '&quot;') // Escapar comillas dobles
          .replaceAll("'", '&#39;'); // Escapar comillas simples

      // Corregir problemas específicos de codificación mal interpretada
      result = result
          .replaceAll('Â°', '°') // grado
          .replaceAll('Ã¡', 'á') // a con tilde
          .replaceAll('Ã©', 'é') // e con tilde
          .replaceAll('Ã­', 'í') // i con tilde
          .replaceAll('Ã³', 'ó') // o con tilde
          .replaceAll('Ãº', 'ú') // u con tilde
          .replaceAll('Ã±', 'ñ') // eñe
          .replaceAll('ÃŒ', 'Í') // I con tilde
          .replaceAll('Ã"', 'Ó') // O con tilde
          .replaceAll('Ãš', 'Ú') // U con tilde
          .replaceAll('Ã¼', 'ü') // u con diéresis
          .replaceAll('Â¿', '¿') // signo de interrogación invertido
          .replaceAll('Â¡', '¡') // signo de exclamación invertido
          .replaceAll('nÂ°', 'n°') // Corrección específica para "número"
          .replaceAll('NÂ°', 'N°'); // Corrección específica para "Número"

      return result;
    } catch (e) {
      print("Error al codificar texto: $e");
      return text;
    }
  }

  /// Método para aplicar los datos del CV a una plantilla HTML
  static String _applyDataToTemplate(Map<String, dynamic> cvData) {
    // Procesar datos básicos de forma segura
    String nombres = _ensureUtf8Encoding(cvData['nombres']?.toString() ?? '');
    String apellidos = _ensureUtf8Encoding(
      cvData['apellidos']?.toString() ?? '',
    );
    String nombreCompleto = '$nombres $apellidos'.trim();

    // Generar iniciales para el círculo del perfil
    String iniciales = '';
    if (nombres.isNotEmpty) iniciales += nombres[0].toUpperCase();
    if (apellidos.isNotEmpty) iniciales += apellidos[0].toUpperCase();
    if (iniciales.isEmpty) iniciales = 'CV';

    // Procesar datos de contacto
    String correo = _ensureUtf8Encoding(cvData['correo']?.toString() ?? '');
    String telefono = _ensureUtf8Encoding(cvData['telefono']?.toString() ?? '');
    String direccion = _ensureUtf8Encoding(
      cvData['direccion']?.toString() ?? '',
    );
    String profesion = _ensureUtf8Encoding(
      cvData['profesion']?.toString() ?? 'Profesional',
    );

    // Datos personales
    String fechaNacimiento = _ensureUtf8Encoding(
      cvData['fecha_nacimiento']?.toString() ?? '',
    );
    String nacionalidad = _ensureUtf8Encoding(
      cvData['nacionalidad']?.toString() ?? '',
    );
    String estadoCivil = _ensureUtf8Encoding(
      cvData['estado_civil']?.toString() ?? '',
    );

    // Contenido principal
    String perfilProfesional = _ensureUtf8Encoding(
      cvData['perfil_profesional']?.toString() ?? '',
    );
    String experienciaLaboral = _ensureUtf8Encoding(
      cvData['experiencia_laboral']?.toString() ?? '',
    );
    String educacion = _ensureUtf8Encoding(
      cvData['educacion']?.toString() ?? '',
    );
    String habilidades = _ensureUtf8Encoding(
      cvData['habilidades']?.toString() ?? '',
    );
    String idiomas = _ensureUtf8Encoding(cvData['idiomas']?.toString() ?? '');
    String certificaciones = _ensureUtf8Encoding(
      cvData['certificaciones']?.toString() ?? '',
    );

    // Crear el HTML directamente sin templates complejos
    return '''
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Currículum Vitae - $nombreCompleto</title>
        <style>
            @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
            
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                font-family: 'Inter', 'Arial', sans-serif;
                line-height: 1.5;
                color: #2d3748;
                background-color: #ffffff;
                font-size: 14px;
            }
            
            .container {
                max-width: 800px;
                margin: 0 auto;
                background-color: white;
                position: relative;
                overflow: hidden;
                box-shadow: 0 0 20px rgba(0,0,0,0.1);
            }
            
            /* Header con diseño moderno */
            header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 40px 30px;
                position: relative;
            }
            
            .header-content {
                display: flex;
                align-items: center;
                gap: 25px;
            }
            
            .profile-circle {
                width: 120px;
                height: 120px;
                border-radius: 50%;
                background: rgba(255,255,255,0.2);
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 48px;
                font-weight: 700;
                color: white;
                border: 3px solid rgba(255,255,255,0.3);
                flex-shrink: 0;
            }
            
            .header-info {
                flex: 1;
            }
            
            .name {
                font-size: 36px;
                font-weight: 700;
                margin-bottom: 8px;
                letter-spacing: -0.5px;
            }
            
            .profession {
                font-size: 18px;
                font-weight: 400;
                opacity: 0.9;
                margin-bottom: 20px;
            }
            
            .contact-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 12px;
            }
            
            .contact-item {
                display: flex;
                align-items: center;
                gap: 8px;
                font-size: 14px;
                opacity: 0.95;
            }
            
            .contact-icon {
                width: 16px;
                height: 16px;
                opacity: 0.8;
            }
            
            /* Layout principal */
            .main-content {
                display: flex;
                min-height: 600px;
            }
            
            .left-column {
                flex: 2;
                padding: 40px 30px;
                background-color: #ffffff;
            }
            
            .right-column {
                flex: 1;
                padding: 40px 25px;
                background-color: #f8fafc;
                border-left: 1px solid #e2e8f0;
            }
            
            /* Secciones */
            .section {
                margin-bottom: 35px;
            }
            
            .section-title {
                font-size: 20px;
                font-weight: 600;
                color: #1a202c;
                margin-bottom: 20px;
                padding-bottom: 8px;
                border-bottom: 2px solid #667eea;
                position: relative;
            }
            
            .section-title::after {
                content: '';
                position: absolute;
                bottom: -2px;
                left: 0;
                width: 40px;
                height: 2px;
                background: #764ba2;
            }
            
            /* Experiencia y Educación */
            .timeline-item {
                margin-bottom: 25px;
                padding-left: 20px;
                border-left: 2px solid #e2e8f0;
                position: relative;
            }
            
            .timeline-item::before {
                content: '';
                position: absolute;
                left: -6px;
                top: 6px;
                width: 10px;
                height: 10px;
                border-radius: 50%;
                background: linear-gradient(135deg, #667eea, #764ba2);
                border: 2px solid white;
                box-shadow: 0 0 0 2px #e2e8f0;
            }
            
            .item-title {
                font-size: 16px;
                font-weight: 600;
                color: #1a202c;
                margin-bottom: 8px;
            }
            
            .item-description {
                font-size: 13px;
                color: #4a5568;
                line-height: 1.6;
            }
            
            /* Columna derecha */
            .info-card {
                background: white;
                padding: 20px;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.05);
                margin-bottom: 25px;
            }
            
            .info-card-title {
                font-size: 16px;
                font-weight: 600;
                color: #1a202c;
                margin-bottom: 15px;
                padding-bottom: 8px;
                border-bottom: 1px solid #e2e8f0;
            }
            
            .info-item {
                margin-bottom: 12px;
                font-size: 13px;
            }
            
            .info-label {
                font-weight: 500;
                color: #667eea;
                display: block;
                margin-bottom: 2px;
                text-transform: uppercase;
                font-size: 11px;
                letter-spacing: 0.5px;
            }
            
            .info-value {
                color: #2d3748;
            }
            
            /* Skills y tags */
            .skills-grid {
                display: flex;
                flex-wrap: wrap;
                gap: 8px;
                margin-top: 10px;
            }
            
            .skill-tag {
                background: linear-gradient(135deg, #667eea, #764ba2);
                color: white;
                padding: 6px 12px;
                border-radius: 20px;
                font-size: 12px;
                font-weight: 500;
                white-space: nowrap;
            }
            
            .languages-list {
                list-style: none;
                padding: 0;
            }
            
            .language-item {
                padding: 8px 0;
                border-bottom: 1px solid #f1f5f9;
                font-size: 13px;
                color: #4a5568;
            }
            
            .language-item:last-child {
                border-bottom: none;
            }
            
            /* Responsive */
            @media print {
                body { -webkit-print-color-adjust: exact; }
                .container { box-shadow: none; }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <header>
                <div class="header-content">
                    <div class="profile-circle">
                        $iniciales
                    </div>
                    <div class="header-info">
                        <h1 class="name">$nombreCompleto</h1>
                        ${profesion.isNotEmpty ? '<div class="profession">$profesion</div>' : ''}
                        <div class="contact-grid">
                            ${correo.isNotEmpty ? '<div class="contact-item"><span class="contact-icon">✉</span>$correo</div>' : ''}
                            ${telefono.isNotEmpty ? '<div class="contact-item"><span class="contact-icon">📞</span>$telefono</div>' : ''}
                            ${direccion.isNotEmpty ? '<div class="contact-item"><span class="contact-icon">📍</span>$direccion</div>' : ''}
                        </div>
                    </div>
                </div>
            </header>
            
            <div class="main-content">
                <div class="left-column">
                    ${perfilProfesional.isNotEmpty ? '''
                    <div class="section">
                        <h2 class="section-title">Perfil Profesional</h2>
                        <p class="item-description">$perfilProfesional</p>
                    </div>
                    ''' : ''}
                    
                    ${experienciaLaboral.isNotEmpty ? '''
                    <div class="section">
                        <h2 class="section-title">Work Experience</h2>
                        ${_buildExperienceItems(experienciaLaboral)}
                    </div>
                    ''' : ''}
                    
                    ${educacion.isNotEmpty ? '''
                    <div class="section">
                        <h2 class="section-title">Education</h2>
                        ${_buildEducationItems(educacion)}
                    </div>
                    ''' : ''}
                </div>
                
                <div class="right-column">
                    <div class="info-card">
                        <h3 class="info-card-title">Personal Information</h3>
                        ${fechaNacimiento.isNotEmpty ? '<div class="info-item"><span class="info-label">Date of Birth</span><span class="info-value">$fechaNacimiento</span></div>' : ''}
                        ${nacionalidad.isNotEmpty ? '<div class="info-item"><span class="info-label">Nationality</span><span class="info-value">$nacionalidad</span></div>' : ''}
                        ${estadoCivil.isNotEmpty ? '<div class="info-item"><span class="info-label">Marital Status</span><span class="info-value">$estadoCivil</span></div>' : ''}
                    </div>
                    
                    ${habilidades.isNotEmpty ? '''
                    <div class="info-card">
                        <h3 class="info-card-title">Skills</h3>
                        <div class="skills-grid">
                            ${_buildSkillTags(habilidades)}
                        </div>
                    </div>
                    ''' : ''}
                    
                    ${idiomas.isNotEmpty ? '''
                    <div class="info-card">
                        <h3 class="info-card-title">Languages</h3>
                        <ul class="languages-list">
                            ${_buildLanguageItems(idiomas)}
                        </ul>
                    </div>
                    ''' : ''}
                    
                    ${certificaciones.isNotEmpty ? '''
                    <div class="info-card">
                        <h3 class="info-card-title">Certifications</h3>
                        ${_buildCertificationItems(certificaciones)}
                    </div>
                    ''' : ''}
                </div>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // Funciones auxiliares para construir elementos HTML
  static String _buildExperienceItems(String experiencia) {
    if (experiencia.isEmpty) return '';

    final lineas =
        experiencia
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
    String html = '';

    for (String linea in lineas) {
      String lineaLimpia = _ensureUtf8Encoding(linea.trim());
      html += '''
        <div class="timeline-item">
          <div class="item-title">$lineaLimpia</div>
        </div>
      ''';
    }

    return html;
  }

  static String _buildEducationItems(String educacion) {
    if (educacion.isEmpty) return '';

    final lineas =
        educacion.split('\n').where((line) => line.trim().isNotEmpty).toList();
    String html = '';

    for (String linea in lineas) {
      String lineaLimpia = _ensureUtf8Encoding(linea.trim());
      html += '''
        <div class="timeline-item">
          <div class="item-title">$lineaLimpia</div>
        </div>
      ''';
    }

    return html;
  }

  static String _buildSkillTags(String habilidades) {
    if (habilidades.isEmpty) return '';

    final skills =
        habilidades
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
    String html = '';

    for (String skill in skills) {
      String skillLimpio = _ensureUtf8Encoding(skill);
      html += '<span class="skill-tag">$skillLimpio</span>';
    }

    return html;
  }

  static String _buildLanguageItems(String idiomas) {
    if (idiomas.isEmpty) return '';

    final langs =
        idiomas
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
    String html = '';

    for (String idioma in langs) {
      String idiomaLimpio = _ensureUtf8Encoding(idioma);
      html += '<li class="language-item">$idiomaLimpio</li>';
    }

    return html;
  }

  static String _buildCertificationItems(String certificaciones) {
    if (certificaciones.isEmpty) return '';

    final lineas =
        certificaciones
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
    String html = '';

    for (String linea in lineas) {
      String lineaLimpia = _ensureUtf8Encoding(linea.trim());
      html += '''
        <div class="info-item">
          <span class="info-value">$lineaLimpia</span>
        </div>
      ''';
    }

    return html;
  }
}

/// Widget para mostrar un botón que genera un PDF del CV
class GeneratePDFButton extends StatelessWidget {
  final Map<String, dynamic> cvData;
  final VoidCallback? onGenerating;
  final Function(String pdfUrl)? onGenerated;
  final Function(String error)? onError;

  const GeneratePDFButton({
    super.key,
    required this.cvData,
    this.onGenerating,
    this.onGenerated,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          // Verificar si hay datos suficientes para generar el PDF
          if (cvData.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No information available to generate PDF. Please save data first.',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          print("Generando PDF con ${cvData.length} campos de datos");
          print("Datos: ${cvData.keys.join(', ')}");

          // Notificar que se está generando el PDF
          onGenerating?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Generating PDF...',
                style: GoogleFonts.poppins(color: Color(0xFF090467)),
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );

          // Preparar datos asegurando que todos los valores sean seguros
          Map<String, dynamic> safeData = {};

          // Agregar con protección contra nulos
          void addSafely(String key, dynamic value) {
            if (value != null) {
              final String strValue = value.toString();
              if (strValue.isNotEmpty) {
                safeData[key] = strValue;
                print(
                  "Campo añadido: $key = ${strValue.length > 50 ? '${strValue.substring(0, 50)}...' : strValue}",
                );
              }
            }
          }

          // Agregar todos los campos esenciales
          cvData.forEach((key, value) {
            addSafely(key, value);
          });

          // Asegurar campos obligatorios para evitar errores
          if (!safeData.containsKey('nombres')) {
            safeData['nombres'] = 'Nombre';
            print("Campo nombres añadido por defecto");
          }
          if (!safeData.containsKey('apellidos')) {
            safeData['apellidos'] = 'Apellido';
            print("Campo apellidos añadido por defecto");
          }

          print("Datos procesados, iniciando generación PDF...");

          try {
            // Primero mostramos la vista previa
            final previewResult = await MonkeyPDFIntegration.generatePDFFromCV(
              safeData,
            );
            print("Vista previa generada: $previewResult");

            // Luego esperamos un momento y activamos la descarga automáticamente
            Future.delayed(Duration(milliseconds: 1500), () {
              try {
                // Buscar el contenedor del CV para generar el PDF
                final contentContainer = html.document.querySelector(
                  "#cv-preview-container",
                );
                if (contentContainer != null) {
                  print("Contenedor encontrado, procediendo a generar PDF");
                  // Descargar como PDF
                  MonkeyPDFIntegration._downloadAsPDF(contentContainer);

                  // Notificar que se ha generado el PDF
                  onGenerated?.call(previewResult);
                } else {
                  print(
                    "ERROR: No se encontró el contenedor #cv-preview-container",
                  );
                  throw Exception('No se encontró el contenedor del CV');
                }
              } catch (innerError) {
                print("Error in automatic download: $innerError");
                print("Stack trace: ${StackTrace.current}");
                onError?.call(innerError.toString());

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error in automatic download: $innerError',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });
          } catch (previewError) {
            print("Error generating the preview: $previewError");
            print("Stack trace: ${StackTrace.current}");
            onError?.call(previewError.toString());

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error generating the preview: $previewError',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          print("General error generating the PDF: $e");
          print("Stack trace: ${StackTrace.current}");
          // Notify the error
          onError?.call(e.toString());

          if (!context.mounted) return;

          // Show an error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error generating the PDF: $e',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff9ee4b8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        shadowColor: const Color(0x8000FF7F),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf, size: 20),
          SizedBox(width: 10),
          Text(
            'Generate PDF',
            style: GoogleFonts.poppins(
              color: Color(0xFF090467),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
