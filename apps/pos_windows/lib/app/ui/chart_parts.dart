// Chart pieces shared by Analytics and the daily report: a ranked bar, hour
// columns, over and short bars, a legend swatch and a plain table (every chart
// can also be read as a table). Colors come from ChartColors; the money is
// always formatted by the caller (integer paise, E-MONEY-1).
import 'dart:math' as math;

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import 'chart_colors.dart';

/// One ranked horizontal bar: a label, a value (and a share), then the bar.
class RankedBarRow extends StatelessWidget {
  const RankedBarRow({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
    this.extra,
  });

  final String label;
  final String value;
  final String? extra;

  /// 0 to 1 of the width.
  final double fraction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (extra != null) ...[const SizedBox(width: 8), Text(extra!)],
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, c) => Container(
            width: c.maxWidth * fraction.clamp(0.0, 1.0),
            height: 12,
            decoration: const BoxDecoration(
              color: ChartColors.series,
              borderRadius: BorderRadius.horizontal(right: Radius.circular(6)),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Columns for each hour of the day with a readout line above. The peak hour
/// is the darker emphasis; hover or tap an hour to read it.
class HourColumns extends StatelessWidget {
  const HourColumns({
    super.key,
    required this.counts,
    required this.hover,
    required this.onHover,
    this.unit = 'bills',
    this.readoutKey = const Key('hours-readout'),
    this.chartKey = const Key('hours-chart'),
    this.extraReadout,
  });

  /// Bills in each hour, 24 entries.
  final List<int> counts;
  final int? hover;
  final ValueChanged<int?> onHover;
  final String unit;
  final Key readoutKey;
  final Key chartKey;

  /// More to say about the hour being read (for example what it sold).
  final String Function(int hour)? extraReadout;

  @override
  Widget build(BuildContext context) {
    var from = 9;
    var to = 21;
    for (var h = 0; h < 24; h++) {
      if (counts[h] > 0) {
        from = math.min(from, h);
        to = math.max(to, h);
      }
    }
    final most = counts.reduce(math.max);
    final peak = peakHour(counts);
    final shown = hover ?? peak;
    String span(int h) => '${hourText(h)} to ${hourText((h + 1) % 24)}';
    final extra = shown == null ? '' : (extraReadout?.call(shown) ?? '');
    final readout = shown == null
        ? 'No bills yet.'
        : hover == null
        ? 'Busiest: ${span(shown)}, ${counts[shown]} $unit$extra. Tap a column for any hour.'
        : '${span(shown)}: ${counts[shown]} $unit$extra';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(readout, key: readoutKey),
        const SizedBox(height: 10),
        SizedBox(
          key: chartKey,
          height: 190,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var h = from; h <= to; h++)
                Expanded(
                  child: MouseRegion(
                    onEnter: (_) => onHover(h),
                    onExit: (_) => onHover(null),
                    child: GestureDetector(
                      key: Key('hour-$h'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onHover(h),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 18,
                              child: counts[h] > 0 && (h == peak || h == hover)
                                  ? FittedBox(
                                      child: Text(
                                        '${counts[h]}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            Flexible(
                              child: FractionallySizedBox(
                                heightFactor: most == 0 ? 0 : counts[h] / most,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: 30,
                                  decoration: BoxDecoration(
                                    color: h == peak
                                        ? ChartColors.seriesDark
                                        : ChartColors.seriesLight,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                    border: h == hover
                                        ? Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: ChartColors.axis),
        Row(
          children: [
            for (var h = from; h <= to; h++)
              Expanded(
                child: Center(
                  child: Text(
                    '${h % 12 == 0 ? 12 : h % 12}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ChartColors.mutedText,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Hour of the day, shop time (am until 11, pm from 12).',
            style: TextStyle(fontSize: 12, color: ChartColors.mutedText),
          ),
        ),
      ],
    );
  }
}

/// One shift close for [CashCloseBars].
class CloseBar {
  const CloseBar({
    required this.name,
    required this.sub,
    required this.variance,
  });
  final String name;
  final String sub;

  /// Counted minus expected; negative is short.
  final Money variance;
}

/// Over (above the line, blue) and short (below it, red) for each close, with
/// the amount written on every bar so color is never the only cue.
class CashCloseBars extends StatelessWidget {
  const CashCloseBars({super.key, required this.closes});

  final List<CloseBar> closes;

  @override
  Widget build(BuildContext context) {
    final biggest = closes.fold<int>(
      0,
      (a, c) => math.max(a, c.variance.paise.abs()),
    );
    const half = 80.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 18,
          runSpacing: 6,
          children: [
            ChartSwatch(ChartColors.over, 'Over (more cash than expected)'),
            ChartSwatch(ChartColors.short, 'Short (less cash than expected)'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < closes.length; i++)
              Expanded(
                child: Column(
                  key: Key('close-$i'),
                  children: [
                    SizedBox(
                      height: half + 20,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (closes[i].variance.paise > 0)
                            Text(
                              '+${formatRupees(closes[i].variance)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (closes[i].variance.paise > 0)
                            Container(
                              width: 32,
                              height: half * closes[i].variance.paise / biggest,
                              decoration: const BoxDecoration(
                                color: ChartColors.over,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: ChartColors.axis),
                    SizedBox(
                      height: half + 20,
                      child: Column(
                        children: [
                          if (closes[i].variance.paise < 0)
                            Container(
                              width: 32,
                              height:
                                  half * -closes[i].variance.paise / biggest,
                              decoration: const BoxDecoration(
                                color: ChartColors.short,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(4),
                                ),
                              ),
                            ),
                          if (closes[i].variance.paise < 0)
                            Text(
                              '-${formatRupees(Money(-closes[i].variance.paise))}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (closes[i].variance.paise == 0)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Exact',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      closes[i].name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      closes[i].sub,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ChartColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class ChartSwatch extends StatelessWidget {
  const ChartSwatch(this.color, this.text, {super.key});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 8),
      Text(text),
    ],
  );
}

/// A plain table of what a chart shows: a header row, then the rows. The first
/// column is left aligned, the rest right aligned (they are numbers).
class ChartTable extends StatelessWidget {
  const ChartTable({super.key, required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    Widget cell(String s, int col, {bool head = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        s,
        textAlign: col == 0 ? TextAlign.left : TextAlign.right,
        style: TextStyle(fontWeight: head ? FontWeight.w700 : FontWeight.w400),
      ),
    );
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.6)},
      border: const TableBorder(
        horizontalInside: BorderSide(color: ChartColors.grid),
      ),
      children: [
        TableRow(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ChartColors.axis)),
          ),
          children: [
            for (var c = 0; c < headers.length; c++)
              cell(headers[c], c, head: true),
          ],
        ),
        for (final r in rows)
          TableRow(
            children: [for (var c = 0; c < r.length; c++) cell(r[c], c)],
          ),
      ],
    );
  }
}
