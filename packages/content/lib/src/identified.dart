/// A piece of content with a stable id: a mission, an option, a follow-up, a lesson, an
/// interviewer.
///
/// Analytics accepts ids only through this interface, so an event property can name content
/// but can't carry text a player typed (`EventValue.id` in the app). Ids are snake_case
/// ([contentIdPattern]), checked by `validateContent`.
abstract interface class Identified {
  String get id;
}

/// The shape every content id must have: lowercase words and digits joined by underscores.
final RegExp contentIdPattern = RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$');
