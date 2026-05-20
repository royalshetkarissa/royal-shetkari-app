import 'package:flutter/material.dart';
import '../widgets/royal_app_bar.dart';

class OrganicTipsScreen extends StatelessWidget {
  const OrganicTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const RoyalAppBar(
        title: 'सेंद्रिय शेती मार्गदर्शिका / Organic Tips',
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
            stops: [0.0, 0.25],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildIntroductionCard(),
            const SizedBox(height: 16),
            _buildTipCard(
              titleMr: '१. वर्मीवॉश (Vermiwash) बनवणे',
              titleEn: '1. Making Vermiwash Fertilizer',
              icon: Icons.opacity,
              color: Colors.amber[800]!,
              steps: [
                'एक प्लास्टिक बादली किंवा मातीचे मडके घ्या आणि त्याच्या तळाशी लहान नळ (Tap) बसवा.',
                'भांड्याच्या तळाशी ३ इंच विटांचे तुकडे व वाळूचा थर द्या (पाणी गाळून येण्यासाठी).',
                'त्यावर अर्धवट कुजलेले शेणखत आणि ओला कचरा ३ इंच थरात भरा.',
                'त्यात ५० ते १०० गांडुळे सोडा आणि त्यावर गोणपाटाचे आच्छादन घाला.',
                'वरच्या गोणपाटावर रोज हलके पाणी शिंपडा (जास्त पाणी घालू नका).',
                '१५-२० दिवसांत गांडुळांच्या शरीरातून निघालेला पौष्टिक अर्क बादलीच्या नळातून जमा होईल. हाच वर्मीवॉश आहे!',
                'वापर: १ लिटर वर्मीवॉश १० लिटर पाण्यात मिसळून पिकांवर फवारावा.'
              ],
              benefits: [
                'पिकांची वाढ निरोगी आणि जलद होते.',
                'पानांना गडद हिरवा रंग येतो व रोगप्रतिकारक शक्ती वाढते.'
              ],
            ),
            const SizedBox(height: 16),
            _buildTipCard(
              titleMr: '२. सेंद्रिय जीवामृत (Slurry) प्रक्रिया',
              titleEn: '2. Jeevamrut / Organic Slurry Process',
              icon: Icons.eco,
              color: Colors.green[800]!,
              steps: [
                '२०० लिटर पाण्याचे बॅरल घ्या आणि त्यात खत मिसळण्यासाठी १८० लिटर पाणी भरा.',
                'त्यात १० किलो देशी गायीचे ताजे शेण आणि १० लिटर देशी गोमूत्र मिसळा.',
                'त्यात २ किलो जुना गूळ आणि २ किलो हरभरा किंवा डाळीचे पीठ (बेसन) टाका.',
                'त्यात सेंद्रिय जिवाणू वाढवण्यासाठी वडाच्या किंवा पिंपळाच्या झाडाखालची मूठभर सुपीक माती टाका.',
                'हे द्रावण लाकडाच्या साहाय्याने सकाळ-संध्याकाळ उजव्या दिशेने (Clockwise) २ मिनिटे हलवा.',
                'बॅरल गोणपाटाने झाकून सावलीत ठेवा व ५ ते ७ दिवस द्रावण आंबण्यासाठी सोडा.',
                '७ दिवसांत अत्यंत शक्तिशाली जीवामृत तयार होईल.',
                'वापर: २०० लिटर जीवामृत प्रति एकर जमिनीतून किंवा ठिबकद्वारे द्यावे.'
              ],
              benefits: [
                'मातीमधील सूक्ष्म जीवाणूंची संख्या जलद गतीने वाढते.',
                'जमिनीची सुपीकता सुधारून हवा खेळती राहते.'
              ],
            ),
            const SizedBox(height: 16),
            _buildTipCard(
              titleMr: '३. घरी ह्युमिक आणि सेंद्रिय कार्बन बनवणे',
              titleEn: '3. Humic & Organic Carbon at Home',
              icon: Icons.layers,
              color: Colors.brown[700]!,
              steps: [
                '१०० लिटर पाण्यामध्ये ५ किलो चांगले कुजलेले जुने शेणखत किंवा गांडूळ खत टाका.',
                'त्यात १ किलो काळा जुना गूळ आणि ५० ग्रॅम ट्रायकोडर्मा जिवाणू पावडर मिसळा.',
                'या द्रावणात ५०० ग्रॅम सुकलेल्या कडुनिंबाच्या पाल्याची पावडर टाका.',
                'द्रावण गोणपाटाने झाकून ७ ते १० दिवस सावलीत राहू द्या आणि रोज एकदा हलवा.',
                '१० दिवसांत गडद काळ्या रंगाचे घरगुती ह्युमिक ॲसिड आणि सेंद्रिय कार्बन द्रावण तयार होईल.',
                'वापर: ५०० मिली द्रावण १५ लिटर पंपात घेऊन पिकांच्या मुळाशी आळवणी (Drenching) करावी.'
              ],
              benefits: [
                'मुळांची लांबी आणि अन्नद्रव्ये शोषून घेण्याची क्षमता कमालीची वाढते.',
                'मातीतील सेंद्रिय कर्बाचे (Organic Carbon) प्रमाण वेगाने सुधारते.'
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroductionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny, color: Colors.orange, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'विषमुक्त शेती, समृद्ध शेतकरी!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'घरच्या घरी अत्यंत सोप्या पद्धतीने सेंद्रिय खते व औषधे तयार करून उत्पादन खर्च शून्यावर आणा.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard({
    required String titleMr,
    required String titleEn,
    required IconData icon,
    required Color color,
    required List<String> steps,
    required List<String> benefits,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.85), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleMr,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      Text(
                        titleEn,
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'कृती आणि पायऱ्या / Step-by-Step Method:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                ...steps.asMap().entries.map((entry) {
                  int idx = entry.key + 1;
                  String text = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: color.withOpacity(0.15),
                          child: Text(
                            '$idx',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            text,
                            style: const TextStyle(fontSize: 12.5, height: 1.4, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(height: 24),
                const Text(
                  'फायदे / Key Benefits:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                ),
                const SizedBox(height: 6),
                ...benefits.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              b,
                              style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
