import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // REQUIRED for data persistence

void main() {
  // Ensures SharedPreferences is initialized before the app runs
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(const BMICalculatorApp());
}

// 1. Main App Widget (Stateless)
class BMICalculatorApp extends StatelessWidget {
  const BMICalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
      ),
      home: const BMICalculatorScreen(),
    );
  }
}

// Enum to manage unit state clearly
enum UnitSystem { metric, imperial }

// 2. Main Screen Widget (Stateful)
class BMICalculatorScreen extends StatefulWidget {
  const BMICalculatorScreen({super.key});

  @override
  State<BMICalculatorScreen> createState() => _BMICalculatorScreenState();
}

class _BMICalculatorScreenState extends State<BMICalculatorScreen> {
  // Controllers for text input fields
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  // State variables
  UnitSystem _currentUnit = UnitSystem.metric;
  double? _bmiResult;
  String _category = '';
  Color _categoryColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _loadSavedUnit(); // Load the user's last selected unit when the screen starts
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // --- Persistence Methods ---

  // Load unit system from local storage
  void _loadSavedUnit() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to 'metric' if nothing is saved
    final savedUnit = prefs.getString('bmiUnitSystem') ?? 'metric';

    setState(() {
      _currentUnit = savedUnit == 'imperial' ? UnitSystem.imperial : UnitSystem.metric;
    });
  }

  // Save the selected unit system to local storage
  void _saveUnitSystem(UnitSystem unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bmiUnitSystem', unit == UnitSystem.metric ? 'metric' : 'imperial');
  }

  // --- UI/Logic Methods ---

  void _setUnitSystem(UnitSystem unit) {
    setState(() {
      _currentUnit = unit;
      _weightController.clear();
      _heightController.clear();
      _bmiResult = null;
      _category = '';
    });
    _saveUnitSystem(unit); // Save the unit change immediately
  }

  void _calculateBMI() {
    final weight = double.tryParse(_weightController.text);
    final heightInput = double.tryParse(_heightController.text);

    if (weight == null || heightInput == null || weight <= 0 || heightInput <= 0) {
      _showSnackbar('Please enter valid positive values.', Colors.red);
      return;
    }

    double bmi = 0;

    if (_currentUnit == UnitSystem.metric) {
      final heightM = heightInput / 100; // cm to m
      bmi = weight / (heightM * heightM);
    } else {
      // Imperial: [Weight (lbs) / (Height (in))^2] * 703
      bmi = (weight / (heightInput * heightInput)) * 703;
    }

    String category;
    Color color;
    String message;

    if (bmi < 18.5) {
      category = 'Underweight';
      message = 'Please consult a healthcare provider.';
      color = Colors.yellow.shade800;
    } else if (bmi >= 18.5 && bmi < 24.9) {
      category = 'Healthy Weight';
      message = 'Keep up the good work!';
      color = Colors.green.shade600;
    } else if (bmi >= 25 && bmi < 29.9) {
      category = 'Overweight';
      message = 'Lifestyle adjustments may be beneficial.';
      color = Colors.orange.shade600;
    } else {
      category = 'Obesity';
      message = 'It is highly recommended to speak with a doctor.';
      color = Colors.red.shade600;
    }

    // Save the result for display
    setState(() {
      _bmiResult = double.parse(bmi.toStringAsFixed(2));
      _category = category;
      _categoryColor = color;
    });

    _showSnackbar('Category: $category. $message', color);
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Helper widget to build the unit toggle buttons
  Widget _buildUnitToggle() {
    return ToggleButtons(
      isSelected: [
        _currentUnit == UnitSystem.metric,
        _currentUnit == UnitSystem.imperial,
      ],
      onPressed: (index) {
        _setUnitSystem(index == 0 ? UnitSystem.metric : UnitSystem.imperial);
      },
      borderRadius: BorderRadius.circular(10.0),
      selectedColor: Colors.white,
      fillColor: Colors.indigo,
      color: Colors.indigo,
      borderColor: Colors.indigo.shade200,
      selectedBorderColor: Colors.indigo,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Metric (kg / cm)'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Imperial (lbs / in)'),
        ),
      ],
    );
  }

  // Helper widget to build the text input fields
  Widget _buildInputFields() {
    // Labels change based on the selected unit system
    final weightLabel = _currentUnit == UnitSystem.metric ? 'Weight (kg)' : 'Weight (lbs)';
    final heightLabel = _currentUnit == UnitSystem.metric ? 'Height (cm)' : 'Height (in)';
    final weightHint = _currentUnit == UnitSystem.metric ? 'e.g., 75.0' : 'e.g., 165.0';
    final heightHint = _currentUnit == UnitSystem.metric ? 'e.g., 175.0' : 'e.g., 68.0';

    return Column(
      children: [
        // Weight Input
        TextField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: weightLabel,
            hintText: weightHint,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            suffixText: _currentUnit == UnitSystem.metric ? 'kg' : 'lbs',
          ),
        ),
        const SizedBox(height: 20),
        // Height Input
        TextField(
          controller: _heightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: heightLabel,
            hintText: heightHint,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            suffixText: _currentUnit == UnitSystem.metric ? 'cm' : 'in',
          ),
        ),
      ],
    );
  }

  // Helper widget to build the result display
  Widget _buildResultDisplay() {
    if (_bmiResult == null) {
      return Container();
    }
    return Column(
      children: [
        const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),
        Text(
          'Your BMI:',
          style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Text(
          '$_bmiResult',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: _categoryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _category,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: _categoryColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Calculator'),
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildUnitToggle(),
              const SizedBox(height: 40),
              _buildInputFields(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _calculateBMI,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Calculate BMI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              _buildResultDisplay(),
            ],
          ),
        ),
      ),
    );
  }
}
