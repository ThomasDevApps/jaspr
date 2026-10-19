@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';
import 'package:jaspr_riverpod/legacy.dart';
import 'package:jaspr_test/client_test.dart';
import 'package:web/web.dart';

import '../utils.dart';

void main() {
  group('sync', () {
    testClient('overrides sync provider with value', (tester) {
      document.body!.innerHTML =
          '<div>\n'
                  '  <!--\${"some_key":"value","some_number":42}-->\n'
                  '  <p>Hello World</p>\n'
                  '</div>\n'
              .toJS;

      final p1 = Provider((_) => 'initial');
      final p2 = StateProvider((_) => 0);

      tester.pumpComponent(
        div([
          ProviderScope(
            sync: [
              p1.syncWith('some_key'),
              p2.syncWith('some_number'),
            ],
            child: p([
              Builder(
                builder: (context) {
                  final v1 = context.read(p1);
                  final v2 = context.watch(p2);

                  return Component.text('One: $v1, Two: $v2');
                },
              ),
            ]),
          ),
        ]),
      );

      expect(find.text('One: value, Two: 42'), findsOneComponent);
    });

    testClient('uses codec when decoding sync provider value', (tester) {
      document.body!.innerHTML =
          '<div>\n'
                  '  <!--\${"some_number":42}-->\n'
                  '  <p>Hello World</p>\n'
                  '</div>\n'
              .toJS;

      final p1 = StateProvider((_) => 0);

      tester.pumpComponent(
        div([
          ProviderScope(
            sync: [
              p1.syncWith('some_number', codec: DoublingCodec()),
            ],
            child: p([
              Builder(
                builder: (context) {
                  final v1 = context.read(p1);

                  return Component.text('One: $v1');
                },
              ),
            ]),
          ),
        ]),
      );

      expect(find.text('One: 21'), findsOneComponent);
    });

    testClient('keeps sync overrides when the scope is updated', (tester) async {
      document.body!.innerHTML =
          '<div>\n'
                  '  <!--\${"some_key":"value"}-->\n'
                  '  <p>Hello World</p>\n'
                  '</div>\n'
              .toJS;

      final p1 = Provider((_) => 'initial');

      tester.pumpComponent(div([_RebuildingScope(provider: p1)]));

      expect(find.text('Value: value, Count: 0'), findsOneComponent);

      // Rebuilds the ProviderScope with a new instance -> updateOverrides
      await tester.click(find.tag('button'));

      expect(find.text('Value: value, Count: 1'), findsOneComponent);
    });
  });
}

/// ----------------------------------------------------------------------------

class _RebuildingScope extends StatefulComponent {
  const _RebuildingScope({required this.provider});

  final Provider<String> provider;

  @override
  State<_RebuildingScope> createState() => _RebuildingScopeState();
}

class _RebuildingScopeState extends State<_RebuildingScope> {
  var _count = 0;

  @override
  Component build(BuildContext context) {
    return ProviderScope(
      sync: [component.provider.syncWith('some_key')],
      child: p([
        Builder(
          builder: (context) {
            final value = context.watch(component.provider);
            return Component.text('Value: $value, Count: $_count');
          },
        ),
        button(
          onClick: () => setState(() => _count++),
          [Component.text('Rebuild')],
        ),
      ]),
    );
  }
}
