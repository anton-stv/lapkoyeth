import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'community_repository.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _search = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    setState(() {
      _loading = true;
      _searched = true;
    });
    try {
      _results = await CommunityRepository.instance.search(_search.text);
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_firebaseSearchError(error))));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось выполнить поиск: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _firebaseSearchError(FirebaseException error) => switch (error.code) {
    'permission-denied' =>
      'Поиск запрещён правилами Firestore (permission-denied)',
    'failed-precondition' =>
      'Для поиска не создан индекс Firestore (failed-precondition)',
    'unavailable' => 'Сервис Firestore временно недоступен (unavailable)',
    _ => 'Ошибка Firestore: ${error.code}',
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Петобщество'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Друзья'),
              Tab(text: 'Заявки'),
              Tab(text: 'Найти'),
            ],
          ),
        ),
        body: TabBarView(children: [_friends(), _requests(), _searchUsers()]),
      ),
    );
  }

  Widget _friends() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: CommunityRepository.instance.requests(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const _Empty(
          icon: Icons.cloud_off_outlined,
          text: 'Не удалось загрузить друзей',
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final uid = CommunityRepository.instance.uid;
      final friendships = snapshot.data!.docs
          .where((doc) => doc.data()['status'] == 'accepted')
          .toList();
      if (friendships.isEmpty) {
        return const _Empty(
          icon: Icons.people_outline,
          text: 'Добавьте первых друзей',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: friendships.length,
        itemBuilder: (_, index) {
          final data = friendships[index].data();
          final otherUid = data['fromUid'] == uid
              ? data['toUid'] as String
              : data['fromUid'] as String;
          return _RemoteUserTile(
            userId: otherUid,
            onTap: () => _openProfile(otherUid),
            trailing: IconButton(
              tooltip: 'Удалить из друзей',
              icon: const Icon(Icons.person_remove_outlined),
              onPressed: () => _confirmDeleteConnection(
                friendships[index].id,
                'Удалить пользователя из друзей?',
              ),
            ),
          );
        },
      );
    },
  );

  Widget _requests() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: CommunityRepository.instance.requests(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const _Empty(
          icon: Icons.cloud_off_outlined,
          text: 'Не удалось загрузить заявки',
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final uid = CommunityRepository.instance.uid;
      final pending = snapshot.data!.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .toList();
      if (pending.isEmpty) {
        return const _Empty(
          icon: Icons.mark_email_read_outlined,
          text: 'Новых заявок нет',
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...pending.map((doc) {
            final data = doc.data();
            final incoming = data['toUid'] == uid;
            final otherUid = incoming
                ? data['fromUid'] as String
                : data['toUid'] as String;
            return _RemoteUserTile(
              userId: otherUid,
              subtitle: incoming ? 'Входящая заявка' : 'Исходящая заявка',
              trailing: incoming
                  ? Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Принять',
                          onPressed: () => CommunityRepository.instance
                              .setRequestStatus(doc.id, 'accepted'),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Отклонить',
                          onPressed: () => CommunityRepository.instance
                              .setRequestStatus(doc.id, 'rejected'),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    )
                  : TextButton.icon(
                      onPressed: () =>
                          CommunityRepository.instance.deleteConnection(doc.id),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Отменить'),
                    ),
              onTap: () => _openProfile(otherUid),
            );
          }),
        ],
      );
    },
  );

  Widget _searchUsers() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      TextField(
        controller: _search,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _runSearch(),
        decoration: InputDecoration(
          labelText: 'Имя или ID профиля',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            onPressed: _runSearch,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ),
      ),
      const SizedBox(height: 14),
      if (_loading)
        const Center(child: CircularProgressIndicator())
      else if (_results.isEmpty)
        _Empty(
          icon: Icons.person_search_outlined,
          text: _searched
              ? 'Пользователи не найдены'
              : 'Введите имя или уникальный ID',
        )
      else
        ..._results.map(
          (doc) => _UserTile(
            data: doc.data(),
            onTap: () => _openProfile(doc.id),
            trailing: FilledButton.tonal(
              onPressed: () async {
                await CommunityRepository.instance.sendRequest(doc.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заявка отправлена')),
                  );
                }
              },
              child: const Text('Добавить'),
            ),
          ),
        ),
    ],
  );

  void _openProfile(String uid) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: uid)),
  );

  Future<void> _confirmDeleteConnection(String id, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Петобщество'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await CommunityRepository.instance.deleteConnection(id);
    }
  }
}

