/// 1D DBSCAN clustering algoritması.
/// OCR satırlarını Y koordinatlarına göre gruplamak için kullanılır.
class DbscanUtils {
  /// Y-koordinatlarına göre 1D DBSCAN clustering yapar.
  /// Geriye her bir eleman için küme id'lerini (cluster id) içeren bir liste döner.
  /// Gürültü (noise) olan veya kümelenmemiş elemanlar -1 değeri alır.
  static List<int> dbscan1D(List<double> values, double eps, int minPts) {
    final n = values.length;
    final labels = List<int>.filled(n, -2); // -2: Tanımlanmamış (unvisited)
    int clusterId = 0;

    for (int i = 0; i < n; i++) {
      if (labels[i] != -2) continue;

      final neighbors = _getNeighbors1D(values, i, eps);

      if (neighbors.length < minPts) {
        labels[i] = -1; // Noise
      } else {
        _expandCluster1D(values, labels, i, neighbors, clusterId, eps, minPts);
        clusterId++;
      }
    }

    return labels;
  }

  static List<int> _getNeighbors1D(List<double> values, int index, double eps) {
    final neighbors = <int>[];
    final targetVal = values[index];

    for (int i = 0; i < values.length; i++) {
      if ((values[i] - targetVal).abs() <= eps) {
        neighbors.add(i);
      }
    }

    return neighbors;
  }

  static void _expandCluster1D(
    List<double> values,
    List<int> labels,
    int rootIndex,
    List<int> neighbors,
    int clusterId,
    double eps,
    int minPts,
  ) {
    labels[rootIndex] = clusterId;

    final queue = List<int>.from(neighbors);
    int head = 0;

    while (head < queue.length) {
      final currIndex = queue[head];
      head++;

      if (labels[currIndex] == -1) {
        labels[currIndex] = clusterId;
      }

      if (labels[currIndex] != -2) continue;

      labels[currIndex] = clusterId;

      final currNeighbors = _getNeighbors1D(values, currIndex, eps);
      if (currNeighbors.length >= minPts) {
        for (final nextNeighbor in currNeighbors) {
          if (!queue.contains(nextNeighbor)) {
            queue.add(nextNeighbor);
          }
        }
      }
    }
  }
}
