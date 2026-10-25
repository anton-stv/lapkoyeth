import 'package:flutter_test/flutter_test.dart';
import 'package:lapkoyeth/features/community/community_repository.dart';

void main() {
  test(
    'search tokens include prefixes for first name, last name and both orders',
    () {
      final tokens = CommunityRepository.buildSearchTokens('Антон', 'Иванов');

      expect(
        tokens,
        containsAll(<String>[
          'а',
          'ант',
          'антон',
          'и',
          'ива',
          'иванов',
          'антон и',
          'иванов а',
        ]),
      );
    },
  );

  test('search tokens trim values and ignore blank last name', () {
    final tokens = CommunityRepository.buildSearchTokens('  Rex  ', '  ');

    expect(tokens, containsAll(<String>['r', 're', 'rex']));
    expect(tokens, isNot(contains('')));
  });
}
