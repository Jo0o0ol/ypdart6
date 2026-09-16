import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';
import '../core/services.dart';
import '../models/models.dart';

Future<bool> editAuthor(BuildContext context, AppServices services, Author? item) async {
  final name = TextEditingController(text: item?.fullName ?? '');
  final year = TextEditingController(text: item?.birthYear?.toString() ?? '');
  final country = TextEditingController(text: item?.country ?? '');
  final formKey = GlobalKey<FormState>();
  var saving = false;
  var serverErrors = <String, String>{};

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> save() async {
            setState(() => serverErrors = <String, String>{});
            if (!formKey.currentState!.validate()) return;
            setState(() => saving = true);
            final value = Author(
              id: item?.id ?? 0,
              fullName: name.text.trim(),
              birthYear: int.tryParse(year.text.trim()),
              country: country.text.trim(),
            );
            try {
              if (item == null) {
                await services.authors.create(value);
              } else {
                await services.authors.update(item.id, value);
              }
              services.references.invalidate();
              if (context.mounted) Navigator.pop(context, true);
            } on ValidationException catch (e) {
              setState(() => serverErrors = e.errors);
              formKey.currentState!.validate();
            } on ApiException catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
              }
            } finally {
              if (context.mounted) setState(() => saving = false);
            }
          }

          return AlertDialog(
            title: Text(item == null ? 'Новый автор' : 'Редактирование автора'),
            content: SizedBox(
              width: math.min(520.0, math.max(260.0, MediaQuery.sizeOf(context).width - 48.0)),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'ФИО', border: OutlineInputBorder()),
                      validator: (value) {
                        final server = serverErrors['fullName'];
                        if (server != null) return server;
                        if (value == null || value.trim().isEmpty) return 'Введите ФИО';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: year,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Год рождения', border: OutlineInputBorder()),
                      validator: (value) {
                        final server = serverErrors['birthYear'];
                        if (server != null) return server;
                        if (value != null && value.trim().isNotEmpty && int.tryParse(value.trim()) == null) {
                          return 'Введите целое число';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: country,
                      decoration: const InputDecoration(labelText: 'Страна', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(context, false), child: const Text('Отмена')),
              FilledButton(onPressed: saving ? null : save, child: const Text('Сохранить')),
            ],
          );
        },
      );
    },
  );

  name.dispose();
  year.dispose();
  country.dispose();
  return result == true;
}

Future<bool> editGenre(BuildContext context, AppServices services, Genre? item) async {
  final name = TextEditingController(text: item?.name ?? '');
  final description = TextEditingController(text: item?.description ?? '');
  final formKey = GlobalKey<FormState>();
  var saving = false;
  var serverErrors = <String, String>{};

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> save() async {
            setState(() => serverErrors = <String, String>{});
            if (!formKey.currentState!.validate()) return;
            setState(() => saving = true);
            final value = Genre(
              id: item?.id ?? 0,
              name: name.text.trim(),
              description: description.text.trim(),
            );
            try {
              if (item == null) {
                await services.genres.create(value);
              } else {
                await services.genres.update(item.id, value);
              }
              services.references.invalidate();
              if (context.mounted) Navigator.pop(context, true);
            } on ValidationException catch (e) {
              setState(() => serverErrors = e.errors);
              formKey.currentState!.validate();
            } on ApiException catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
            } finally {
              if (context.mounted) setState(() => saving = false);
            }
          }

          return AlertDialog(
            title: Text(item == null ? 'Новый жанр' : 'Редактирование жанра'),
            content: SizedBox(
              width: math.min(520.0, math.max(260.0, MediaQuery.sizeOf(context).width - 48.0)),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder()),
                      validator: (value) {
                        final server = serverErrors['name'];
                        if (server != null) return server;
                        if (value == null || value.trim().isEmpty) return 'Введите название';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: description,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(context, false), child: const Text('Отмена')),
              FilledButton(onPressed: saving ? null : save, child: const Text('Сохранить')),
            ],
          );
        },
      );
    },
  );

  name.dispose();
  description.dispose();
  return result == true;
}

