// RUN: %target-parse-verify-swift

class A {
  func foo() { }
}

class B : A {
  func bar() { }
}

class Other { }

func acceptA(_ a: A) { }

func f0<T : A>(_ obji: T, _ ai: A, _ bi: B) {
  var obj = obji, a = ai, b = bi
  // Method access
  obj.foo()
  obj.bar() // expected-error{{value of type 'T' has no member 'bar'}}

  // Calls
  acceptA(obj)

  // Derived-to-base conversion for assignment
  a = obj

  // Invalid assignments
  obj = a // expected-error{{'A' is not convertible to 'T'}}
  obj = b // expected-error{{'B' is not convertible to 'T'}}

  // Downcast that is actually a coercion
  a = (obj as? A)! // expected-warning{{conditional cast from 'T' to 'A' always succeeds}}
  a = obj as A

  // Downcasts
  b = obj as! B
}

func call_f0(_ a: A, b: B, other: Other) {
  f0(a, a, b)
  f0(b, a, b)
  f0(other, a, b) // expected-error{{cannot convert value of type 'Other' to expected argument type 'A'}}
}

class X<T> {
  func f() -> T {}
}

class Y<T> : X<[T]> {
}

func testGenericInherit() {
  let yi : Y<Int>
  _ = yi.f() as [Int] 
}


struct SS<T> : T { } // expected-error{{inheritance from non-protocol type 'T'}}
enum SE<T> : T { case X } // expected-error{{raw type 'T' is not expressible by any literal}} expected-error {{SE<T>' declares raw type 'T', but does not conform to RawRepresentable and conformance could not be synthesized}}

// Also need Equatable for init?(RawValue)
enum SE2<T : ExpressibleByIntegerLiteral>
  : T // expected-error {{'SE2<T>' declares raw type 'T', but does not conform to RawRepresentable and conformance could not be synthesized}} expected-error{{RawRepresentable 'init' cannot be synthesized because raw type 'T' is not Equatable}}
{ case X }

// ... but not if init?(RawValue) and `rawValue` are directly implemented some other way.
protocol InstanceGettable {
  static var someInstance : Self { get }
}
enum SE3<T : ExpressibleByIntegerLiteral> : T where T: InstanceGettable {
  case X 

  init?(rawValue: T) {
    self = SE3.X
  }

  var rawValue : T {
    return T.someInstance
  }
}

enum SE4<T : ExpressibleByIntegerLiteral & Equatable> : T { case X }
