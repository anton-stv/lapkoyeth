import 'package:flutter/material.dart';

class StoryModel {
  final String id;
  final String userName;
  final Color color;
  final String emoji;
  final bool isViewed;

  const StoryModel({
    required this.id,
    required this.userName,
    required this.color,
    required this.emoji,
    this.isViewed = false,
  });
}

// Заглушки пока нет реального контента
final stubStories = [
  const StoryModel(id: '1', userName: 'Бобик', color: Color(0xFF9DB8A5), emoji: '🐕'),
  const StoryModel(id: '2', userName: 'Мурка', color: Color(0xFFD9C2A3), emoji: '🐈'),
  const StoryModel(id: '3', userName: 'Рекс', color: Color(0xFFF2A56B), emoji: '🦴'),
  const StoryModel(id: '4', userName: 'Пушок', color: Color(0xFFA8D8D1), emoji: '🐾'),
  const StoryModel(id: '5', userName: 'Дружок', color: Color(0xFF9DB8A5), emoji: '🐶'),
  const StoryModel(id: '6', userName: 'Барсик', color: Color(0xFFE8B35A), emoji: '🐱'),
];