Future<bool> editPublisher(BuildContext context, AppServices services, Publisher? item) async {
  final name = TextEditingController(text: item?.name ?? '');
  final city = TextEditingController(text: item?.city ?? '');
  final year = TextEditingController(text: item?.foundedYear?.toString() ?? '');
  final formKey = GlobalKey<FormState>();
  var saving = false;
  var serverErrors = <String, String>{};

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> save() async {
            setState(() => serverErrors = <String, String>{});
            if (!formKey.currentState!.validate()) return;
            setState(() => saving = true);
            final value = Publisher(
              id: item?.id ?? 0,
              name: name.text.trim(),
              city: city.text.trim(),
              foundedYear: int.tryParse(year.text.trim()),
            );
            try {
              if (item == null) {
                await services.publishers.create(value);
              } else {
                await services.publishers.update(item.id, value);
              }
              services.references.invalidate();
              if (context.mounted) Navigator.pop(context, true);
            } on ValidationException catch (e) {
              setState(() => serverErrors = e.errors);
              formKey.currentState!.validate();
            } on ApiException catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
            } finally {
              if (context.mounted) setState(() => saving = false);
            }
          }

          return AlertDialog(
            title: Text(item == null ? 'Новое издательство' : 'Редактирование издательства'),
            content: SizedBox(
              width: math.min(520.0, math.max(260.0, MediaQuery.sizeOf(context).width - 48.0)),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder()),
                      validator: (value) {
                        final server = serverErrors['name'];
                        if (server != null) return server;
                        if (value == null || value.trim().isEmpty) return 'Введите название';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: city, decoration: const InputDecoration(labelText: 'Город', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: year,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Год основания', border: OutlineInputBorder()),
                      validator: (value) {
                        final server = serverErrors['foundedYear'];
                        if (server != null) return server;
                        if (value != null && value.trim().isNotEmpty && int.tryParse(value.trim()) == null) return 'Введите целое число';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(context, false), child: const Text('Отмена')),
              FilledButton(onPressed: saving ? null : save, child: const Text('Сохранить')),
            ],
          );
        },
      );
    },
  );

  name.dispose();
  city.dispose();
  year.dispose();
  return result == true;
}

Future<bool> editReader(BuildContext context, AppServices services, Reader? item) async {
  final name = TextEditingController(text: item?.fullName ?? '');
  final email = TextEditingController(text: item?.email ?? '');
  final phone = TextEditingController(text: item?.phone ?? '');
  final formKey = GlobalKey<FormState>();
  var saving = false;
  var serverErrors = <String, String>{};

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> save() async {
            setState(() => serverErrors = <String, String>{});
            if (!formKey.currentState!.validate()) return;
            setState(() => saving = true);
            final value = Reader(
              id: item?.id ?? 0,
              fullName: name.text.trim(),
              email: email.text.trim(),
              phone: phone.text.trim(),
              card: item?.card,
            );
            try {
              if (item == null) {
                await services.readers.create(value);
              } else {
                await services.readers.update(item.id, value);
              }
              if (context.mounted) Navigator.pop(context, true);
            } on ValidationException catch (e) {
              setState(() => serverErrors = e.errors);
              formKey.currentState!.validate();
            } on ApiException catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
            } finally {
              if (context.mounted) setState(() => saving = false);
            }
          }

          return AlertDialog(
            title: Text(item == null ? 'Новый читатель' : 'Редактирование читателя'),
            content: SizedBox(
              width: math.min(520.0, math.max(260.0, MediaQuery.sizeOf(context).width - 48.0)),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'ФИО', border: OutlineInputBorder()),
                      validator: (value) {
                        final server = serverErrors['fullName'];
                        if (server != null) return server;
                        if (value == null || value.trim().isEmpty) return 'Введите ФИО';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                      validator: (value) {
                        final server = serverErrors['email'];
                        if (server != null) return server;
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Введите e-mail';
                        if (!text.contains('@') || !text.contains('.')) return 'Некорректный e-mail';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Телефон', border: OutlineInputBorder())),
                    if (item?.card != null) ...[
                      const SizedBox(height: 12),
                      Text('Читательский билет: ${item!.card!.number}'),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(context, false), child: const Text('Отмена')),
              FilledButton(onPressed: saving ? null : save, child: const Text('Сохранить')),
            ],
          );
        },
      );
    },
  );

  name.dispose();
  email.dispose();
  phone.dispose();
  return result == true;
}
