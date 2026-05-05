import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/usuario_provider.dart';

/// Usuarios list page
class UsuariosListPage extends ConsumerWidget {
  const UsuariosListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usuariosListProvider);

    // Load data on first build
    ref.listen(usuariosListProvider, (prev, next) {
      if (prev == null) {
        ref.read(usuariosListProvider.notifier).loadUsuarios();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(usuariosListProvider.notifier).loadUsuarios();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create usuario page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create usuario - TODO')),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.error}'),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(usuariosListProvider.notifier)
                              .loadUsuarios();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.usuarios.isEmpty
                  ? const Center(
                      child: Text('No usuarios found'),
                    )
                  : ListView.builder(
                      itemCount: state.usuarios.length,
                      itemBuilder: (context, index) {
                        final usuario = state.usuarios[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(usuario.email[0].toUpperCase()),
                          ),
                          title: Text(usuario.email),
                          subtitle: Text('${usuario.role} - ${usuario.status}'),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                onTap: () {
                                  // TODO: Navigate to edit page
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Edit ${usuario.email} - TODO'),
                                    ),
                                  );
                                },
                                child: const Text('Edit'),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  // Delete confirmation
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Usuario'),
                                      content: Text(
                                        'Are you sure you want to delete ${usuario.email}?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            ref
                                                .read(
                                                  usuariosListProvider
                                                      .notifier,
                                                )
                                                .deleteUsuario(usuario.id);
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Usuario deleted',
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                          onTap: () {
                            // TODO: Navigate to detail page
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('View ${usuario.email} - TODO'),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
