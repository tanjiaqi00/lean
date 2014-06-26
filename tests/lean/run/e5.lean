definition Bool [inline] := Type.{0}

definition false : Bool := ∀x : Bool, x
check false

theorem false_elim (C : Bool) (H : false) : C
:= H C

definition eq {A : Type} (a b : A)
:= ∀ P : A → Bool, P a → P b

check eq

infix `=` 50 := eq

theorem refl {A : Type} (a : A) : a = a
:= λ P H, H

definition true : Bool
:= false = false

theorem trivial : true
:= refl false

theorem subst {A : Type} {P : A -> Bool} {a b : A} (H1 : a = b) (H2 : P a) : P b
:= H1 _ H2

theorem symm {A : Type} {a b : A} (H : a = b) : b = a
:= subst H (refl a)

theorem trans {A : Type} {a b c : A} (H1 : a = b) (H2 : b = c) : a = c
:= subst H2 H1

inductive nat : Type :=
| zero : nat
| succ : nat → nat

print "using strict implicit arguments"
abbreviation symmetric {A : Type} (R : A → A → Bool) := ∀ ⦃a b⦄, R a b → R b a

check symmetric
variable p : nat → nat → Bool
check symmetric p
axiom H1 : symmetric p
axiom H2 : p zero (succ zero)
check H1
check H1 H2

print "------------"
print "using implicit arguments"
abbreviation symmetric2 {A : Type} (R : A → A → Bool) := ∀ {a b}, R a b → R b a
check symmetric2
check symmetric2 p
axiom H3 : symmetric2 p
axiom H4 : p zero (succ zero)
check H3
check H3 H4

print "-----------------"
print "using strict implicit arguments (ASCII notation)"
abbreviation symmetric3 {A : Type} (R : A → A → Bool) := ∀ {{a b}}, R a b → R b a

check symmetric3
check symmetric3 p
axiom H5 : symmetric3 p
axiom H6 : p zero (succ zero)
check H5
check H5 H6
