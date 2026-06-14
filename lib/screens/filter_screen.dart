import 'package:flutter/material.dart';

import '../models/gas_station.dart';
import '../theme/app_theme.dart';

/// Pantalla de filtros: combustible y orden son controlados por
/// [MainScaffold] para que la lista y el mapa reflejen la selección.
class FilterScreen extends StatelessWidget {
  const FilterScreen({
    super.key,
    required this.selectedFuel,
    required this.sortOrder,
    required this.onFuelChanged,
    required this.onSortOrderChanged,
    required this.onApply,
  });

  final FuelType selectedFuel;
  final SortOrder sortOrder;
  final ValueChanged<FuelType> onFuelChanged;
  final ValueChanged<SortOrder> onSortOrderChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Filtros',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ajusta la búsqueda a tu gusto',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          Text(
            'Tipo de combustible',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: FuelType.values.map((fuel) {
              final selected = fuel == selectedFuel;
              return ChoiceChip(
                label: Text(fuel.label),
                selected: selected,
                onSelected: (_) => onFuelChanged(fuel),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                labelStyle: textTheme.bodyMedium?.copyWith(
                  color: selected ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide.none,
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text(
            'Ordenar por',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Card(
            child: RadioGroup<SortOrder>(
              groupValue: sortOrder,
              onChanged: (value) => onSortOrderChanged(value!),
              child: const Column(
                children: [
                  RadioListTile<SortOrder>(
                    value: SortOrder.price,
                    title: Text('Precio (menor a mayor)'),
                    activeColor: AppColors.primary,
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<SortOrder>(
                    value: SortOrder.distance,
                    title: Text('Distancia (más cercana)'),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: onApply,
            child: const SizedBox(
              width: double.infinity,
              child: Text('Aplicar filtros', textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}
