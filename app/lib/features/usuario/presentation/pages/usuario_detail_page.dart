import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/usuario_provider.dart';

/// Usuario detail page
class UsuarioDetailPage extends ConsumerWidget {
  final String usuarioId;

  const UsuarioDetailPage({
    Key? key,
    required this.usuarioId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarioAsync = ref.watch(usuarioProvider(usuarioId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuario Details'),
      ),
      body: usuarioAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(usuarioProvider(usuarioId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (usuario) {
          if (usuario == null) {
            return const Center(
              child: Text('Usuario not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    child: Text(
                      usuario.email[0].toUpperCase(),
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Details
                _buildDetailCard(
                  label: 'Email',
                  value: usuario.email,
                ),
                _buildDetailCard(
                  label: 'ID',
                  value: usuario.id,
                ),
                _buildDetailCard(
                  label: 'Role',
                  value: usuario.role,
                ),
                _buildDetailCard(
                  label: 'Status',
                  value: usuario.status,
                ),
                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement edit
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit usuario - TODO'),
                            ),
                          );
                        },
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
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
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(usuariosListProvider.notifier)
                                        .deleteUsuario(usuario.id);
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Usuario deleted'),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build detail card widget
  Widget _buildDetailCard({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(value),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
