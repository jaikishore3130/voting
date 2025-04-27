import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:voting/screens/candidate/nomination_tab.dart';

import 'package:voting/screens/otp_screen.dart';

class NominationScreen extends StatefulWidget {
  final String aadhaarNumber;
  final String subCollectionId;
  const NominationScreen({required this.aadhaarNumber, Key? key, required this.subCollectionId}) : super(key: key);

  @override
  State<NominationScreen> createState() => _NominationScreenState();
}

class _NominationScreenState extends State<NominationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final picker = ImagePicker();
  File? _photo;
  File? _video;
  String? photoUrl;
  String? videoUrl;
  String? _selectedConstituency;

  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _educationController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _constituencyController = TextEditingController();

  String? _selectedGender = 'MALE';
  String? _selectedState;
  String? _selectedParty;

  final Map<String, List<String>> stateConstituencies = {'Telangana': ['ADILABAD', 'BHONGIR', 'CHEVELLA', 'HYDERABAD', 'KARIMNAGAR', 'KHAMMAM', 'MAHABUBABAD',
    'MAHBUBNAGAR', 'MALKAJGIRI', 'MEDAK', 'NAGARKURNOOL', 'NALGONDA', 'NIZAMABAD', 'PEDDAPALLE', 'SECUNDRABAD', 'WARANGAL', 'ZAHIRABAD'],'Uttar Pradesh':
  ['AGRA', 'AKBARPUR', 'ALIGARH', 'ALLAHABAD', 'AMBEDKAR NAGAR', 'AMETHI', 'AMROHA', 'AONLA', 'AZAMGARH', 'BADAUN', 'BAGHPAT', 'BAHRAICH', 'BALLIA', 'BANDA',
    'BANSGAON', 'BARABANKI', 'BAREILLY', 'BASTI', 'BHADOHI', 'BIJNOR', 'BULANDSHAHR', 'CHANDAULI', 'DEORIA', 'DHAURAHRA', 'DOMARIYAGANJ', 'ETAH', 'ETAWAH',
    'FAIZABAD', 'FARRUKHABAD', 'FATEHPUR', 'FATEHPUR SIKRI', 'FIROZABAD', 'GAUTAM BUDDHA NAGAR', 'GHAZIABAD', 'GHAZIPUR', 'GHOSI', 'GONDA', 'GORAKHPUR', 'HAMIRPUR',
    'HARDOI', 'HATHRAS', 'JALAUN', 'JAUNPUR', 'JHANSI', 'KAIRANA', 'KAISERGANJ', 'KANNAUJ', 'KANPUR', 'KAUSHAMBI', 'KHERI', 'KUSHI NAGAR', 'LALGANJ', 'LUCKNOW',
    'MACHHLISHAHR', 'MAHARAJGANJ', 'MAINPURI', 'MATHURA', 'MEERUT', 'MIRZAPUR', 'MISRIKH', 'MOHANLALGANJ', 'MORADABAD', 'MUZAFFARNAGAR', 'NAGINA', 'PHULPUR',
    'PILIBHIT', 'PRATAPGARH', 'RAE BARELI', 'RAMPUR', 'ROBERTSGANJ', 'SAHARANPUR', 'SALEMPUR', 'SAMBHAL', 'SANT KABIR NAGAR', 'SHAHJAHANPUR', 'SHRAWASTI', 'SITAPUR',
    'SULTANPUR', 'UNNAO', 'VARANASI'],'Maharashtra': ['AHMADNAGAR', 'AKOLA', 'AMRAVATI', 'AURANGABAD', 'BARAMATI', 'BEED', 'BHANDARA - GONDIYA', 'BHIWANDI', 'BULDHANA',
    'CHANDRAPUR', 'DHULE', 'DINDORI', 'GADCHIROLI-CHIMUR', 'HATKANANGLE', 'HINGOLI', 'JALGAON', 'JALNA', 'KALYAN', 'KOLHAPUR', 'LATUR', 'MADHA', 'MAVAL', 'MUMBAI NORTH',
    'MUMBAI NORTH CENTRAL', 'MUMBAI NORTH EAST', 'MUMBAI NORTH WEST', 'MUMBAI SOUTH', 'MUMBAI SOUTH CENTRAL', 'NAGPUR', 'NANDED', 'NANDURBAR', 'NASHIK', 'OSMANABAD',
    'PALGHAR', 'PARBHANI', 'PUNE', 'RAIGAD', 'RAMTEK', 'RATNAGIRI - SINDHUDURG', 'RAVER', 'SANGLI', 'SATARA', 'SHIRDI', 'SHIRUR', 'SOLAPUR', 'THANE', 'WARDHA', 'YAVATMAL-WASHIM']
    ,'Gujarat': ['AHMEDABAD EAST', 'AHMEDABAD WEST', 'AMRELI', 'ANAND', 'BANASKANTHA', 'BARDOLI', 'BHARUCH', 'BHAVNAGAR', 'CHHOTA UDAIPUR', 'DAHOD', 'GANDHINAGAR', 'JAMNAGAR',
      'JUNAGADH', 'KACHCHH', 'KHEDA', 'MAHESANA', 'NAVSARI', 'PANCHMAHAL', 'PATAN', 'PORBANDAR', 'RAJKOT', 'SABARKANTHA', 'SURAT', 'SURENDRANAGAR', 'VADODARA', 'VALSAD']
    ,'Rajasthan': ['AJMER', 'ALWAR', 'BANSWARA', 'BARMER', 'BHARATPUR', 'BHILWARA', 'BIKANER (SC)', 'CHITTORGARH', 'CHURU', 'DAUSA', 'GANGANAGAR', 'JAIPUR', 'JAIPUR RURAL',
      'JALORE', 'JHALAWAR-BARAN', 'JHUNJHUNU', 'JODHPUR', 'KARAULI-DHOLPUR', 'KOTA', 'NAGAUR', 'PALI', 'RAJSAMAND', 'SIKAR', 'TONK-SAWAI MADHOPUR', 'UDAIPUR']
    ,'Kerala': ['ALAPPUZHA', 'ALATHUR', 'ATTINGAL', 'CHALAKUDY', 'ERNAKULAM', 'IDUKKI', 'KANNUR', 'KASARAGOD', 'KOLLAM', 'KOTTAYAM', 'KOZHIKODE', 'MALAPPURAM',
      'MAVELIKKARA', 'PALAKKAD', 'PATHANAMTHITTA', 'PONNANI', 'THIRUVANANTHAPURAM', 'THRISSUR', 'VADAKARA', 'WAYANAD'],'West Bengal': ['ALIPURDUARS', 'ARAMBAGH', 'ASANSOL', 'BAHARAMPUR',
      'BALURGHAT', 'BANGAON', 'BANKURA', 'BARASAT', 'BARDHAMAN DURGAPUR', 'BARDHAMAN PURBA', 'BARRACKPORE', 'BASIRHAT', 'BIRBHUM', 'BISHNUPUR', 'BOLPUR', 'COOCH BEHAR', 'DARJEELING',
      'DIAMOND HARBOUR', 'DUM DUM', 'GHATAL', 'HOOGHLY', 'HOWRAH', 'JADAVPUR', 'JALPAIGURI', 'JANGIPUR', 'JAYNAGAR',
      'JHARGRAM', 'KANTHI', 'KOLKATA DAKSHIN', 'KOLKATA UTTAR', 'KRISHNANAGAR', 'MALDAHA DAKSHIN', 'MALDAHA UTTAR', 'MATHURAPUR', 'MEDINIPUR', 'MURSHIDABAD', 'PURULIA', 'RAIGANJ', 'RANAGHAT', 'SRERAMPUR', 'TAMLUK', 'ULUBERIA']
    ,'Uttarakhand': ['ALMORA', 'GARHWAL', 'HARDWAR', 'NAINITAL-UDHAMSINGH NAGAR', 'TEHRI GARHWAL']
    ,'Andhra Pradesh': ['AMALAPURAM', 'ANAKAPALLI', 'ANANTAPUR', 'ARUKU', 'BAPATLA', 'CHITTOOR', 'ELURU', 'GUNTUR', 'HINDUPUR', 'KADAPA', 'KAKINADA', 'KURNOOL', 'MACHILIPATNAM',
      'NANDYAL', 'NARASARAOPET', 'NARSAPURAM', 'NELLORE', 'ONGOLE', 'RAJAHMUNDRY', 'RAJAMPET', 'SRIKAKULAM', 'TIRUPATI', 'VIJAYAWADA', 'VISAKHAPATNAM', 'VIZIANAGARAM']
    ,'Haryana': ['AMBALA', 'BHIWANI-MAHENDRAGARH', 'FARIDABAD', 'GURGAON', 'HISAR', 'KARNAL', 'KURUKSHETRA', 'ROHTAK', 'SIRSA', 'SONIPAT']
    ,'Punjab': ['AMRITSAR', 'ANANDPUR SAHIB', 'BATHINDA', 'FARIDKOT', 'FATEHGARH SAHIB', 'FIROZPUR', 'GURDASPUR', 'HOSHIARPUR', 'JALANDHAR', 'KHADOOR SAHIB', 'LUDHIANA', 'PATIALA', 'SANGRUR']
    ,'Jammu & Kashmir': ['ANANTNAG', 'BARAMULLA', 'JAMMU', 'LADAKH', 'SRINAGAR', 'UDHAMPUR']
    ,'Andaman & Nicobar Islands': ['ANDAMAN & NICOBAR ISLANDS']
    ,'Tamil Nadu': ['ARAKKONAM', 'ARANI', 'CHENNAI CENTRAL', 'CHENNAI NORTH', 'CHENNAI SOUTH', 'CHIDAMBARAM', 'COIMBATORE', 'CUDDALORE', 'DHARMAPURI', 'DINDIGUL', 'ERODE',
      'KALLAKURICHI', 'KANCHEEPURAM', 'KANNIYAKUMARI', 'KARUR', 'KRISHNAGIRI', 'MADURAI', 'MAYILADUTHURAI', 'NAGAPATTINAM', 'NAMAKKAL', 'NILGIRIS', 'PERAMBALUR', 'POLLACHI',
      'RAMANATHAPURAM', 'SALEM', 'SIVAGANGA', 'SRIPERUMBUDUR', 'TENKASI', 'THANJAVUR', 'THENI', 'THIRUVALLUR', 'THOOTHUKKUDI', 'TIRUCHIRAPPALLI', 'TIRUNELVELI', 'TIRUPPUR', 'TIRUVANNAMALAI', 'VILUPPURAM', 'VIRUDHUNAGAR']
    ,'Bihar': ['ARARIA', 'ARRAH', 'AURANGABAD', 'BANKA', 'BEGUSARAI', 'BHAGALPUR', 'BUXAR', 'DARBHANGA', 'GAYA (SC)', 'GOPALGANJ (SC)', 'HAJIPUR (SC)', 'JAHANABAD', 'JAMUI (SC)', 'JHANJHARPUR', 'KARAKAT', 'KATIHAR', 'KHAGARIA', 'KISHANGANJ', 'MADHEPURA', 'MADHUBANI', 'MAHARAJGANJ', 'MUNGER', 'MUZAFFARPUR', 'NALANDA', 'NAWADA', 'PASCHIM CHAMPARAN', 'PATALIPUTRA', 'PATNA SAHIB', 'PURNIA', 'PURVI CHAMPARAN', 'SAMASTIPUR (SC)', 'SARAN', 'SASARAM (SC)', 'SHEOHAR', 'SITAMARHI', 'SIWAN', 'SUPAUL', 'UJIARPUR', 'VAISHALI', 'VALMIKI NAGAR']
    ,'Arunachal Pradesh': ['ARUNACHAL EAST', 'ARUNACHAL WEST']
    ,'Odisha': ['ASKA', 'BALASORE', 'BARGARH', 'BERHAMPUR', 'BHADRAK', 'BHUBANESWAR', 'BOLANGIR', 'CUTTACK', 'DHENKANAL', 'JAGATSINGHPUR', 'JAJPUR', 'KALAHANDI', 'KANDHAMAL', 'KENDRAPARA', 'KEONJHAR', 'KORAPUT', 'MAYURBHANJ', 'NABARANGPUR', 'PURI', 'SAMBALPUR', 'SUNDARGARH']
    ,'Assam': ['AUTONOMOUS DISTRICT', 'BARPETA', 'DHUBRI', 'DIBRUGARH', 'GAUHATI', 'JORHAT', 'KALIABOR', 'KARIMGANJ', 'KOKRAJHAR', 'LAKHIMPUR', 'MANGALDOI', 'NOWGONG', 'SILCHAR', 'TEZPUR']
    ,'Karnataka': ['BAGALKOT', 'BANGALORE CENTRAL', 'BANGALORE NORTH', 'BANGALORE RURAL', 'BANGALORE SOUTH', 'BELGAUM', 'BELLARY', 'BIDAR', 'BIJAPUR', 'CHAMARAJANAGAR', 'CHIKKBALLAPUR', 'CHIKKODI', 'CHITRADURGA', 'DAKSHINA KANNADA', 'DAVANAGERE', 'DHARWAD', 'GULBARGA', 'HASSAN', 'HAVERI', 'KOLAR', 'KOPPAL', 'MANDYA', 'MYSORE', 'RAICHUR', 'SHIMOGA', 'TUMKUR', 'UDUPI CHIKMAGALUR', 'UTTARA KANNADA']
    ,'Madhya Pradesh': ['BALAGHAT', 'BETUL', 'BHIND', 'BHOPAL', 'CHHINDWARA', 'DAMOH', 'DEWAS', 'DHAR', 'GUNA', 'GWALIOR', 'HOSHANGABAD', 'INDORE', 'JABALPUR', 'KHAJURAHO', 'KHANDWA', 'KHARGONE', 'MANDLA', 'MANDSOUR', 'MORENA', 'RAJGARH', 'RATLAM', 'REWA', 'SAGAR', 'SATNA', 'SHAHDOL', 'SIDHI', 'TIKAMGARH', 'UJJAIN', 'VIDISHA']
    ,'Chhattisgarh': ['BASTAR', 'BILASPUR', 'DURG', 'JANJGIR-CHAMPA', 'KANKER', 'KORBA', 'MAHASAMUND', 'RAIGARH', 'RAIPUR', 'RAJNANDGAON', 'SARGUJA']
    ,'Chandigarh': ['CHANDIGARH']
    ,'NCT OF Delhi': ['CHANDNI CHOWK', 'EAST DELHI', 'NEW DELHI', 'NORTH EAST DELHI', 'NORTH WEST DELHI', 'SOUTH DELHI', 'WEST DELHI']
    ,'Jharkhand': ['CHATRA', 'DHANBAD', 'DUMKA', 'GIRIDIH', 'GODDA', 'HAZARIBAGH', 'JAMSHEDPUR', 'KHUNTI', 'KODARMA', 'LOHARDAGA', 'PALAMAU', 'RAJMAHAL', 'RANCHI', 'SINGHBHUM']
    ,'Dadra & Nagar Haveli': ['DADRA AND NAGAR HAVELI']
    ,'Daman & Diu': ['DAMAN & DIU']
    ,'Himachal Pradesh': ['HAMIRPUR', 'KANGRA', 'MANDI', 'SHIMLA']
    ,'Manipur': ['INNER MANIPUR', 'OUTER MANIPUR']
    ,'Lakshadweep': ['LAKSHADWEEP']
    ,'Mizoram': ['MIZORAM']
    ,'Nagaland': ['NAGALAND']
    ,'Goa': ['NORTH GOA', 'SOUTH GOA']
    ,'Puducherry': ['PUDUCHERRY'],'Meghalaya': ['SHILLONG', 'TURA'],'Sikkim': ['SIKKIM'],'Tripura': ['TRIPURA EAST', 'TRIPURA WEST']};


  List<String> get states => stateConstituencies.keys.toList();
  List<String> getConstituencies(String? state) => stateConstituencies[state] ?? [];

  final List<String> parties =  [
     'BJP', 'TRS', 'INC', 'BSP', 'NCP', 'VBA', 'APoI', 'CPI(M)', 'BDJS', 'AITC', 'RSP', 'SP', 'YSRCP',
    'TDP', 'JnP', 'INLD', 'SBSP', 'IND', 'SHS', 'AAP', 'SAD', 'JKN', 'JKPDP','JPC', 'DMK', 'PMK', 'NTK', 'MNM', 'AIADMK', 'RJD',
    'CPI(ML)(L)', 'SSD', 'PPA', 'JD(S)', 'NPEP', 'BMUP', 'BJD', 'AIMIM', 'HAMS', 'AHFBK', 'PPID', 'SPL', 'ASDC', 'RLD', 'PSPL',
    'JD(U)', 'BTP', 'AIFB', 'AGP', 'AIUDF', 'ABSKP', 'PUNEKP', 'RTORP', 'JNJP', 'LTSP', 'RVNP', 'JANADIP', 'SDPI', 'DMDK',
    'ABGP', 'VCK', 'JMM', 'LIP', 'JDR', 'MOSP', 'MADP', 'AJPR', 'PMP', 'BBMP', 'AJSUP', 'JVM', 'RMPOI', 'LJP',
    'BJKVP', 'SWP', 'NEINDP', 'RSPSR', 'ravp', 'RSOSP', 'BLSP', 'WPOI', 'SUCI(C)', 'SJDD', 'ANC', 'JDL', 'VSIP', 'AAM', 'JKP',
    'BOPF', 'UPPL', 'CPIM', 'GGP', 'KEC(M)', 'KEC', 'JAPL', 'AKBMP', 'TJS', 'IUML', 'BSCP', 'ADAL', 'BRPI', 'MNF', 'PRISMP',
    'VPI', 'YKP', 'NDPP', 'RLTP', 'RAHIS', 'NPF', 'BLSD', 'BVA', 'NAWPP', 'AINRC', 'BNDl', 'MSHP', 'BARESP', 'BLRP', 'AIPF',
    'WAP', 'VCSMP', 'SAD(M)', 'UDP', 'SKM', 'SDF', 'PDP', 'JHP', 'TMC(M)', 'IPFT', 'JKNPP', 'DSSP', 'AHNP', 'PHJSP'
  ];

  int? _calculatedAge;
  bool _isPhoneVerified = false;

  Future<File> encryptFile(File file, String aadhaar, String fileType) async {
    final key = encrypt.Key.fromUtf8('28212821282128212821282128212821');
    final iv = encrypt.IV.fromUtf8('3031303130313031');
    final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final inputBytes = await file.readAsBytes();
    final encrypted = encrypter.encryptBytes(inputBytes, iv: iv);

    final encryptedFileName = '${aadhaar}_$fileType.enc';
    final dir = await getTemporaryDirectory();
    final encryptedFile = File(path.join(dir.path, encryptedFileName));
    await encryptedFile.writeAsBytes(encrypted.bytes);

    print('Encrypted file saved to: ${encryptedFile.path}');
    return encryptedFile;
  }

  Future<String?> uploadToGitHub(File file, String filename) async {
    final token = 'YOUR_GIT_TOKEN';
    final repoOwner = 'YOUR_GITUSERNAME';
    final repoName = 'encrypted-profile-images';

    final url = 'https://api.github.com/repos/$repoOwner/$repoName/contents/$filename';
    final content = base64Encode(await file.readAsBytes());

    String? sha;

    // Step 1: Check if file already exists
    final getResponse = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
      },
    );

    if (getResponse.statusCode == 200) {
      final json = jsonDecode(getResponse.body);
      sha = json['sha'];
    } else if (getResponse.statusCode != 404) {
      print('❌ Failed to check file existence: ${getResponse.statusCode} ${getResponse.body}');
      return null;
    }

    // Step 2: Create or Update file
    final body = jsonEncode({
      'message': 'Upload encrypted file $filename',
      'content': content,
      if (sha != null) 'sha': sha, // include sha if updating
    });

    final putResponse = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
      },
      body: body,
    );

    if (putResponse.statusCode == 201 || putResponse.statusCode == 200) {
      final json = jsonDecode(putResponse.body);
      return json['content']['download_url'];
    } else {
      print('❌ Failed to upload: ${putResponse.statusCode} ${putResponse.body}');
      return null;
    }
  }

  Future<void> _pickPhoto(String aadhaar) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _photo = File(pickedFile.path);
      final encryptedFile = await encryptFile(_photo!, aadhaar, 'NP');
      photoUrl = await uploadToGitHub(encryptedFile, '${aadhaar}_NP.enc');
      print(photoUrl);
    }
  }

  Future<void> _captureVideo(String aadhaar) async {
    final pickedVideo = await picker.pickVideo(source: ImageSource.camera);
    if (pickedVideo != null) {
      _video = File(pickedVideo.path);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎥 Video captured')));
      final encryptedFile = await encryptFile(_video!, aadhaar, 'NV');
      videoUrl = await uploadToGitHub(encryptedFile, '${aadhaar}_NV.enc');
    }
  }

  void _selectDOB() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      _dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() =>
      _calculatedAge = DateTime
          .now()
          .year - pickedDate.year);
    }
  }

  Widget _buildTextField(TextEditingController controller,
      String label, {
        TextInputType type = TextInputType.text,
        bool isPassword = false,
        String? validatorText,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
        validator: (val) =>
        val == null || val.isEmpty ? (validatorText ?? 'Required') : null,
      ),
    );
  }


  Widget _buildDropdown<T>(String label,
      T? value,
      List<T> items,
      Function(T?) onChanged,) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: items.map((e) =>
            DropdownMenuItem<T>(value: e, child: Text(e.toString()))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  List<Step> _buildSteps(double screenWidth) =>
      [
        Step(
          title: const Text('Personal'),
          isActive: _currentStep >= 0,
          content: SingleChildScrollView(  // Wrap the content of the step with a scroll view
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(_nameController, 'Full Name'),
                _buildTextField(_fatherNameController, 'Father\'s Name'),
                _buildTextField(_motherNameController, 'Mother\'s Name'),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                        ),
                        onPressed: _selectDOB,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          _dobController.text.isEmpty ? 'Select DOB' : _dobController.text,
                          style: TextStyle(fontSize: screenWidth * 0.035),
                        ),
                      ),
                    ),
                    if (_calculatedAge != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          'Age: $_calculatedAge',
                          style: TextStyle(fontSize: screenWidth * 0.04),
                        ),
                      ),
                  ],
                ),
                _buildTextField(_educationController, 'Education'),
                const SizedBox(height: 12),
                const Text('Gender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ['MALE', 'FEMALE', 'OTHERS'].map((gender) {
                    return ChoiceChip(
                      label: Text(gender),
                      selected: _selectedGender == gender,
                      onSelected: (selected) {
                        setState(() => _selectedGender = gender);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        Step(
          title: Text('Location'),
          isActive: _currentStep >= 1,
          content: Column(
            children: [
              _buildTextField(_addressController, 'Postal Address'),

              // State Dropdown
              _buildDropdown(
                  'State',
                  _selectedState,
                  states,
                      (val) {
                    setState(() {
                      _selectedState = val;
                      _selectedConstituency = null; // Reset constituency when state changes
                    });
                  }
              ),

              // Constituency Dropdown
              if (_selectedState != null)
                _buildDropdown(
                  'Constituency',
                  _selectedConstituency,
                  getConstituencies(_selectedState),
                      (val) => setState(() => _selectedConstituency = val),
                ),



              // Political Party Dropdown
              _buildDropdown(
                  'Political Party', _selectedParty, parties, (val) =>
                  setState(() => _selectedParty = val)),

            ],
          ),
        ),


        Step(
          title: Text('Authentication'),
          isActive: _currentStep >= 2,
          content: Column(
            children: [
              _buildTextField(
                  _phoneController, 'Phone Number', type: TextInputType.phone),
              if (!_isPhoneVerified)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20)),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OtpScreen(
                              phoneNumber: "+91${_phoneController.text.trim()}",
                              aadhaarNumber: widget.aadhaarNumber,
                              userType: 'nomination',
                            ),
                      ),
                    );
                    if (result == true) {
                      setState(() => _isPhoneVerified = true);
                    }
                  },
                  icon: Icon(Icons.verified),
                  label: Text('Verify Phone Number'),
                ),
              if (_isPhoneVerified) ...[
                _buildTextField(
                    _passwordController, 'password', isPassword: true),
                _buildTextField(_confirmPasswordController, 'Confirm Password',
                    isPassword: true),
              ],
            ],
          ),
        ),
        Step(
          title: Text('e-KYC'),
          isActive: _currentStep >= 3,
          content: Column(
            children: [
              _photo != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_photo!, height: 100),
              )
                  : Text('No photo selected'),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _pickPhoto(widget.aadhaarNumber),
                icon: Icon(Icons.image_outlined),
                label: Text('Upload Photo'),
                style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14)),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _captureVideo(widget.aadhaarNumber),
                icon: Icon(Icons.videocam_outlined),
                label: Text(
                    _video != null ? 'Video Captured ✅' : 'Capture Face Video'),
                style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
          ),
        ),
      ];


  Future<void> _submitNomination() async {
    final nominationRef = FirebaseFirestore.instance.collection('nominations')
        .doc('list')
        .collection(widget.subCollectionId);

    // Check if the nomination already exists for this Aadhaar number
    final existingNomination = await nominationRef.doc(widget.aadhaarNumber)
        .get();

    if (existingNomination.exists) {
      // Navigate to the status screen if nomination already exists
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) =>
            NominationTab(
              aadhaarNumber: widget.aadhaarNumber,
              subCollectionId: widget.subCollectionId,)),
      );
      return;
    }

    // Save the nomination
    await nominationRef.doc(widget.aadhaarNumber).set({
      'name': _nameController.text,
      'father_name': _fatherNameController.text,
      'mother_name': _motherNameController.text,
      'age': _calculatedAge,
      'education': _educationController.text,
      'address': _addressController.text,
      'phone_number': _phoneController.text,
      'gender': _selectedGender,
      'state': _selectedState,
      'party': _selectedParty,
      'constituency': _selectedConstituency,
      'photo': photoUrl,
      'video': videoUrl,
      'ec_head': false,
      'ec_deputy_head': false,
      'password': _passwordController.text
    });

    // Navigate to NominationStatusScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) =>
          NominationTab(
            aadhaarNumber: widget.aadhaarNumber,
            subCollectionId: widget.subCollectionId,)),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty &&
            _fatherNameController.text.isNotEmpty &&
            _motherNameController.text.isNotEmpty &&
            _dobController.text.isNotEmpty &&
            _educationController.text.isNotEmpty;
      case 1:
        return _addressController.text.isNotEmpty &&
            _selectedState != null &&
            _constituencyController.text.isNotEmpty &&
            _selectedParty != null;
      case 2:
        if (!_isPhoneVerified) return false;
        return _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text == _passwordController.text;
      case 3:
        return _photo != null && _video != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(title: const Text("Nomination Form")),
      body: SingleChildScrollView( // Wrap Stepper in SingleChildScrollView for general scrolling
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : screenWidth * 0.2,
          vertical: 20,
        ),
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < _buildSteps(screenWidth).length - 1) {
                setState(() => _currentStep += 1);
              } else {
                _submitNomination();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              }
            },
            steps: _buildSteps(screenWidth),
          ),
        ),
      ),
    );
  }
}