class _RemoteUserTile extends StatelessWidget {
  final String userId;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  const _RemoteUserTile({
    required this.userId,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: CommunityRepository.instance.user(userId),
        builder: (_, snapshot) => _UserTile(
          data: snapshot.data?.data() ?? const {},
          subtitle: subtitle,
          trailing: trailing,
          onTap: onTap,
        ),
      );
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  const _UserTile({
    required this.data,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) {
    final photo = data['photoUrl'] as String?;
    final name = (data['displayName'] as String?)?.trim();
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundImage: photo == null ? null : NetworkImage(photo),
          child: photo == null ? const Icon(Icons.person_outline) : null,
        ),
        title: Text(name?.isNotEmpty == true ? name! : 'Пользователь'),
        subtitle: Text(subtitle ?? (data['publicId'] as String? ?? '')),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class PublicProfileScreen extends StatelessWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Профиль пользователя')),
    backgroundColor: AppColors.background,
    body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: CommunityRepository.instance.user(userId),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data!.data();
        if (user == null || user['profilePublic'] == false) {
          return const _Empty(icon: Icons.lock_outline, text: 'Профиль закрыт');
        }
        final photo = user['photoUrl'] as String?;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CircleAvatar(
              radius: 52,
              backgroundImage: photo == null ? null : NetworkImage(photo),
              child: photo == null
                  ? const Icon(Icons.person_outline, size: 48)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user['displayName'] as String? ?? 'Пользователь',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              user['publicId'] as String? ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if ((user['bio'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 18),
              Text(user['bio'] as String),
            ],
            if (user['petsPublic'] != false) ...[
              const SizedBox(height: 24),
              Text('Питомцы', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _PublicPets(userId: userId),
            ],
          ],
        );
      },
    ),
  );
}

class _PublicPets extends StatelessWidget {
  final String userId;
  const _PublicPets({required this.userId});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 142,
    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: CommunityRepository.instance.publicPets(userId),
      builder: (_, snapshot) {
        final pets = [...?snapshot.data?.docs]
          ..sort(
            (a, b) => ((a.data()['createdOrder'] as num?) ?? 0).compareTo(
              (b.data()['createdOrder'] as num?) ?? 0,
            ),
          );
        if (pets.isEmpty) return const Text('Публичных питомцев нет');
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: pets.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final data = pets[i].data();
            final photo = data['photoUrl'] as String?;
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PublicPetScreen(data: data)),
              ),
              child: SizedBox(
                width: 104,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: photo == null
                          ? null
                          : NetworkImage(photo),
                      child: photo == null
                          ? const Icon(Icons.pets, size: 36)
                          : null,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      data['name'] as String? ?? 'Питомец',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class PublicPetScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const PublicPetScreen({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final photo = data['photoUrl'] as String?;
    final photos =
        (data['photoUrls'] as List?)?.whereType<String>().toList() ??
        const <String>[];
    return Scaffold(
      appBar: AppBar(title: Text(data['name'] as String? ?? 'Питомец')),
      body: ListView(
        children: [
          SizedBox(
            height: 280,
            child: photo == null
                ? const ColoredBox(
                    color: AppColors.primary,
                    child: Center(
                      child: Icon(Icons.pets, color: Colors.white, size: 80),
                    ),
                  )
                : Image.network(photo, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] as String? ?? '',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if ((data['breed'] as String?)?.isNotEmpty == true)
                  Text(data['breed'] as String),
                if ((data['about'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 18),
                  Text(data['about'] as String),
                ],
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          photos[index],
                          width: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
