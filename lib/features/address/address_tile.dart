import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:wallet_test/core/theme/app_tokens.dart';
import 'package:wallet_test/features/address/address_display.dart';
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
    const addressFontSize = 14.0;
    final scaledAddressFontSize = MediaQuery.textScalerOf(context).scale(addressFontSize);
    final textScaleFactor = scaledAddressFontSize / addressFontSize;

    return Container(
      height: AppTokens.cellHeight,
      padding: const .symmetric(horizontal: AppTokens.horizontalPadding),
      color: AppTokens.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .start,
              spacing: AppTokens.verticalGap,
              children: [
                Text(
                  widget.network,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: AppTokens.textSecondary,
                  ),
                  overflow: .ellipsis,
                ),
                Text(
                  formatAddressForCell(widget.address, textScaleFactor),
                  style: const TextStyle(
                    fontSize: addressFontSize,
                    color: AppTokens.textPrimary,
                  ),
                  overflow: .ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.gapTextIcon),
          BlocBuilder<AddressTileBloc, AddressTileState>(
            bloc: _bloc,
            builder: (context, state) {
              final appearance = _CopyButtonAppearance.fromState(state);

              return SizedBox.square(
                dimension: AppTokens.tapTarget,
                child: IconButton(
                  padding: .zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _bloc.add(CopyTapped(widget.address)),
                  icon: Icon(
                    appearance.icon,
                    size: appearance.iconSize,
                    color: appearance.color,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CopyButtonAppearance {
  const _CopyButtonAppearance({
    required this.icon,
    required this.color,
    required this.iconSize
  });

  factory _CopyButtonAppearance.fromState(AddressTileState state) {
    final (:icon, :color) = switch (state) {
      AddressTileState(error: String _) => (
        icon: Icons.error_outline,
        color: AppTokens.danger,
      ),
      AddressTileState(copied: true) => (
        icon: Icons.check,
        color: AppTokens.success,
      ),
      _ => (
        icon: Icons.copy,
        color: AppTokens.textSecondary,
      ),
    };

    return _CopyButtonAppearance(
      icon: icon,
      color: color,
      iconSize: AppTokens.iconSize
    );
  }

  final IconData icon;
  final Color color;
  final double iconSize;
}
