import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/verse_tracking/verse_tracking_bloc.dart';

class VerseDisplayCard extends StatelessWidget {
  const VerseDisplayCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VerseTrackingBloc, VerseTrackingState>(
      builder: (context, state) {
        if (state is VerseTrackingLoaded) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'سورة ${state.surah.name}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: state.isCompleted 
                              ? Colors.amber.shade100
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: state.isCompleted 
                                ? Colors.amber
                                : Colors.blue,
                          ),
                        ),
                        child: Text(
                          state.isCompleted
                              ? '✅ مكتملة'
                              : 'الآية ${state.currentVerseIndex + 1}/${state.surah.verses.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: state.isCompleted 
                                ? Colors.amber.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Progress bar
                  LinearProgressIndicator(
                    value: (state.currentVerseIndex + (state.isCompleted ? 1 : 0)) / state.surah.verses.length,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.isCompleted ? Colors.amber : Colors.green,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (!state.isCompleted) ...[
                    // Current verse display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            Colors.green.shade50,
                            Colors.green.shade100,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          // Arabic text
                          Text(
                            state.currentVerse.arabicText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.8,
                              color: Colors.black87,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Transliteration
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              state.currentVerse.transliteration,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Translation
                          Text(
                            state.currentVerse.translation,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Similarity indicator if available
                    if (state.lastSimilarity > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getSimilarityColor(state.lastSimilarity).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getSimilarityColor(state.lastSimilarity),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getSimilarityIcon(state.lastSimilarity),
                              color: _getSimilarityColor(state.lastSimilarity),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getSimilarityText(state.lastSimilarity),
                              style: TextStyle(
                                color: _getSimilarityColor(state.lastSimilarity),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(state.lastSimilarity * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: _getSimilarityColor(state.lastSimilarity),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    // Completion message
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber.shade50,
                            Colors.amber.shade100,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.celebration,
                            size: 48,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'مبروك! لقد أكملت سورة ${state.surah.name}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'تم حفظ ${state.surah.verses.length} آية',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        } else if (state is VerseTrackingLoading) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'جاري التحميل...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد بيانات متاحة',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  // Helper method to get similarity color based on percentage
  Color _getSimilarityColor(double similarity) {
    if (similarity >= 0.8) {
      return Colors.green;
    } else if (similarity >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Helper method to get similarity icon based on percentage
  IconData _getSimilarityIcon(double similarity) {
    if (similarity >= 0.8) {
      return Icons.check_circle;
    } else if (similarity >= 0.6) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  // Helper method to get similarity text based on percentage
  String _getSimilarityText(double similarity) {
    if (similarity >= 0.8) {
      return 'ممتاز';
    } else if (similarity >= 0.6) {
      return 'جيد';
    } else {
      return 'يحتاج تحسين';
    }
  }
}