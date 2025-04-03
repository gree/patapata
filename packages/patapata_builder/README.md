<div align="center">
  <h1>Patapata - Builder</h1>
  <p>
    <strong>Adds new capabilities to your <a href="https://github.com/gree/patapata/blob/main/packages/patapata_core/lib/src/repository.dart">Repository</a>.</strong>
  </p>
</div>

---

## About
This package extends the functionality of [Patapata](https://pub.dev/packages/patapata_core) using build_runner.

Currently, it only includes [repository_sets_builder](https://github.com/gree/patapata/blob/main/packages/patapata_builder/lib/src/repository_sets_builder.dart), which extends [repository](https://github.com/gree/patapata/blob/main/packages/patapata_core/lib/src/repository.dart).

## Getting started

1. Add the dependency to your `pubspec.yaml` file

```yaml
dev_dependencies:
  patapata_builder: ^1.0.0
  build_runner: ^2.4.13
```

### Repository_sets_builder

[repository_sets_builder](https://github.com/gree/patapata/blob/main/packages/patapata_builder/lib/src/repository_sets_builder.dart) adds the concept of filters to the objects stored in a [repository](https://github.com/gree/patapata/blob/main/packages/patapata_core/lib/src/repository.dart).
Normally, the type of an object retrieved from a [repository](https://github.com/gree/patapata/blob/main/packages/patapata_core/lib/src/repository.dart) remains the same regardless of the hierarchy level it is retrieved from.
However, this can be inconvenient in some cases.

For example, consider a case where the same type of object is stored at different levels of a hierarchy.
At the parent level, only Data A is stored, while at the child level, Data B is stored.
If you try to access Data B from the parent level, it does not exist. However, it’s unclear whether it is truly null or simply not retrieved at that level.

To solve this, [repository_sets_builder](https://github.com/gree/patapata/blob/main/packages/patapata_builder/lib/src/repository_sets_builder.dart) provides filters that apply access restrictions based on the hierarchy level.
This makes it possible to clearly define which data should be accessible at each level, avoiding ambiguity and improving data integrity.

```dart
import 'package:patapata_core/patapata_annotation.dart';
import 'package:provider/provider.dart';

part 'model.g.dart';

mixin DataSet {}

@RepositoryClass(sets: {DataSet})
abstract class _Data extends ProviderModel<Data> {
  _Data({
    required this.id,
  });

  _Data.init(this.id) {
    final tData = Data(id: id);
    final tBatch = tData.begin();

    tBatch
      ..set(_name, 'id: $id')
      ..set(_value, 0)
  }

  @RepositoryId()
  final int id;

  @RepositoryField()
  late final _name = createUnsetVariable<String>();

  @RepositoryField(sets: {DataSet})
  late final _value = createUnsetVariable<int>();
}
```

By defining a class as shown above and running build_runner, the `Data` class will be generated.
When you store it in the [repository](https://github.com/gree/patapata/blob/main/packages/patapata_core/lib/src/repository.dart), it can be retrieved either as `Data` or as `DataSet`.

When retrieved as Data, all members are accessible.
However, when retrieved as DataSet, only `value1` can be accessed.

For more concrete usage examples, please refer to the repository section of [patapata_example_app](https://github.com/gree/patapata/tree/main/packages/patapata_example_app).

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_builder/LICENSE)
