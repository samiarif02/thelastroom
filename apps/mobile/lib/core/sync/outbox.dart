import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// What an outbox row sends.
enum OutboxKind {
  /// One attempt, by its `attempt_id`.
  attempt,

  /// The profile's current state (one row at most).
  profile,
}

/// One thing still to send.
class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.kind,
    required this.ref,
    required this.tries,
  });

  final int id;
  final OutboxKind kind;

  /// The attempt's id, or [Outbox.profileRef].
  final String ref;

  /// Failed sends so far.
  final int tries;
}

/// The outbox (docs/rules/state-management.md): rows are written in the same transaction as the
/// change they send, and deleted once the server has it. A failed send waits longer each time
/// ([backoff]), so a device offline for a week never retries in a tight loop.
class Outbox {
  const Outbox(this._db);

  final AppDatabase _db;

  static const String profileRef = 'profile';

  /// The first retry waits this long; each failure doubles it, up to [maxBackoff].
  static const Duration firstBackoff = Duration(seconds: 5);
  static const Duration maxBackoff = Duration(minutes: 30);

  /// How long to wait after [tries] failed sends.
  static Duration backoff(int tries) {
    final doubled =
        firstBackoff.inMilliseconds * math.pow(2, math.max(0, tries - 1));
    return Duration(
      milliseconds: math.min(doubled.toInt(), maxBackoff.inMilliseconds),
    );
  }

  /// Queues [ref]; queuing the same thing twice is one row. Call inside the transaction that
  /// writes the change, so the two land together or not at all.
  Future<void> add(OutboxKind kind, String ref) => _db.customStatement(
    'insert into outbox (kind, ref) values (?, ?) '
    'on conflict (kind, ref) do update set tries = 0, next_try_at = 0',
    [kind.name, ref],
  );

  /// Rows due at [now], oldest first, at most [limit].
  Future<List<OutboxEntry>> due(DateTime now, {int limit = batchSize}) async {
    final rows = await _db
        .customSelect(
          'select id, kind, ref, tries from outbox where next_try_at <= ? '
          'order by id limit ?',
          variables: [
            Variable.withInt(now.millisecondsSinceEpoch),
            Variable.withInt(limit),
          ],
        )
        .get();
    return [
      for (final r in rows)
        if (_kind(r.read<String>('kind')) case final kind?)
          OutboxEntry(
            id: r.read<int>('id'),
            kind: kind,
            ref: r.read<String>('ref'),
            tries: r.read<int>('tries'),
          ),
    ];
  }

  /// How many rows wait, due or not.
  Future<int> get length async {
    final row = await _db
        .customSelect('select count(*) as n from outbox')
        .getSingle();
    return row.read<int>('n');
  }

  /// When the next waiting row is due, or null when the outbox is empty.
  Future<DateTime?> nextDue() async {
    final row = await _db
        .customSelect('select min(next_try_at) as at from outbox')
        .getSingle();
    final at = row.readNullable<int>('at');
    return at == null ? null : DateTime.fromMillisecondsSinceEpoch(at);
  }

  /// The server has [entries]: they leave the outbox.
  Future<void> sent(List<OutboxEntry> entries) async {
    if (entries.isEmpty) return;
    await _db.customStatement(
      'delete from outbox where id in (${_marks(entries.length)})',
      [for (final e in entries) e.id],
    );
  }

  /// Sending [entries] failed at [now]: each waits its next [backoff].
  Future<void> failed(List<OutboxEntry> entries, DateTime now) =>
      _db.transaction(() async {
        for (final e in entries) {
          final tries = e.tries + 1;
          await _db.customStatement(
            'update outbox set tries = ?, next_try_at = ? where id = ?',
            [tries, now.add(backoff(tries)).millisecondsSinceEpoch, e.id],
          );
        }
      });

  /// One send carries at most this many rows (rate-limit friendly).
  static const int batchSize = 50;

  static String _marks(int n) => List.filled(n, '?').join(', ');

  static OutboxKind? _kind(String name) {
    for (final k in OutboxKind.values) {
      if (k.name == name) return k;
    }
    return null;
  }
}

/// Rung when something is queued, so the sync worker sends it now instead of on its next timer.
class OutboxSignal {
  final StreamController<void> _queued = StreamController<void>.broadcast();

  Stream<void> get queued => _queued.stream;

  void ping() {
    if (!_queued.isClosed) _queued.add(null);
  }

  Future<void> close() => _queued.close();
}
