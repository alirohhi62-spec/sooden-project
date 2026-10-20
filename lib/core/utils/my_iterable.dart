class MyIterable<T> {
  List<T> items;

  MyIterable(this.items);

  Iterator<T> get iterator => _MyIterator(this);
}

  class _MyIterator<T> implements Iterator<T> {
  final MyIterable<T> myIterable;
  int currentIndex = -1;

  _MyIterator(this.myIterable);

  @override
  T get current => myIterable.items[currentIndex];

  @override
  bool moveNext() {
    currentIndex++;
    return currentIndex < myIterable.items.length;
  }
}

