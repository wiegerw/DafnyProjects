/* 
* Formal specification and verification of a Priority Queue implemented as a heap.
* A heap is a partially ordered set represented in an array, suited to implement priority 
* queues operations insert and deleteMax in O(heapSize).
* Illustrates the verification of object-oriented programs and data structures.
* J. Pascoal Faria, FEUP, Jan/2022.
*/
 
type T = int // for demo purposes, but could be real, etc.



class {:autocontracts} PriorityQueue {
 
  // Concrete state representation
  var heap: array<T>;
  var size : nat;
 
  // Configuration parameters
  static const initialCapacity := 10; 
 
  // Class invariant (heap invariant + automatic things generated by :autocontracts)
  predicate Valid()  {
    heapInv()
  }
 
  // Heap invariant
  predicate {:autocontracts false} heapInv()
     reads this, heap
  {
    // valid size 
    size <= heap.Length
    // each node is less or equal than its parent
    && forall i :: 1 <= i < size ==> heap[i] <= heap[(i-1)/2]
  }
 
  // State abstraction function: gets the heap contents as a multiset.
  function elems(): multiset<T> 
  { multiset(heap[..size]) }
 
  // Initializes the heap as empty.
  constructor()
    ensures isEmpty()
  {
    heap := new T[initialCapacity];
    size := 0; 
  }
 
  // Checks if the heap is empty
  predicate method isEmpty() 
    ensures isEmpty() <==> elems() == multiset{}
  {
    // to help proving the post-condition
    assert elems() == multiset{} <==> |elems()| == 0;
    // actual expression 
    size == 0
  }  
 
  // Inserts a value x in the heap.
  method insert(x : T)
    ensures elems() == old(elems()) + multiset{x}
  {
    if size == heap.Length {
      grow();
    }
    // Place at the bottom
    heap[size] := x;
    size := size + 1;
    // Move up as needed in the heap
    heapifyUp();
  }
 
  // Method used internally to grow the heap capacity 
  method grow()
    requires size == heap.Length 
    ensures heap.Length > size && heap[..size] == old(heap[..size])
  {
      var oldHeap := heap;
      heap := new T[if size == 0 then initialCapacity else 2 * size];
      forall i | 0 <= i < oldHeap.Length {
        heap[i] := oldHeap[i];
      }
  }
 
 
    // Auxiliary method to move a dirty node from the bottom upwards in the heap
  method {:autocontracts false} heapifyUp()
    requires size > 0 && heapifyUpInv(size-1) 
    modifies heap
    ensures heapInv() && multiset(heap[..size]) == old(multiset(heap[..size]))
  {
    var k := size - 1;
    while k > 0 && heap[k] > heap[(k - 1) / 2]
      invariant 0 <= k < size
      invariant heapifyUpInv(k) && multiset(heap[..size]) == old(multiset(heap[..size]))
    {
      heap[k], heap[(k - 1) / 2] := heap[(k - 1) / 2], heap[k];
      k := (k - 1) / 2;
    }
  }
 
  // During heapifyUp, while moving a node up at index k, there are some differences:
  // children of k are sorted wrt parent of k, and k is not sorted wrt its parent.
  predicate {:autocontracts false} heapifyUpInv(k: nat)
    reads this, heap
  {
    size <= heap.Length 
    && (forall i :: 1 <= i < size && i != k ==> heap[i] <= heap[(i - 1)/2])
    && (k > 0 ==> forall i :: 1 <= i < size && (i-1)/2 == k ==> 
                                 heap[i] <= heap[((i - 1)/2 - 1)/2])
  }
 
  // Deletes and retrieves the maximum value in the heap (assumed not empty).
  method deleteMax() returns (x: T)
    requires ! isEmpty()
    ensures isMax(x, old(elems()))
    ensures elems() == old(elems()) - multiset{x}
  {
    // recall the lemma ...  
    maxIsAtTop(); 
    // pick the maximum from the top
    x := heap[0];  
    // reduce the size
    size := size - 1; 
    if size > 0 {
      // move last element to top
      heap[0] := heap[size]; 
      // move down as needed in the heap
      heapifyDown(); 
    }
  }

// Deletes and retrieves the maximum value in the heap (assumed not empty).
  method geteMax() returns (x: T)
    requires ! isEmpty()
    ensures isMax(x,elems())
  {
    maxIsAtTop(); 
    return heap[0];  
  }
 

  // Auxiliary predicate to check if a value is a maximum in a multiset.
  predicate isMax(x: T, m: multiset<T>) {
    x in m && forall y :: y in m ==> y <= x
  }
 
  // Auxiliary method to move a dirty node from the top down in the heap
  method {:autocontracts false} heapifyDown() 
    requires size > 0 && heapifyDownInv(0) 
    modifies heap
    ensures heapInv() && multiset(heap[..size]) == old(multiset(heap[..size]))
  {
    var k := 0;
    while true 
      decreases size - k
      invariant 0 <= k < size
      invariant heapifyDownInv(k) && multiset(heap[..size]) == old(multiset(heap[..size]))
    {
      var leftChild := 2 * k + 1; // index of left child
      var rightChild := 2 * k + 2;
      if leftChild >= size {               
        return;  // reached the bottom
      }
      var maxChild := if rightChild < size && heap[rightChild] > heap[leftChild] 
                      then rightChild else leftChild;
      if heap[k] > heap[maxChild] {                
        return; // already sorted
      }
      // move up and continue
      heap[k], heap[maxChild] := heap[maxChild], heap[k];
      k := maxChild;
    }
  }
 
  // During heapifyDown, while moving a node down at index k, there are some differences:
  // children of k are sorted wrt parent of k, and k is not sorted wrt its children.
  predicate {:autocontracts false} heapifyDownInv(k: nat)
    reads this, heap
  {
    size <= heap.Length
    && (forall i :: 1 <= i < size && (i-1)/2 != k ==> heap[i] <= heap[(i - 1)/2])
    && (k > 0 ==> forall i :: 1 <= i < size && (i-1)/2 == k ==> 
                                heap[i] <= heap[((i - 1)/2 - 1)/2])
  }
  
  // Lemma stating that the maximum is at the top of the heap (position 0).
  // This property is assumed by deleteMax and follows from the heap invariant.
  // Proved by induction on the size of the heap, reason why it receives
  // a parameter with the size to consider.
  lemma {:induction n} maxIsAtTop(n: nat := size)
    requires n <= size
    ensures forall i :: 0 <= i < n ==> heap[i] <= heap[0]
  {}
}
 
// A simple test scenario.
method testPriorityQueue() {
  var h := new PriorityQueue();
  assert h.isEmpty();
  h.insert(2);
  h.insert(5);
  h.insert(1);
  h.insert(1);
  var x := h.deleteMax(); assert x == 5;
  x := h.deleteMax(); assert x == 2;
  x := h.deleteMax(); assert x == 1;
  x := h.deleteMax(); assert x == 1;
  assert h.isEmpty();  
}
