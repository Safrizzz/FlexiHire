import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing skills with Firebase
/// Skills are stored in Firebase for:
/// 1. Consistency across the platform
/// 2. Smart job matching
/// 3. Analytics and trending skills
class SkillsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cache for skills to reduce Firebase reads
  static List<String>? _cachedSkills;
  static DateTime? _lastFetch;
  static const _cacheDuration = Duration(hours: 1);

  /// Get all skills from Firebase (with caching)
  Future<List<String>> getAllSkills() async {
    // Return cached if valid
    if (_cachedSkills != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return _cachedSkills!;
    }

    try {
      final doc = await _db.collection('app_config').doc('skills').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final skills = List<String>.from(data['list'] ?? []);
        _cachedSkills = skills;
        _lastFetch = DateTime.now();
        return skills;
      }

      // If no skills in Firebase, seed with default skills
      await seedDefaultSkills();
      return _cachedSkills ?? _defaultSkills;
    } catch (e) {
      // Return default skills on error
      return _defaultSkills;
    }
  }

  /// Search skills by query (for autocomplete)
  Future<List<String>> searchSkills(String query) async {
    if (query.trim().isEmpty) return [];

    final allSkills = await getAllSkills();
    final queryLower = query.toLowerCase().trim();

    // Score-based matching for better results
    final scored = <MapEntry<String, int>>[];

    for (final skill in allSkills) {
      final skillLower = skill.toLowerCase();
      int score = 0;

      if (skillLower == queryLower) {
        score = 100; // Exact match
      } else if (skillLower.startsWith(queryLower)) {
        score = 80; // Starts with query
      } else if (skillLower.contains(queryLower)) {
        score = 60; // Contains query
      } else {
        // Check individual words
        final words = skillLower.split(RegExp(r'[\s\-_\(\)]'));
        for (final word in words) {
          if (word.startsWith(queryLower)) {
            score = 50;
            break;
          }
        }
      }

      if (score > 0) {
        scored.add(MapEntry(skill, score));
      }
    }

    // Sort by score (highest first), then alphabetically
    scored.sort((a, b) {
      final scoreCompare = b.value.compareTo(a.value);
      if (scoreCompare != 0) return scoreCompare;
      return a.key.compareTo(b.key);
    });

    return scored.map((e) => e.key).take(15).toList();
  }

  /// Add a custom skill to Firebase (for skills not in the list)
  Future<void> addCustomSkill(String skill) async {
    if (skill.trim().isEmpty) return;

    final normalizedSkill = _normalizeSkill(skill);
    final allSkills = await getAllSkills();

    // Check if already exists (case-insensitive)
    if (allSkills.any(
      (s) => s.toLowerCase() == normalizedSkill.toLowerCase(),
    )) {
      return;
    }

    try {
      await _db.collection('app_config').doc('skills').update({
        'list': FieldValue.arrayUnion([normalizedSkill]),
        'customSkills': FieldValue.arrayUnion([normalizedSkill]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update cache
      _cachedSkills?.add(normalizedSkill);
    } catch (e) {
      // Ignore errors for custom skill addition
    }
  }

  /// Normalize skill name (proper capitalization)
  String _normalizeSkill(String skill) {
    return skill
        .trim()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          // Keep acronyms uppercase (CSS, HTML, SQL, etc.)
          if (word.toUpperCase() == word && word.length <= 5) {
            return word;
          }
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Seed default skills to Firebase
  Future<void> seedDefaultSkills() async {
    try {
      await _db.collection('app_config').doc('skills').set({
        'list': _defaultSkills,
        'customSkills': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _cachedSkills = List.from(_defaultSkills);
      _lastFetch = DateTime.now();
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear cache (useful when skills are updated)
  void clearCache() {
    _cachedSkills = null;
    _lastFetch = null;
  }

  /// Default skills list - comprehensive list for Malaysian job market
  static const List<String> _defaultSkills = [
    // Programming Languages
    'Python',
    'Java',
    'JavaScript',
    'TypeScript',
    'Dart',
    'C++',
    'C#',
    'PHP',
    'Ruby',
    'Swift',
    'Kotlin',
    'Go',
    'Rust',
    'R',
    'MATLAB',
    'Scala',

    // Web Development
    'HTML',
    'HTML5',
    'CSS',
    'CSS3',
    'Cascading Style Sheets (CSS)',
    'CSS Flexbox',
    'CSS Grid',
    'Sass',
    'LESS',
    'Bootstrap',
    'Tailwind CSS',
    'Materialize CSS',
    'Bulma',

    // Frontend Frameworks
    'React',
    'React.js',
    'Angular',
    'Vue.js',
    'Next.js',
    'Nuxt.js',
    'Svelte',
    'jQuery',

    // Mobile Development
    'Flutter',
    'React Native',
    'iOS Development',
    'Android Development',
    'Xamarin',
    'Ionic',
    'SwiftUI',

    // Backend Development
    'Node.js',
    'Express.js',
    'Django',
    'Flask',
    'Spring Boot',
    'Laravel',
    'Ruby on Rails',
    'ASP.NET',
    'FastAPI',

    // Databases
    'SQL',
    'MySQL',
    'PostgreSQL',
    'MongoDB',
    'Firebase',
    'Redis',
    'Oracle',
    'SQLite',
    'Microsoft SQL Server',
    'DynamoDB',

    // Cloud & DevOps
    'AWS',
    'Amazon Web Services',
    'Google Cloud Platform',
    'Microsoft Azure',
    'Docker',
    'Kubernetes',
    'CI/CD',
    'Jenkins',
    'GitHub Actions',
    'Terraform',
    'Linux',
    'Unix',

    // Data Science & AI
    'Machine Learning',
    'Deep Learning',
    'Artificial Intelligence',
    'Data Analysis',
    'Data Science',
    'Data Visualization',
    'TensorFlow',
    'PyTorch',
    'Pandas',
    'NumPy',
    'Scikit-learn',
    'Natural Language Processing',
    'Computer Vision',
    'Big Data',
    'Hadoop',
    'Spark',

    // Design & Creative
    'UI Design',
    'UX Design',
    'UI/UX Design',
    'Graphic Design',
    'Adobe Photoshop',
    'Adobe Illustrator',
    'Adobe XD',
    'Figma',
    'Sketch',
    'Canva',
    'InDesign',
    'After Effects',
    'Premiere Pro',
    'Video Editing',
    'Photography',
    '3D Modeling',
    'Blender',
    'AutoCAD',

    // Business & Management
    'Project Management',
    'Agile',
    'Scrum',
    'Product Management',
    'Business Analysis',
    'Business Development',
    'Strategic Planning',
    'Operations Management',
    'Supply Chain Management',
    'Inventory Management',
    'Quality Assurance',
    'Quality Control',
    'Risk Management',
    'Change Management',
    'Lean Management',
    'Six Sigma',

    // Marketing & Sales
    'Digital Marketing',
    'Social Media Marketing',
    'Content Marketing',
    'SEO',
    'SEM',
    'Google Ads',
    'Facebook Ads',
    'Email Marketing',
    'Marketing Strategy',
    'Brand Management',
    'Market Research',
    'Sales',
    'B2B Sales',
    'B2C Sales',
    'Lead Generation',
    'CRM',
    'Salesforce',
    'HubSpot',

    // Customer Service
    'Customer Service',
    'Customer Support',
    'Customer Experience',
    'Customer Satisfaction',
    'Customer Retention',
    'Customer Relationship Management (CRM)',
    'Customer Insight',
    'Call Center',
    'Help Desk',
    'Technical Support',

    // Finance & Accounting
    'Accounting',
    'Financial Analysis',
    'Financial Reporting',
    'Budgeting',
    'Forecasting',
    'Bookkeeping',
    'Auditing',
    'Tax Preparation',
    'Financial Planning',
    'Investment Analysis',
    'Risk Assessment',
    'SAP',
    'QuickBooks',
    'Excel',
    'Financial Modeling',

    // Human Resources
    'Recruitment',
    'Talent Acquisition',
    'Employee Relations',
    'Performance Management',
    'Training & Development',
    'HR Management',
    'Payroll',
    'Compensation & Benefits',
    'HRIS',
    'Onboarding',

    // Communication & Soft Skills
    'Communication',
    'Written Communication',
    'Verbal Communication',
    'Presentation Skills',
    'Public Speaking',
    'Negotiation',
    'Interpersonal Skills',
    'Teamwork',
    'Collaboration',
    'Leadership',
    'Problem Solving',
    'Critical Thinking',
    'Analytical Skills',
    'Time Management',
    'Organizational Skills',
    'Attention to Detail',
    'Creativity',
    'Adaptability',
    'Work Ethic',
    'Multitasking',

    // Languages
    'English',
    'Malay',
    'Mandarin',
    'Tamil',
    'Cantonese',
    'Japanese',
    'Korean',
    'Arabic',
    'French',
    'German',
    'Spanish',
    'Translation',
    'Interpretation',

    // Administrative
    'Microsoft Office',
    'Microsoft Word',
    'Microsoft Excel',
    'Microsoft PowerPoint',
    'Google Workspace',
    'Data Entry',
    'Typing',
    'Filing',
    'Scheduling',
    'Calendar Management',
    'Travel Arrangements',
    'Meeting Coordination',
    'Administrative Support',
    'Office Management',
    'Reception',

    // Food & Beverage
    'Food Service',
    'Food Preparation',
    'Cooking',
    'Baking',
    'Barista',
    'Bartending',
    'Food Safety',
    'Kitchen Management',
    'Menu Planning',
    'Catering',

    // Retail & Hospitality
    'Retail Sales',
    'Cashier',
    'Inventory Management',
    'Visual Merchandising',
    'Customer Engagement',
    'Hotel Management',
    'Front Desk',
    'Event Planning',
    'Event Management',

    // Healthcare
    'Patient Care',
    'Medical Terminology',
    'First Aid',
    'CPR',
    'Nursing',
    'Pharmacy',
    'Medical Records',
    'Healthcare Administration',

    // Education & Training
    'Teaching',
    'Tutoring',
    'Curriculum Development',
    'Lesson Planning',
    'Classroom Management',
    'E-Learning',
    'Educational Technology',
    'Student Assessment',
    'Mentoring',
    'Coaching',

    // Engineering
    'Mechanical Engineering',
    'Electrical Engineering',
    'Civil Engineering',
    'Chemical Engineering',
    'Software Engineering',
    'Systems Engineering',
    'Industrial Engineering',
    'Manufacturing',
    'CAD',
    'SolidWorks',

    // Other Technical Skills
    'API Development',
    'REST API',
    'GraphQL',
    'Microservices',
    'Version Control',
    'Git',
    'GitHub',
    'GitLab',
    'Bitbucket',
    'Testing',
    'Unit Testing',
    'Integration Testing',
    'Automation Testing',
    'Selenium',
    'Cybersecurity',
    'Network Security',
    'Penetration Testing',
    'Blockchain',
    'IoT',
    'Embedded Systems',

    // Strategy
    'Strategy',
    'Business Strategy',
    'Go-to-Market Strategy',
    'Competitive Analysis',
    'SWOT Analysis',
  ];
}
