/// Mixin for models that have an integer ID.
///
/// Used by [BaseListProviderImpl] for type-safe CRUD operations
/// (updateItem, deleteItem) instead of dynamic casts.
mixin HasId {
  int get id;
}
