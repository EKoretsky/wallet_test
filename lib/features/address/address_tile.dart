import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:wallet_test/core/theme/app_tokens.dart';

import 'package:wallet_test/features/address/address_tile_bloc.dart';

class AddressTile extends StatefulWidget {
  const AddressTile({
    super.key,
    required this.address,
    required this.network,
  });

  final String address;
  final String network;

  @override
  State<AddressTile> createState() => _AddressTileState();
}

class _AddressTileState extends State<AddressTile> {
  late final AddressTileBloc _bloc = GetIt.instance<AddressTileBloc>();

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const .all(8),
      color: AppTokens.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .start,
              children: [
                Text(
                  widget.network,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTokens.textPrimary,
                  ),
                  overflow: .ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _bloc.add(CopyTapped(widget.address)),
            icon: const Icon(
              Icons.copy,
              size: 20,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
