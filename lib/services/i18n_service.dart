import 'package:flutter/foundation.dart';

class I18nService extends ChangeNotifier {
  static final I18nService instance = I18nService._internal();
  I18nService._internal();

  String _currentLanguage = 'en'; // 'en' | 'hi' | 'es' | 'ta'

  String get currentLanguage => _currentLanguage;

  void setLanguage(String lang) {
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      notifyListeners();
    }
  }

  static const Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'app_name': 'Specz.co',
      'tagline': 'Digital Eye-Care Companion',
      'disclaimer': 'Specz.co helps organize personal eye-care records and reminders. It does not provide a medical diagnosis and does not replace an eye-care professional.',
      'ai_disclaimer': 'Double-check the eye numbers as AI can make mistakes.',
      'eye_health_score': 'Eye Health Score',
      'score_why': 'Score Reasoning',
      'doctor_questions': 'Suggested Questions for Doctor Visit',
      'prescriptions': 'Prescriptions',
      'add_prescription': 'Add Prescription',
      'scan_prescription': 'Scan with AI OCR',
      'medicines': 'Medicines & Drops',
      'add_medicine': 'Add Medicine',
      'pdf_summary': 'Download PDF Report',
      'upgrade_plus': 'Upgrade to Specz Plus',
      'profiles': 'Profiles',
      'active_profiles': 'Active Profiles',
      'delete_profile': 'Delete Profile Permanently',
      'archive_profile': 'Archive Profile',
      'right_eye': 'Right Eye (OD)',
      'left_eye': 'Left Eye (OS)',
      'sph': 'SPH (Sphere)',
      'cyl': 'CYL (Cylinder)',
      'axis': 'Axis',
      'add': 'Add Power',
      'pd': 'Pupillary Distance (PD)',
      'notes': 'Notes & Advice',
      'doctor_name': 'Doctor Name',
      'clinic_name': 'Clinic / Hospital',
      'academic_chart': 'Refraction Trend (Academic B&W Grid)',
    },
    'hi': {
      'app_name': 'Specz.co',
      'tagline': 'डिजिटल आई-केयर साथी',
      'disclaimer': 'Specz.co व्यक्तिगत नेत्र-देखभाल रिकॉर्ड और रिमाइंडर्स को व्यवस्थित करने में मदद करता है। यह चिकित्सा निदान प्रदान नहीं करता है।',
      'ai_disclaimer': 'चश्मे के नंबर दोबारा जांचें क्योंकि AI गलती कर सकता है।',
      'eye_health_score': 'आई हेल्थ स्कोर',
      'score_why': 'स्कोर का विवरण',
      'doctor_questions': 'डॉक्टर से पूछने योग्य प्रश्न',
      'prescriptions': 'प्रिस्क्रिप्शन',
      'add_prescription': 'प्रिस्क्रिप्शन जोड़ें',
      'scan_prescription': 'AI OCR से स्कैन करें',
      'medicines': 'दवाएं और आई ड्रॉप्स',
      'add_medicine': 'दवा जोड़ें',
      'pdf_summary': 'PDF रिपोर्ट डाउनलोड करें',
      'upgrade_plus': 'Specz Plus में अपग्रेड करें',
      'profiles': 'प्रोफाइल',
      'active_profiles': 'सक्रिय प्रोफाइल',
      'delete_profile': 'प्रोफाइल स्थायी रूप से हटाएं',
      'archive_profile': 'प्रोफाइल आर्काइव करें',
      'right_eye': 'दाहिनी आंख (OD)',
      'left_eye': 'बाईं आंख (OS)',
      'sph': 'SPH (स्फेयर)',
      'cyl': 'CYL (सिलेंडर)',
      'axis': 'एक्सिस',
      'add': 'एड पावर',
      'pd': 'प्यूपिलरी डिस्टेंस (PD)',
      'notes': 'टिप्पणियाँ एवं सलाह',
      'doctor_name': 'डॉक्टर का नाम',
      'clinic_name': 'क्लिनिक / अस्पताल',
      'academic_chart': 'रिफ्रैक्शन ट्रेंड (अकादमिक B&W ग्रिड)',
    },
    'es': {
      'app_name': 'Specz.co',
      'tagline': 'Compañero Digital de Salud Visual',
      'disclaimer': 'Specz.co ayuda a organizar registros de salud visual. No proporciona diagnósticos médicos ni reemplaza a un profesional.',
      'ai_disclaimer': 'Verifique los números de prescripción, la IA puede cometer errores.',
      'eye_health_score': 'Puntuación de Salud Visual',
      'score_why': 'Explicación del Puntaje',
      'doctor_questions': 'Preguntas Sugeridas para el Doctor',
      'prescriptions': 'Prescripciones',
      'add_prescription': 'Agregar Prescripción',
      'scan_prescription': 'Escanear con IA OCR',
      'medicines': 'Medicamentos y Gotas',
      'add_medicine': 'Agregar Medicamento',
      'pdf_summary': 'Descargar Reporte PDF',
      'upgrade_plus': 'Actualizar a Specz Plus',
      'profiles': 'Perfiles',
      'active_profiles': 'Perfiles Activos',
      'delete_profile': 'Eliminar Perfil Permanentemente',
      'archive_profile': 'Archivar Perfil',
      'right_eye': 'Ojo Derecho (OD)',
      'left_eye': 'Ojo Izquierdo (OS)',
      'sph': 'SPH (Esfera)',
      'cyl': 'CYL (Cilindro)',
      'axis': 'Eje',
      'add': 'Adición',
      'pd': 'Distancia Pupilar (PD)',
      'notes': 'Notas y Recomendaciones',
      'doctor_name': 'Nombre del Doctor',
      'clinic_name': 'Clínica / Hospital',
      'academic_chart': 'Tendencia de Refracción (Grilla B&N Académica)',
    },
    'ta': {
      'app_name': 'Specz.co',
      'tagline': 'டிஜிட்டல் கண் பராமரிப்பு துணை',
      'disclaimer': 'Specz.co தனிப்பட்ட கண் பராமரிப்பு பதிவுகளை அமைக்க உதவுகிறது. இது மருத்துவ பரிசோதனை அல்ல.',
      'ai_disclaimer': 'கண் எண்களை இருமுறை சரிபார்க்கவும், AI தவறுகளைச் செய்யக்கூடும்.',
      'eye_health_score': 'கண் ஆரோக்கிய மதிப்பெண்',
      'score_why': 'மதிப்பெண் காரணம்',
      'doctor_questions': 'மருத்துவரிடம் கேட்க வேண்டிய கேள்விகள்',
      'prescriptions': 'மருந்துச் சீட்டு',
      'add_prescription': 'மருந்துச் சீட்டு சேர்',
      'scan_prescription': 'AI OCR உடன் ஸ்கேன் செய்',
      'medicines': 'மருந்துகள் & கண் சொட்டு மருந்துகள்',
      'add_medicine': 'மருந்து சேர்',
      'pdf_summary': 'PDF அறிக்கை பதிவிறக்கு',
      'upgrade_plus': 'Specz Plus-க்கு மேம்படுத்து',
      'profiles': 'சுயவிவரங்கள்',
      'active_profiles': 'செயலில் உள்ள சுயவிவரங்கள்',
      'delete_profile': 'சுயவிவரத்தை நிரந்தரமாக நீக்கு',
      'archive_profile': 'காப்பகப்படுத்து',
      'right_eye': 'வலது கண் (OD)',
      'left_eye': 'இடது கண் (OS)',
      'sph': 'SPH',
      'cyl': 'CYL',
      'axis': 'Axis',
      'add': 'Add Power',
      'pd': 'PD',
      'notes': 'குறிப்புகள்',
      'doctor_name': 'மருத்துவர் பெயர்',
      'clinic_name': 'மருத்துவமனை',
      'academic_chart': 'ஒளிவிலகல் வரைபடம் (கல்வி B&W கட்டம்)',
    }
  };

  String translate(String key) {
    return _localizedStrings[_currentLanguage]?[key] ??
        _localizedStrings['en']?[key] ??
        key;
  }
}
